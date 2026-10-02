<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::transaction(function (): void {
            $templates = DB::table('checklist_templates')
                ->whereIn('slug', ['restroom', 'utilities'])
                ->lockForUpdate()
                ->get();

            foreach ($templates as $template) {
                $settings = json_decode($template->settings ?? '{}', true, 512, JSON_THROW_ON_ERROR);
                if (($settings['validation_mode'] ?? null) !== 'time_slots') {
                    continue;
                }

                $existingSlots = collect($settings['time_slots'] ?? [])
                    ->filter(fn ($slot): bool => is_array($slot) && isset($slot['key']))
                    ->keyBy('key');
                $settings['time_slots'] = collect([
                    '08:00' => '8 AM',
                    '11:00' => '11 AM',
                    '14:00' => '2 PM',
                    '16:00' => '4 PM',
                ])->map(fn (string $label, string $key): array => array_merge(
                    $existingSlots->get($key, []),
                    ['key' => $key, 'label' => $label]
                ))->values()->all();

                if (($settings['instructions'] ?? null) === 'Mark each hourly inspection as Good (/) or Not Good (X), and add a row remark when needed.') {
                    $settings['instructions'] = 'Mark each scheduled inspection as Good (/) or Not Good (X), and add a row remark when needed.';
                }

                $description = $template->description;
                if ($description === 'Hourly restroom condition and orderliness inspection.') {
                    $description = 'Restroom condition and orderliness inspection at 8 AM, 11 AM, 2 PM, and 4 PM.';
                }

                $encodedSettings = json_encode($settings, JSON_THROW_ON_ERROR);
                if ($settings === json_decode($template->settings, true) && $description === $template->description) {
                    continue;
                }

                // Only update the schedule; preserve questions, toggles, and audit history.
                DB::table('checklist_templates')->where('id', $template->id)->update([
                    'settings' => $encodedSettings,
                    'description' => $description,
                    'version' => $template->version + 1,
                    'updated_at' => now(),
                ]);
            }
        });
    }

    public function down(): void
    {
        // Keep the updated schedule, as submissions may already use these slots.
    }
};
