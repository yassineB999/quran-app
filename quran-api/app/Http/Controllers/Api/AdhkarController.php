<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AdhkarCategory;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class AdhkarController extends Controller
{
    private string $sourceUrl = 'https://raw.githubusercontent.com/wdalgrb/azkar-api/master/azkar.json';
    private string $englishSourceUrl = 'https://raw.githubusercontent.com/Seen-Arabic/Morning-And-Evening-Adhkar-DB/main/en.json';

    private array $categoryMap = [
        'morning' => 'أذكار الصباح',
        'evening' => 'أذكار المساء',
        'bedtime' => 'أذكار النوم',
        'post-prayer' => 'أذكار بعد السلام من الصلاة المفروضة',
    ];

    private array $englishTitles = [
        'morning' => 'Morning Adhkar',
        'evening' => 'Evening Adhkar',
    ];

    public function show(string $category, Request $request)
    {
        if (!isset($this->categoryMap[$category])) {
            return response()->json(['message' => 'Category not found'], 404);
        }

        $lang = strtolower((string)$request->query('lang', 'ar'));
        if (!in_array($lang, ['ar', 'en'], true)) {
            return response()->json(['message' => 'Language not supported'], 422);
        }

        if ($lang === 'en' && !isset($this->englishTitles[$category])) {
            return response()->json(['message' => 'Translation not available for this category'], 422);
        }

        $refresh = $request->boolean('refresh');
        $cache = AdhkarCategory::where('category', $category)
            ->where('language', $lang)
            ->first();

        if ($cache && !$refresh) {
            $items = $this->normalizeItems($cache->payload, $lang, $category);
            $result = $this->paginateList($items, $request, 50);
            return response()->json([
                'data' => $result['items'],
                'title' => $cache->title,
                'category' => $category,
                'language' => $lang,
                'pagination' => $result['pagination'],
                'cached' => true,
            ]);
        }

        $sourceUrl = $lang === 'en' ? $this->englishSourceUrl : $this->sourceUrl;
        $response = Http::timeout(30)->get($sourceUrl);
        if ($response->failed()) {
            return response()->json(['message' => 'Failed to fetch adhkar data'], 502);
        }

        $data = $response->json();
        $key = $this->categoryMap[$category];
        $title = $lang === 'en' ? $this->englishTitles[$category] : $key;

        if (!is_array($data)) {
            return response()->json(['message' => 'Invalid adhkar source data'], 502);
        }

        if ($lang === 'en') {
            $payload = $this->filterEnglishItems($data, $category);
        } else {
            if (!array_key_exists($key, $data)) {
                return response()->json(['message' => 'Invalid adhkar source data'], 502);
            }
            $payload = $data[$key];
        }

        AdhkarCategory::updateOrCreate(
            ['category' => $category, 'language' => $lang],
            [
                'title' => $title,
                'payload' => $payload,
                'source_url' => $sourceUrl,
                'fetched_at' => now(),
            ]
        );

        $items = $this->normalizeItems($payload, $lang, $category);
        $result = $this->paginateList($items, $request, 50);

        return response()->json([
            'data' => $result['items'],
            'title' => $title,
            'category' => $category,
            'language' => $lang,
            'pagination' => $result['pagination'],
            'cached' => false,
        ]);
    }

    private function normalizeItems($payload, string $lang, string $category): array
    {
        if (!is_array($payload)) {
            return [];
        }

        if ($lang === 'en') {
            return $payload;
        }

        if (array_is_list($payload) && !empty($payload) && is_array($payload[0]) && array_is_list($payload[0])) {
            $flat = [];
            foreach ($payload as $group) {
                $flat = array_merge($flat, $group);
            }
            return $flat;
        }

        return $payload;
    }

    private function filterEnglishItems(array $items, string $category): array
    {
        $type = $category === 'morning' ? 1 : 2;
        return array_values(array_filter($items, function ($item) use ($type) {
            if (!is_array($item)) {
                return false;
            }
            $itemType = $item['type'] ?? 0;
            return $itemType === 0 || $itemType === $type;
        }));
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
}
