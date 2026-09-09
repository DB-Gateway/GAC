<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('checklist_templates')
            || ! Schema::hasTable('checklist_items')
            || ! Schema::hasColumn('checklist_items', 'metadata')) {
            return;
        }

        $templates = DB::table('checklist_templates')
            ->whereIn('slug', [
                'dealer-operations-standards',
                'dealer-operations-standards-sales',
            ])
            ->pluck('slug', 'id');

        if ($templates->isEmpty()) {
            return;
        }

        DB::table('checklist_items')
            ->whereIn('checklist_template_id', $templates->keys())
            ->whereNotNull('metadata')
            ->orderBy('id')
            ->chunkById(100, function ($items) use ($templates): void {
                foreach ($items as $item) {
                    $metadata = json_decode((string) $item->metadata, true);
                    if (! is_array($metadata)) {
                        continue;
                    }

                    $slug = $templates->get($item->checklist_template_id);
                    $number = (int) ($metadata['number'] ?? 0);
                    if ($slug === 'dealer-operations-standards-sales') {
                        $checker = 'SALES MANAGER';
                    } elseif ($slug === 'dealer-operations-standards' && $number > 0) {
                        $checker = $this->aftersalesCheckerFor($number);
                    } else {
                        continue;
                    }

                    $metadata['checker'] = $checker;

                    DB::table('checklist_items')
                        ->where('id', $item->id)
                        ->update([
                            'metadata' => json_encode($metadata, JSON_UNESCAPED_UNICODE),
                            'updated_at' => now(),
                        ]);
                }
            });
    }

    public function down(): void
    {
        // This is a non-destructive data normalization. Existing checker data
        // may predate this migration, so rollback intentionally keeps it.
    }

    private function aftersalesCheckerFor(int $number): string
    {
        return match (true) {
            in_array($number, [28, 30, 31, 32, 33, 34, 64, 66, 74], true) => 'CE SERVICE',
            in_array($number, [39, 43, 45, 46, 47, 48, 49, 51, 52, 53, 65], true) => 'WS',
            in_array($number, [40, 41, 42], true) => 'Parts Supervisor',
            $number === 38 => 'JC',
            $number === 36 => 'WORKSHOP SUP',
            default => 'ASM',
        };
    }
};
