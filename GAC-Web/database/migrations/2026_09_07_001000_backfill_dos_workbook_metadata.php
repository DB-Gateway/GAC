<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

return new class extends Migration
{
    /**
     * The section keys are stable even when an installed database contains a
     * title whose em dash was damaged while importing the workbook data.
     *
     * @var array<string, string>
     */
    private const SALES_SECTION_TITLES = [
        'dos-facade' => 'Facilities — Facade',
        'dos-showroom-area' => 'Facilities — Showroom Area',
        'dos-test-drive' => 'Product Presentation and Test Drive — Test Drive',
    ];

    /**
     * @var array<string, array{filename: string, item_key_pattern: string, pic_field: string}>
     */
    private const SOURCES = [
        'dealer-operations-standards' => [
            'filename' => 'dos_aftersales_items.json',
            'item_key_pattern' => '/^dos-(?:as-|item-)?(\d+)$/',
            'pic_field' => 'PersonAccountable',
        ],
        'dealer-operations-standards-sales' => [
            'filename' => 'dos_sales_items.json',
            'item_key_pattern' => '/^dos-(\d+)$/',
            'pic_field' => 'PIC',
        ],
    ];

    public function up(): void
    {
        if (! Schema::hasTable('checklist_templates')) {
            return;
        }

        $templates = DB::table('checklist_templates')
            ->whereIn('slug', array_keys(self::SOURCES))
            ->get(['id', 'slug'])
            ->keyBy('slug');

        if ($templates->isEmpty()) {
            return;
        }

        DB::transaction(function () use ($templates): void {
            if (Schema::hasTable('checklist_items')
                && Schema::hasColumn('checklist_items', 'metadata')) {
                foreach (self::SOURCES as $slug => $source) {
                    $template = $templates->get($slug);
                    if ($template === null) {
                        continue;
                    }

                    $this->backfillItems(
                        (int) $template->id,
                        $this->canonicalItems($source),
                        $source['item_key_pattern']
                    );
                }
            }

            $salesTemplate = $templates->get('dealer-operations-standards-sales');
            if ($salesTemplate !== null
                && Schema::hasTable('checklist_sections')
                && Schema::hasColumn('checklist_sections', 'title')) {
                $this->repairSalesSectionTitles((int) $salesTemplate->id);
            }
        });
    }

    public function down(): void
    {
        // The migration only fills missing/corrupted workbook data. A rollback
        // cannot distinguish those repairs from later legitimate admin edits.
    }

    /**
     * @param  array<int, array<string, int|string>>  $canonicalItems
     */
    private function backfillItems(
        int $templateId,
        array $canonicalItems,
        string $itemKeyPattern
    ): void {
        DB::table('checklist_items')
            ->where('checklist_template_id', $templateId)
            ->select(['id', 'key', 'metadata'])
            ->orderBy('id')
            ->chunkById(100, function ($items) use ($canonicalItems, $itemKeyPattern): void {
                foreach ($items as $item) {
                    $metadata = $this->decodeMetadata($item->metadata);
                    if ($metadata === null) {
                        continue;
                    }

                    $number = $this->resolveItemNumber(
                        $metadata,
                        (string) $item->key,
                        $canonicalItems,
                        $itemKeyPattern
                    );

                    if ($number === null) {
                        continue;
                    }

                    [$merged, $changed] = $this->mergeMetadata(
                        $metadata,
                        $canonicalItems[$number]
                    );

                    if (! $changed) {
                        continue;
                    }

                    DB::table('checklist_items')
                        ->where('id', $item->id)
                        ->update([
                            'metadata' => json_encode(
                                $merged,
                                JSON_THROW_ON_ERROR | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE
                            ),
                            'updated_at' => now(),
                        ]);
                }
            });
    }

    private function repairSalesSectionTitles(int $templateId): void
    {
        $sections = DB::table('checklist_sections')
            ->where('checklist_template_id', $templateId)
            ->whereIn('key', array_keys(self::SALES_SECTION_TITLES))
            ->get(['id', 'key', 'title']);

        foreach ($sections as $section) {
            $title = (string) $section->title;
            if (! str_contains($title, '?') && ! $this->hasObviousEncodingDamage($title)) {
                continue;
            }

            DB::table('checklist_sections')
                ->where('id', $section->id)
                ->update([
                    'title' => self::SALES_SECTION_TITLES[$section->key],
                    'updated_at' => now(),
                ]);
        }
    }

    /**
     * @param  array{filename: string, item_key_pattern: string, pic_field: string}  $source
     * @return array<int, array<string, int|string>>
     */
    private function canonicalItems(array $source): array
    {
        $path = database_path('data/'.$source['filename']);
        if (! is_file($path)) {
            throw new RuntimeException("Missing DOS template data file: $path");
        }

        $contents = file_get_contents($path);
        if ($contents === false) {
            throw new RuntimeException("Unable to read DOS template data file: $path");
        }

        try {
            $rows = json_decode($contents, true, flags: JSON_THROW_ON_ERROR);
        } catch (JsonException $exception) {
            throw new RuntimeException(
                "Invalid DOS template data file: $path",
                previous: $exception
            );
        }

        if (! is_array($rows) || ! array_is_list($rows)) {
            throw new RuntimeException("DOS template data must be a JSON list: $path");
        }

        $items = [];
        foreach ($rows as $row) {
            if (! is_array($row)) {
                throw new RuntimeException("DOS template data contains an invalid row: $path");
            }

            $number = (int) ($row['No'] ?? 0);
            if ($number < 1 || isset($items[$number])) {
                throw new RuntimeException("DOS template data contains an invalid or duplicate item number: $path");
            }

            $level = trim((string) ($row['Category'] ?? 'Standard'));
            $items[$number] = [
                'number' => $number,
                'level' => $level,
                'category' => $level,
                'coverage' => Str::squish((string) ($row['Coverage'] ?? '')),
                'subject' => trim((string) ($row['Subject'] ?? '')),
                'checker' => $this->normalizedChecker((string) ($row['Checker'] ?? '')),
                'pic' => trim((string) ($row[$source['pic_field']] ?? '')),
                'bom_task' => trim((string) ($row['BOMTask'] ?? '')),
                'escalation' => trim((string) ($row['Escalation'] ?? '')),
                'how_to_check' => trim((string) ($row['HowToCheck'] ?? '')),
            ];
        }

        return $items;
    }

    /**
     * Null means the existing JSON is invalid and should be left untouched.
     *
     * @return array<string, mixed>|null
     */
    private function decodeMetadata(mixed $encoded): ?array
    {
        if ($encoded === null || (is_string($encoded) && trim($encoded) === '')) {
            return [];
        }

        if (is_array($encoded)) {
            return $encoded;
        }

        if (! is_string($encoded)) {
            return null;
        }

        try {
            $metadata = json_decode($encoded, true, flags: JSON_THROW_ON_ERROR);
        } catch (JsonException) {
            return null;
        }

        return is_array($metadata) ? $metadata : null;
    }

    /**
     * @param  array<string, mixed>  $metadata
     * @param  array<int, array<string, int|string>>  $canonicalItems
     */
    private function resolveItemNumber(
        array $metadata,
        string $itemKey,
        array $canonicalItems,
        string $itemKeyPattern
    ): ?int {
        $metadataNumber = (int) ($metadata['number'] ?? 0);
        if ($metadataNumber > 0 && isset($canonicalItems[$metadataNumber])) {
            return $metadataNumber;
        }

        if (preg_match($itemKeyPattern, $itemKey, $matches) !== 1) {
            return null;
        }

        $keyNumber = (int) $matches[1];

        return isset($canonicalItems[$keyNumber]) ? $keyNumber : null;
    }

    /**
     * @param  array<string, mixed>  $metadata
     * @param  array<string, int|string>  $canonical
     * @return array{0: array<string, mixed>, 1: bool}
     */
    private function mergeMetadata(array $metadata, array $canonical): array
    {
        $changed = false;

        foreach ($canonical as $field => $canonicalValue) {
            $hasField = array_key_exists($field, $metadata);
            $currentValue = $hasField ? $metadata[$field] : null;
            $isMissing = ! $hasField
                || $currentValue === null
                || (is_string($currentValue) && trim($currentValue) === '');
            $isEncodingDamaged = is_string($currentValue)
                && $this->hasObviousEncodingDamage($currentValue);

            if (! $isMissing && ! $isEncodingDamaged) {
                continue;
            }

            // An empty canonical cell has no information with which to enrich a
            // missing field. It can still safely replace a corrupted value.
            if ($isMissing && $canonicalValue === '') {
                continue;
            }

            if (! $hasField || $currentValue !== $canonicalValue) {
                $metadata[$field] = $canonicalValue;
                $changed = true;
            }
        }

        return [$metadata, $changed];
    }

    private function normalizedChecker(string $checker): string
    {
        $checker = trim($checker);

        return match (strtoupper($checker)) {
            'WS', 'WS SUP', 'WORKSHOP', 'WORSHOP SUP',
            'WORKSHOP SUP', 'WORKSHOP SUPERVISOR' => 'WORKSHOP SUP',
            default => $checker,
        };
    }

    private function hasObviousEncodingDamage(string $value): bool
    {
        if (str_contains($value, "\u{FFFD}")) {
            return true;
        }

        foreach (['Ã', 'Â', 'â€', 'ï¿½', 'ðŸ'] as $marker) {
            if (str_contains($value, $marker)) {
                return true;
            }
        }

        return false;
    }
};
