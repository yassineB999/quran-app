<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\HadithCache;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class HadithController extends Controller
{
    private string $baseUrl = 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1';

    public function editions(Request $request)
    {
        $refresh = $request->boolean('refresh');
        $lang = $request->query('lang');
        $cache = HadithCache::where('type', 'editions')->first();

        if ($cache && !$refresh) {
            $payload = $cache->payload;
            if ($lang) {
                $payload = $this->filterEditionsByLanguage($payload, (string)$lang);
            }
            $pagination = null;
            if (is_array($payload) && array_is_list($payload)) {
                $result = $this->paginateList($payload, $request, 50);
                $payload = $result['items'];
                $pagination = $result['pagination'];
            }
            return response()->json([
                'data' => $payload,
                'pagination' => $pagination,
                'cached' => true,
            ]);
        }

        $url = "{$this->baseUrl}/editions.min.json";
        $response = Http::timeout(30)->get($url);

        if ($response->failed()) {
            return response()->json(['message' => 'Failed to fetch hadith editions'], 502);
        }

        $payload = $response->json();

        HadithCache::updateOrCreate(
            ['type' => 'editions'],
            [
                'payload' => $payload,
                'source_url' => $url,
                'fetched_at' => now(),
            ]
        );

        if ($lang) {
            $payload = $this->filterEditionsByLanguage($payload, (string)$lang);
        }

        $pagination = null;
        if (is_array($payload) && array_is_list($payload)) {
            $result = $this->paginateList($payload, $request, 50);
            $payload = $result['items'];
            $pagination = $result['pagination'];
        }

        return response()->json([
            'data' => $payload,
            'pagination' => $pagination,
            'cached' => false,
        ]);
    }

    public function show(string $edition, Request $request)
    {
        $number = $request->query('number');
        $section = $request->query('section');
        $refresh = $request->boolean('refresh');

        if ($number !== null && $section !== null) {
            return response()->json(['message' => 'Provide either number or section, not both'], 422);
        }

        $type = $number !== null ? 'hadith' : ($section !== null ? 'section' : 'edition');

        $cacheQuery = HadithCache::where('type', $type)->where('edition', $edition);
        if ($number !== null) {
            $cacheQuery->where('hadith_number', (int)$number);
        }
        if ($section !== null) {
            $cacheQuery->where('section_number', (int)$section);
        }
        $cache = $cacheQuery->first();

        if ($cache && !$refresh) {
            $payload = $cache->payload;
            $pagination = null;
            if (is_array($payload) && isset($payload['hadiths']) && is_array($payload['hadiths']) && array_is_list($payload['hadiths'])) {
                $result = $this->paginateList($payload['hadiths'], $request, 50);
                $payload['hadiths'] = $result['items'];
                $pagination = $result['pagination'];
            }
            return response()->json([
                'data' => $payload,
                'pagination' => $pagination,
                'cached' => true,
            ]);
        }

        $path = "{$this->baseUrl}/editions/{$edition}";
        if ($number !== null) {
            $path .= '/' . (int)$number;
        } elseif ($section !== null) {
            $path .= '/sections/' . (int)$section;
        }
        $url = "{$path}.json";

        $response = Http::timeout(30)->get($url);
        if ($response->failed()) {
            return response()->json(['message' => 'Failed to fetch hadith data'], 502);
        }

        $payload = $response->json();

        HadithCache::updateOrCreate(
            [
                'type' => $type,
                'edition' => $edition,
                'hadith_number' => $number !== null ? (int)$number : null,
                'section_number' => $section !== null ? (int)$section : null,
            ],
            [
                'payload' => $payload,
                'source_url' => $url,
                'fetched_at' => now(),
            ]
        );

        $pagination = null;
        if (is_array($payload) && isset($payload['hadiths']) && is_array($payload['hadiths']) && array_is_list($payload['hadiths'])) {
            $result = $this->paginateList($payload['hadiths'], $request, 50);
            $payload['hadiths'] = $result['items'];
            $pagination = $result['pagination'];
        }

        return response()->json([
            'data' => $payload,
            'pagination' => $pagination,
            'cached' => false,
        ]);
    }

    private function paginateList(array $items, Request $request, int $defaultPerPage): array
    {
        $page = max(1, (int)$request->query('page', 1));
        $perPage = (int)$request->query('per_page', $defaultPerPage);
        if ($perPage < 1) {
            $perPage = $defaultPerPage;
        }
        if ($perPage > 200) {
            $perPage = 200;
        }

        $total = count($items);
        $totalPages = $perPage > 0 ? (int)ceil($total / $perPage) : 1;
        $page = min($page, max($totalPages, 1));
        $offset = ($page - 1) * $perPage;
        $data = array_slice($items, $offset, $perPage);

        return [
            'items' => $data,
            'pagination' => [
                'page' => $page,
                'per_page' => $perPage,
                'total' => $total,
                'total_pages' => $totalPages,
                'has_more' => $page < $totalPages,
            ],
        ];
    }

    private function filterEditionsByLanguage($payload, string $lang)
    {
        if (!is_array($payload)) {
            return $payload;
        }

        $lang = strtolower(trim($lang));
        $map = [
            'en' => 'english',
            'ar' => 'arabic',
            'ur' => 'urdu',
            'bn' => 'bengali',
            'id' => 'indonesian',
            'tr' => 'turkish',
            'ru' => 'russian',
            'fr' => 'french',
            'es' => 'spanish',
            'fa' => 'persian',
            'ckb' => 'kurdish',
        ];
        $target = $map[$lang] ?? $lang;

        $filterCollection = function (array $collection) use ($lang, $target): array {
            return array_values(array_filter($collection, function ($item) use ($lang, $target) {
                if (!is_array($item)) {
                    return false;
                }
                $language = strtolower((string)($item['language'] ?? ''));
                $name = strtolower((string)($item['name'] ?? ''));
                return $language === $target || $language === $lang || str_starts_with($name, $lang . '-');
            }));
        };

        if (array_is_list($payload)) {
            return $filterCollection($payload);
        }

        foreach ($payload as $bookKey => $book) {
            if (is_array($book) && isset($book['collection']) && is_array($book['collection'])) {
                $payload[$bookKey]['collection'] = $filterCollection($book['collection']);
            }
        }

        return $payload;
    }
}
