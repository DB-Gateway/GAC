<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        foreach ([
            ['checklist_templates', 'settings'],
            ['checklist_sections', 'metadata'],
            ['checklist_items', 'metadata'],
            ['checklist_submissions', 'context'],
            ['checklist_submissions', 'template_snapshot'],
            ['checklist_responses', 'details'],
            ['checklist_responses', 'item_snapshot'],
            ['notifications', 'data'],
            ['reports', 'filters'],
            ['reports', 'data_snapshot'],
        ] as [$table, $column]) {
            $this->canonicalizeJsonColumn($table, $column);
        }
    }

    public function down(): void
    {
        // Restoring the incorrect meaning of PM would corrupt newer records.
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

        $correctedText = preg_replace(
            '/purchasing[\s_-]+manager/i',
            'Property Management',
            $value
        ) ?? $value;
        $normalized = mb_strtolower(trim($correctedText));
        $isPmTerminology = in_array($normalized, [
            'pm',
            'property management',
            'property_management',
            'property mgmt',
            'property management (pm)',
            'pm (property management)',
        ], true);

        if (! $isPmTerminology) {
            return $correctedText;
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

        return $normalized === 'pm' ? $correctedText : 'Property Management';
    }
};
