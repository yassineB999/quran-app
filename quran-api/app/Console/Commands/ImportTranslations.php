<?php

namespace App\Console\Commands;

use App\Models\Ayah;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;

class ImportTranslations extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'app:import-translations';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Import English translations for Ayahs from external API';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('Starting translation import...');

        for ($i = 1; $i <= 114; $i++) {
            $this->info("Fetching translation for Surah $i...");

            // Fetch Sahih International translation
            $response = Http::get("http://api.alquran.cloud/v1/surah/$i/en.sahih");

            if ($response->successful()) {
                $data = $response->json()['data'];
                $ayahs = $data['ayahs'];

                foreach ($ayahs as $apiAyah) {
                    $numberInSurah = $apiAyah['numberInSurah'];
                    $text = $apiAyah['text'];

                    // Update MongoDB
                    // We match by surah_number and number_in_surah
                    $updated = Ayah::where('surah_number', $i)
                        ->where('number_in_surah', $numberInSurah)
                        ->update(['translation_en' => $text]);
                    
                    if ($updated) {
                         //$this->info("Updated Ayah $i:$numberInSurah");
                    } else {
                        $this->warn("Ayah not found: $i:$numberInSurah");
                    }
                }
                $this->info("Completed Surah $i");
            } else {
                $this->error("Failed to fetch Surah $i");
            }
            
            // Avoid rate limits
            sleep(1);
        }

        $this->info('Translation import completed.');
    }
}
