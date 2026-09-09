<?php

use App\Models\ChecklistTemplate;
use Database\Seeders\ChecklistTemplateSeeder;
use Illuminate\Database\Migrations\Migration;

return new class extends Migration
{
    public function up(): void
    {
        (new ChecklistTemplateSeeder)->run();
    }

    public function down(): void
    {
        ChecklistTemplate::query()
            ->whereIn('slug', ['sales', 'service'])
            ->update(['is_active' => false]);

        $legacy = ChecklistTemplate::query()->where('slug', 'gateway-5s')->first();

        if ($legacy) {
            $settings = $legacy->settings ?? [];
            unset($settings['workspace_hidden']);
            $legacy->update(['settings' => $settings]);
        }
    }
};
