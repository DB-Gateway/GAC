<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $this->canonicalizeColumn(
            'users',
            'user_type',
            'PROPERTY_MANAGEMENT'
        );
        $this->canonicalizeColumn(
            'checklist_submissions',
            'submitted_by_user_type',
            'PROPERTY_MANAGEMENT'
        );
        $this->canonicalizeColumn(
            'checklist_responses',
            'escalation_target',
            'property_management'
        );

        $this->canonicalizeJsonColumn('checklist_items', 'metadata');
        $this->canonicalizeJsonColumn('checklist_responses', 'details');
        $this->canonicalizeJsonColumn('checklist_responses', 'item_snapshot');
        $this->canonicalizeJsonColumn('notifications', 'data');
        $this->canonicalizeJsonColumn('reports', 'filters');
        $this->canonicalizeJsonColumn('reports', 'data_snapshot');
    }

    public function down(): void
    {
        // This is a terminology correction. Restoring the incorrect meaning of
        // PM during rollback would corrupt records created after this migration.
    }

    private function canonicalizeColumn(
        string $table,
        string $column,
        string $canonicalValue
    ): void {
        if (! Schema::hasTable($table) || ! Schema::hasColumn($table, $column)) {
            return;
        }

        DB::table($table)
            ->whereRaw(
                "LOWER(TRIM({$column})) IN (?, ?, ?, ?, ?, ?, ?)",
                [
                    'pm',
                    'property management',
                    'property_management',
                    'property mgmt',
                    'purchasing manager',
                    'purchasing_manager',
                    'purchasing mgr',
                ]
            )
            ->update([$column => $canonicalValue]);
    }

    private function canonicalizeJsonColumn(string $table, string $column): void
    {
        if (! Schema::hasTable($table) || ! Schema::hasColumn($table, $column)) {
            return;
        }

        DB::table($table)
            ->select(['id', $column])
            ->whereNotNull($column)
            ->orderBy('id')
            ->chunkById(200, function ($rows) use ($table, $column): void {
                foreach ($rows as $row) {
                    $decoded = is_string($row->{$column})
                        ? json_decode($row->{$column}, true)
                        : (array) $row->{$column};

                    if (! is_array($decoded)) {
                        continue;
                    }

                    $rewritten = $this->rewriteTerminology($decoded);
                    if ($rewritten === $decoded) {
                        continue;
                    }

                    DB::table($table)
                        ->where('id', $row->id)
                        ->update([
                            $column => json_encode(
                                $rewritten,
                                JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE
                            ),
                        ]);
                }
            });
    }

    private function rewriteTerminology(mixed $value, ?string $context = null): mixed
    {
        if (is_array($value)) {
            $rewritten = [];
            foreach ($value as $key => $child) {
                $childContext = is_string($key) ? $key : $context;
                $rewritten[$key] = $this->rewriteTerminology($child, $childContext);
            }

            return $rewritten;
        }

        if (! is_string($value)) {
            return $value;
        }

        $normalized = mb_strtolower(trim($value));
        $isPmTerminology = in_array($normalized, [
            'pm',
            'property management',
            'property_management',
            'property mgmt',
            'purchasing manager',
            'purchasing_manager',
            'purchasing mgr',
        ], true);

        if (! $isPmTerminology) {
            return $value;
        }

        $normalizedContext = mb_strtolower((string) $context);
        if (str_contains($normalizedContext, 'label')) {
            return 'Property Management';
        }
        if (str_contains($normalizedContext, 'role') || str_contains($normalizedContext, 'user_type')) {
            return 'PROPERTY_MANAGEMENT';
        }
        if (str_contains($normalizedContext, 'escalation')) {
            return 'property_management';
        }

        return $normalized === 'pm' ? $value : 'Property Management';
    }
};
