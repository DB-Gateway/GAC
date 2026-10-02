<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::table('checklist_submissions')
            ->whereNull('branch_restroom_id')
            ->whereNotNull('template_snapshot')
            ->orderBy('id')
            ->chunkById(200, function ($submissions): void {
                foreach ($submissions as $submission) {
                    $snapshot = json_decode((string) $submission->template_snapshot, true);
                    if (! is_array($snapshot)) {
                        continue;
                    }

                    $slug = (string) ($snapshot['slug'] ?? '');
                    if (preg_match('/^restroom-(\d+)-(male|female|pwd)$/i', $slug, $matches) !== 1) {
                        continue;
                    }

                    $restroom = DB::table('branch_restrooms')->find((int) $matches[1]);
                    if ($restroom === null || strcasecmp(trim((string) $restroom->branch), trim((string) $submission->branch)) !== 0) {
                        continue;
                    }

                    DB::table('checklist_submissions')->where('id', $submission->id)->update([
                        'branch_restroom_id' => $restroom->id,
                        'restroom_area' => $restroom->area_type,
                        'restroom_gender' => strtolower($matches[2]),
                    ]);
                }
            });
    }

    public function down(): void
    {
        // Keep restored submission identity when rolling back this data repair.
    }
};
