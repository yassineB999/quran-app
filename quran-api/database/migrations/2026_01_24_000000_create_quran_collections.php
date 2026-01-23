<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('surahs', function (Blueprint $table) {
            $table->id();
            $table->integer('number')->unique();
            $table->string('name_simple');
            $table->string('name_arabic');
            $table->integer('verses_count');
            $table->string('revelation_place');
            $table->timestamps();
        });

        Schema::create('ayahs', function (Blueprint $table) {
            $table->id();
            $table->integer('number');
            $table->integer('number_in_surah');
            $table->integer('surah_number')->index();
            $table->text('text_warsh');
            $table->integer('juz')->nullable();
            $table->integer('page')->nullable();
            $table->integer('hizb')->nullable();
            $table->integer('manzil')->nullable();
            $table->text('translation_en')->nullable();
            
            $table->index(['surah_number', 'number_in_surah']);
            $table->timestamps();
        });

        Schema::create('reciters', function (Blueprint $table) {
            $table->id();
            $table->integer('reciter_id')->unique();
            $table->string('name');
            $table->string('rewaya');
            $table->string('server_url');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('surahs');
        Schema::dropIfExists('ayahs');
        Schema::dropIfExists('reciters');
    }
};
