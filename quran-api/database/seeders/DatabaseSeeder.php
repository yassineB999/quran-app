<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Artisan;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // User::factory(10)->create();

        User::firstOrCreate(
            ['email' => 'test@example.com'],
            ['name' => 'Test User']
        );

        $this->command->info('Seeding Quran Data...');
        
        // 1. Seed Warsh Text (Surahs and Ayahs)
        Artisan::call('quran:seed-warsh-text', [], $this->command->getOutput());
        
        // 2. Import Translations
        Artisan::call('app:import-translations', [], $this->command->getOutput());
        
        // 3. Seed Reciters
        Artisan::call('quran:seed-reciters', [], $this->command->getOutput());
    }
}
