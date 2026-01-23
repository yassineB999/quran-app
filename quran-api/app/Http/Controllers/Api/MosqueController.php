<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class MosqueController extends Controller
{
    public function nearby(Request $request)
    {
        $data = $request->validate([
            'lat' => ['required', 'numeric', 'between:-90,90'],
            'lng' => ['required', 'numeric', 'between:-180,180'],
            'radius' => ['nullable', 'integer', 'min:100', 'max:50000'],
            'limit' => ['nullable', 'integer', 'min:1', 'max:50'],
        ]);

        $radius = $data['radius'] ?? config('services.openstreetmap.nearby_radius_m');
        $limit = $data['limit'] ?? config('services.openstreetmap.nearby_max_results');
        $endpoint = config('services.openstreetmap.overpass_url');

        if (!$endpoint) {
            return response()->json([
                'message' => 'Overpass API endpoint is not configured.',
            ], 500);
        }

        $query = sprintf(
            '[out:json];node["amenity"="place_of_worship"]["religion"="muslim"](around:%d,%s,%s);out;',
            $radius,
            $data['lat'],
            $data['lng']
        );

        $response = Http::asForm()->post($endpoint, [
            'data' => $query,
        ]);

        if (!$response->ok()) {
            return response()->json([
                'message' => 'Failed to fetch nearby mosques.',
            ], 502);
        }

        $payload = $response->json();
        $elements = $payload['elements'] ?? [];

        $mapped = collect($elements)->map(function ($place) use ($data) {
            $lat = $place['lat'] ?? null;
            $lng = $place['lon'] ?? null;
            if ($lat === null || $lng === null) {
                return null;
            }

            $tags = $place['tags'] ?? [];
            $name = $tags['name']
                ?? $tags['name:ar']
                ?? $tags['name:en']
                ?? $tags['name:fr']
                ?? '';
            $city = $tags['addr:city']
                ?? $tags['addr:place']
                ?? $tags['addr:suburb']
                ?? $tags['addr:district']
                ?? '';

            return [
                'id' => (string)($place['id'] ?? ''),
                'name' => $name,
                'city' => $city,
                'latitude' => (float)$lat,
                'longitude' => (float)$lng,
                'distance_km' => $this->calculateDistanceKm(
                    $data['lat'],
                    $data['lng'],
                    $lat,
                    $lng
                ),
            ];
        })->filter()->sortBy('distance_km')->values();

        if ($limit) {
            $mapped = $mapped->take($limit)->values();
        }

        return response()->json([
            'data' => $mapped,
        ]);
    }

    private function calculateDistanceKm(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $earthRadius = 6371.0;
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);

        $a = sin($dLat / 2) * sin($dLat / 2) +
            cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
            sin($dLng / 2) * sin($dLng / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
        return $earthRadius * $c;
    }
}
