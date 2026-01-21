<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\HijriCalendar;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class HijriCalendarController extends Controller
{
    private string $baseUrl = 'https://api.aladhan.com/v1/gToHCalendar';

    public function month(int $year, int $month, Request $request)
    {
        if ($month < 1 || $month > 12) {
            return response()->json(['message' => 'Invalid month'], 422);
        }

        $refresh = $request->boolean('refresh');
        $result = $this->fetchMonth($year, $month, $refresh);

        if (isset($result['error'])) {
            return response()->json(['message' => $result['error']], 502);
        }

        $payload = $result['payload'];
        $pagination = null;
        if (is_array($payload) && isset($payload['data']) && is_array($payload['data']) && array_is_list($payload['data'])) {
            $pageResult = $this->paginateList($payload['data'], $request, 30);
            $payload['data'] = $pageResult['items'];
            $pagination = $pageResult['pagination'];
        }

        return response()->json([
            'year' => $year,
            'month' => $month,
            'data' => $payload,
            'pagination' => $pagination,
            'cached' => $result['cached'],
        ]);
    }

    public function year(int $year, Request $request)
    {
        $refresh = $request->boolean('refresh');
        $months = [];
        $errors = [];

        for ($month = 1; $month <= 12; $month++) {
            $result = $this->fetchMonth($year, $month, $refresh);
            if (isset($result['error'])) {
                $errors[] = ['month' => $month, 'message' => $result['error']];
            } else {
                $months[] = [
                    'month' => $month,
                    'data' => $result['payload'],
                    'cached' => $result['cached'],
                ];
            }
        }

        if (!empty($errors)) {
            return response()->json(['message' => 'Failed to fetch some months', 'errors' => $errors], 502);
        }

        $pageResult = $this->paginateList($months, $request, 6);

        return response()->json([
            'year' => $year,
            'months' => $pageResult['items'],
            'pagination' => $pageResult['pagination'],
        ]);
    }

    private function fetchMonth(int $year, int $month, bool $refresh): array
    {
        $cache = HijriCalendar::where('gregorian_year', $year)->where('month', $month)->first();

        if ($cache && !$refresh) {
            return [
                'payload' => $cache->payload,
                'cached' => true,
            ];
        }

        $url = "{$this->baseUrl}/{$month}/{$year}";
        $response = Http::timeout(30)->get($url);

        if ($response->failed()) {
            return ['error' => 'Failed to fetch Hijri calendar'];
        }

        $payload = $response->json();

        HijriCalendar::updateOrCreate(
            [
                'gregorian_year' => $year,
                'month' => $month,
            ],
            [
                'payload' => $payload,
                'source_url' => $url,
                'fetched_at' => now(),
            ]
        );

        return [
            'payload' => $payload,
            'cached' => false,
        ];
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
