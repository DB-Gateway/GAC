<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('users') && Schema::hasColumn('users', 'user_type')) {
            DB::table('users')
                ->whereRaw('LOWER(TRIM(user_type)) IN (?, ?)', ['gm', 'general manager'])
                ->update(['user_type' => 'ADMIN']);
        }

        $this->replaceChecklistResponsibility('general manager', 'COMPLIANCE ADMINISTRATOR');
    }

    public function down(): void
    {
        if (Schema::hasTable('users') && Schema::hasColumn('users', 'user_type')) {
            DB::table('users')
                ->where('user_type', 'ADMIN')
                ->update(['user_type' => 'General Manager']);
        }

        $this->replaceChecklistResponsibility('compliance administrator', 'GENERAL MANAGER');
    }

    private function replaceChecklistResponsibility(string $search, string $replacement): void
    {
        if (! Schema::hasTable('checklist_items') || ! Schema::hasColumn('checklist_items', 'metadata')) {
            return;
        }

        DB::table('checklist_items')
            ->whereNotNull('metadata')
            ->orderBy('id')
            ->chunkById(200, function ($items) use ($search, $replacement): void {
                foreach ($items as $item) {
                    $metadata = json_decode((string) $item->metadata, true);

                    if (! is_array($metadata)) {
                        continue;
                    }

                    $changed = false;
                    foreach (['pic', 'escalation'] as $field) {
                        if (! is_string($metadata[$field] ?? null)) {
                            continue;
                        }

                        $updatedValue = str_ireplace($search, $replacement, $metadata[$field]);
                        if ($updatedValue !== $metadata[$field]) {
                            $metadata[$field] = $updatedValue;
                            $changed = true;
                        }
                    }

                    if ($changed) {
                        DB::table('checklist_items')
                            ->where('id', $item->id)
                            ->update(['metadata' => json_encode($metadata, JSON_UNESCAPED_UNICODE)]);
                    }
                }
            });
    }
};
