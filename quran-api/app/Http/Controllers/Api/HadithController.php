<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\HadithCache;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class HadithController extends Controller
{
    private string $baseUrl = 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1';
    private int $maxCacheBytes = 15000000;

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
        $lang = $request->query('lang');

        if ($number !== null && $section !== null) {
            return response()->json(['message' => 'Provide either number or section, not both'], 422);
        }

        $langs = $this->parseLanguages($lang);
        $wantsArabic = in_array('ar', $langs, true);
        $wantsEnglish = in_array('en', $langs, true);
        if ($wantsArabic && $wantsEnglish) {
            $arabicEdition = $this->resolveEditionForLanguage($edition, 'ar');
            $englishEdition = $this->resolveEditionForLanguage($edition, 'en');

            $arabicPayload = $this->fetchEditionPayload(
                $arabicEdition,
                $number,
                $section,
                $refresh
            );
            if (!$arabicPayload) {
                return response()->json(['message' => 'Failed to fetch Arabic hadith data'], 502);
            }

            $englishPayload = $this->fetchEditionPayload(
                $englishEdition,
                $number,
                $section,
                $refresh
            );
            if (!$englishPayload) {
                return response()->json(['message' => 'Failed to fetch English hadith data'], 502);
            }

            $payload = $this->buildMergedPayload($arabicPayload, $englishPayload);
            $payload['arabic_edition'] = $arabicEdition;
            $payload['english_edition'] = $englishEdition;

            $pagination = null;
            if (isset($payload['hadiths']) && is_array($payload['hadiths']) && array_is_list($payload['hadiths'])) {
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

        $resolvedEdition = $this->resolveEditionForLanguage(
            $edition,
            $wantsArabic ? 'ar' : ($wantsEnglish ? 'en' : null)
        );
        $payload = $this->fetchEditionPayload(
            $resolvedEdition,
            $number,
            $section,
            $refresh
        );
        if (!$payload) {
            return response()->json(['message' => 'Failed to fetch hadith data'], 502);
        }

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

    public function daily(Request $request)
    {
        $arabicEdition = (string)$request->query('arabic_edition', 'ara-muslim');
        $englishEdition = (string)$request->query('english_edition', 'eng-muslim');
        $refresh = $request->boolean('refresh');
        $timezone = $request->query('tz');

        $arabicPayload = $this->fetchEdition($arabicEdition, $refresh);
        if (!$arabicPayload) {
            return response()->json(['message' => 'Failed to fetch Arabic hadith data'], 502);
        }

        $englishPayload = $this->fetchEdition($englishEdition, $refresh);
        if (!$englishPayload) {
            return response()->json(['message' => 'Failed to fetch English hadith data'], 502);
        }

        $arabicHadiths = $this->extractHadiths($arabicPayload);
        $englishHadiths = $this->extractHadiths($englishPayload);
        $limit = min(count($arabicHadiths), count($englishHadiths));
        $validIndices = [];
        for ($i = 0; $i < $limit; $i++) {
            if ($this->hasText($arabicHadiths[$i] ?? null) && $this->hasText($englishHadiths[$i] ?? null)) {
                $validIndices[] = $i;
            }
        }

        if (empty($validIndices)) {
            return response()->json(['message' => 'Hadith data is empty'], 502);
        }

        $today = $timezone ? now($timezone) : now();
        $seed = $today->format('Y-m-d') . '|' . $arabicEdition . '|' . $englishEdition;
        $index = $this->pickDailyIndex(count($validIndices), $seed);
        $pickedIndex = $validIndices[$index];
        $arabicHadith = $arabicHadiths[$pickedIndex] ?? [];
        $englishHadith = $englishHadiths[$pickedIndex] ?? [];

        $arabicText = $this->extractText($arabicHadith, ['arabic', 'arab', 'text', 'hadith', 'body']);
        $englishText = $this->extractText($englishHadith, ['translation', 'text', 'hadith', 'body']);
        $referenceName = $this->extractCollectionName($englishPayload)
            ?? $this->extractCollectionName($arabicPayload)
            ?? $englishEdition;
        $number = $arabicHadith['hadithnumber'] ?? $englishHadith['hadithnumber'] ?? null;
        $reference = $referenceName;
        if ($number) {
            $reference .= ' • Hadith ' . $number;
        }

        return response()->json([
            'data' => [
                'arabic' => $arabicText,
                'translation' => $englishText,
                'reference' => $reference,
                'number' => $number,
                'arabic_edition' => $arabicEdition,
                'english_edition' => $englishEdition,
            ],
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

    private function fetchEdition(string $edition, bool $refresh): ?array
    {
        $cache = HadithCache::where('type', 'edition')->where('edition', $edition)->first();
        if ($cache && !$refresh) {
            return $cache->payload;
        }

        $url = "{$this->baseUrl}/editions/{$edition}.min.json";
        $response = Http::timeout(30)->get($url);
        if ($response->failed()) {
            return null;
        }

        $payload = $response->json();

        if ($this->canCachePayload($payload)) {
            HadithCache::updateOrCreate(
                [
                    'type' => 'edition',
                    'edition' => $edition,
                ],
                [
                    'payload' => $payload,
                    'source_url' => $url,
                    'fetched_at' => now(),
                ]
            );
        }

        return $payload;
    }

    private function canCachePayload($payload): bool
    {
        $encoded = json_encode($payload);
        if ($encoded === false) {
            return false;
        }
        return strlen($encoded) <= $this->maxCacheBytes;
    }

    private function extractHadiths($payload): array
    {
        if (!is_array($payload)) {
            return [];
        }
        if (isset($payload['hadiths']) && is_array($payload['hadiths'])) {
            return $payload['hadiths'];
        }
        if (array_is_list($payload)) {
            return $payload;
        }
        return [];
    }

    private function fetchEditionPayload(
        string $edition,
        ?string $number,
        ?string $section,
        bool $refresh
    ): ?array {
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
            return $cache->payload;
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
            return null;
        }

        $payload = $response->json();

        if ($this->canCachePayload($payload)) {
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
        }

        return $payload;
    }

    private function hasText($item): bool
    {
        if (!is_array($item)) {
            return false;
        }
        $text = $item['text'] ?? null;
        return is_string($text) && trim($text) !== '';
    }

    private function pickDailyIndex(int $count, string $seed): int
    {
        if ($count <= 1) {
            return 0;
        }
        $hash = sprintf('%u', crc32($seed));
        return ((int)$hash) % $count;
    }

    private function extractCollectionName($payload): ?string
    {
        if (!is_array($payload)) {
            return null;
        }
        $metadata = $payload['metadata'] ?? null;
        if (is_array($metadata)) {
            $name = $metadata['name'] ?? $metadata['book'] ?? null;
            if (is_string($name) && trim($name) !== '') {
                return $name;
            }
        }
        $name = $payload['name'] ?? $payload['book'] ?? null;
        if (is_string($name) && trim($name) !== '') {
            return $name;
        }
        return null;
    }

    private function extractText($source, array $keys): ?string
    {
        if (!is_array($source)) {
            return null;
        }

        foreach ($keys as $key) {
            $value = $source[$key] ?? null;
            if (is_string($value) && trim($value) !== '') {
                return $value;
            }
        }

        return null;
    }

    private function parseLanguages(?string $lang): array
    {
        if (!$lang) {
            return [];
        }
        $parts = array_map('trim', explode(',', strtolower($lang)));
        $normalized = [];
        foreach ($parts as $part) {
            if ($part === 'arabic') {
                $part = 'ar';
            }
            if ($part === 'english') {
                $part = 'en';
            }
            if ($part !== '') {
                $normalized[] = $part;
            }
        }
        return array_values(array_unique($normalized));
    }

    private function resolveEditionForLanguage(string $edition, ?string $lang): string
    {
        $edition = strtolower(trim($edition));
        $edition = str_replace([' ', '_'], '-', $edition);
        if ($edition === '') {
            return $edition;
        }
        if (str_starts_with($edition, 'ara-') ||
            str_starts_with($edition, 'eng-') ||
            str_starts_with($edition, 'en-')) {
            return $edition;
        }

        $aliases = [
            'bukhari' => 'bukhari',
            'muslim' => 'muslim',
            'nasai' => 'nasai',
            'abudawud' => 'abudawud',
            'abu-dawud' => 'abudawud',
            'tirmidhi' => 'tirmidhi',
            'ibnmajah' => 'ibnmajah',
            'ibn-majah' => 'ibnmajah',
            'malik' => 'malik',
            'ahmed' => 'ahmed',
            'darimi' => 'darimi',
            'forty' => 'forty',
        ];

        $base = $aliases[$edition] ?? $edition;
        if ($lang === 'ar') {
            return 'ara-' . $base;
        }
        if ($lang === 'en') {
            return 'eng-' . $base;
        }
        return $base;
    }

    private function buildMergedPayload(array $arabicPayload, array $englishPayload): array
    {
        $arabicHadiths = $this->extractHadiths($arabicPayload);
        $englishHadiths = $this->extractHadiths($englishPayload);
        $englishMap = [];
        foreach ($englishHadiths as $item) {
            $number = $this->extractHadithNumber($item);
            if ($number !== null) {
                $englishMap[$number] = $item;
            }
        }

        $merged = [];
        foreach ($arabicHadiths as $item) {
            if (!is_array($item)) {
                continue;
            }
            $number = $this->extractHadithNumber($item);
            $englishItem = $number !== null ? ($englishMap[$number] ?? null) : null;
            $englishText = $englishItem
                ? $this->extractText($englishItem, ['translation', 'text', 'hadith', 'body'])
                : null;
            if ($englishText) {
                $item['englishText'] = $englishText;
            }
            $merged[] = $item;
        }

        $payload = [];
        if (isset($arabicPayload['metadata'])) {
            $payload['metadata'] = $arabicPayload['metadata'];
        }
        if (isset($arabicPayload['name'])) {
            $payload['name'] = $arabicPayload['name'];
        } elseif (isset($arabicPayload['book'])) {
            $payload['book'] = $arabicPayload['book'];
        }
        $payload['hadiths'] = $merged;
        return $payload;
    }

    private function extractHadithNumber($item): ?int
    {
        if (!is_array($item)) {
            return null;
        }
        if (isset($item['hadithnumber'])) {
            return (int)$item['hadithnumber'];
        }
        if (isset($item['number'])) {
            return (int)$item['number'];
        }
        return null;
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
