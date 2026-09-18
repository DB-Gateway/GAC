<?php

use Database\Seeders\ChecklistTemplateSeeder;
use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    public function up(): void
    {
        $seeder = new ChecklistTemplateSeeder;
        $seeder->syncTemplate($seeder->sales());
        $seeder->syncTemplate($seeder->service());
    }

    public function down(): void
    {
        // Preset definitions remain active.
    }
};

