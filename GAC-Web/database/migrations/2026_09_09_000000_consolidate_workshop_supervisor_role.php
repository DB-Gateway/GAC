<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    private const CANONICAL_ROLE = 'WORKSHOP SUP';

    public function up(): void
    {
        $this->canonicalizeChecklistItems();
        $this->canonicalizeUsers();
    }

    public function down(): void
    {
        // The former Workshop and Workshop Supervisor assignments cannot be
        // separated reliably after consolidation, so rollback keeps the
        // canonical role and preserves every response and user account.
    }

    private function canonicalizeChecklistItems(): void
    {
        if (! Schema::hasTable('checklist_templates')
            || ! Schema::hasTable('checklist_items')
            || ! Schema::hasColumn('checklist_items', 'metadata')) {
            return;
        }

        $templateIds = DB::table('checklist_templates')
            ->whereIn('slug', [
                'dealer-operations-standards',
                'dealer-operations-standards-subform',
            ])
            ->pluck('id');

        if ($templateIds->isEmpty()) {
            return;
        }

        DB::table('checklist_items')
            ->whereIn('checklist_template_id', $templateIds)
            ->whereNotNull('metadata')
            ->orderBy('id')
            ->chunkById(100, function ($items): void {
                foreach ($items as $item) {
                    $metadata = json_decode((string) $item->metadata, true);
                    if (! is_array($metadata)
                        || ! $this->isWorkshopSupervisorAlias($metadata['checker'] ?? null)
                        || ($metadata['checker'] ?? null) === self::CANONICAL_ROLE) {
                        continue;
                    }

                    $metadata['checker'] = self::CANONICAL_ROLE;

                    DB::table('checklist_items')
                        ->where('id', $item->id)
                        ->update([
                            'metadata' => json_encode($metadata, JSON_UNESCAPED_UNICODE),
                            'updated_at' => now(),
                        ]);
                }
            });
    }

    private function canonicalizeUsers(): void
    {
        if (! Schema::hasTable('users') || ! Schema::hasColumn('users', 'user_type')) {
            return;
        }

        DB::table('users')
            ->whereNotNull('user_type')
            ->orderBy('id')
            ->chunkById(100, function ($users): void {
                foreach ($users as $user) {
                    if (! $this->isWorkshopSupervisorAlias($user->user_type)
                        || $user->user_type === self::CANONICAL_ROLE) {
                        continue;
                    }

                    DB::table('users')
                        ->where('id', $user->id)
                        ->update([
                            'user_type' => self::CANONICAL_ROLE,
                            'updated_at' => now(),
                        ]);
                }
            });
    }

    private function isWorkshopSupervisorAlias(mixed $value): bool
    {
        $normalized = preg_replace(
            '/[^a-z0-9]+/',
            ' ',
            strtolower(trim((string) $value))
        );

        return in_array(trim((string) $normalized), [
            'ws',
            'ws sup',
            'workshop',
            'workshop sup',
            'workshop supervisor',
            'worshop sup',
            'worshop supervisor',
        ], true);
    }
};
