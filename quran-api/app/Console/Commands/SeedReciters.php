<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;
use App\Models\Reciter;

class SeedReciters extends Command
{
    protected $signature = 'quran:seed-reciters';
    protected $description = 'Seed Warsh Reciters from MP3Quran';

    public function handle()
    {
        $this->info('Fetching Reciters...');

        $response = Http::get('https://mp3quran.net/api/v3/reciters?rewaya=2');

        if ($response->failed()) {
            $this->error('Failed to fetch data.');
            return;
        }

        $data = $response->json('reciters');

        $this->info('Found ' . count($data) . ' reciters.');

        foreach ($data as $reciterData) {
            $warshMoshaf = null;
            foreach ($reciterData['moshaf'] as $moshaf) {
                if ($moshaf['moshaf_type'] == 2 || $moshaf['name'] == 'Warsh A\'n Nafi\'') {
                    if ($moshaf['id'] == 2 || str_contains($moshaf['name'], 'Warsh')) {
                        $warshMoshaf = $moshaf;
                        break;
                    }
                }
            }

            if (!$warshMoshaf && !empty($reciterData['moshaf'])) {
                $warshMoshaf = $reciterData['moshaf'][0];
            }

            if ($warshMoshaf) {
                Reciter::updateOrCreate(
                    ['reciter_id' => $reciterData['id']],
                    [
                        'name' => $reciterData['name'],
                        'rewaya' => 'warsh',
                        'server_url' => trim($warshMoshaf['server']),
                    ]
                );
                $this->info("Seeded: {$reciterData['name']}");
            }
        }

        $this->info('Reciters seeding completed.');
    }
}
