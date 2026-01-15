<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;
use App\Models\Surah;
use App\Models\Ayah;

class SeedWarshText extends Command
{
    protected $signature = 'quran:seed-warsh-text';
    protected $description = 'Seed Warsh narration text from Al Quran Cloud';

    public function handle()
    {
        $this->info('Fetching Warsh text...');

        $response = Http::timeout(120)->get('http://api.alquran.cloud/v1/quran/quran-warsh');

        if ($response->failed()) {
            $this->error('Failed to fetch data.');
            return;
        }

        $data = $response->json('data');
        $surahs = $data['surahs'];

        $this->info('Seeding surahs and ayahs...');

        $bar = $this->output->createProgressBar(count($surahs));
        $bar->start();

        foreach ($surahs as $surahData) {
            $surah = Surah::updateOrCreate(
                ['number' => $surahData['number']],
                [
                    'name_simple' => $surahData['englishName'],
                    'name_arabic' => $surahData['name'],
                    'verses_count' => count($surahData['ayahs']),
                    'revelation_place' => $surahData['revelationType'],
                ]
            );

            foreach ($surahData['ayahs'] as $ayahData) {
                Ayah::updateOrCreate(
                    [
                        'surah_number' => $surahData['number'],
                        'number_in_surah' => $ayahData['numberInSurah'],
                    ],
                    [
                        'number' => $ayahData['number'],
                        'text_warsh' => $ayahData['text'],
                        'juz' => $ayahData['juz'],
                        'page' => $ayahData['page'],
                        'hizb' => $ayahData['hizbQuarter'],
                        'manzil' => $ayahData['manzil'],
                    ]
                );
            }
            $bar->advance();
        }

        $bar->finish();
        $this->newLine();
        $this->info('Seeding completed successfully.');
    }
}
