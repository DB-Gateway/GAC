<?php

namespace Tests\Feature;

use App\Models\ChecklistItem;
use App\Models\ChecklistSection;
use App\Models\ChecklistTemplate;
use Database\Seeders\ChecklistTemplateSeeder;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DosWorkbookMetadataBackfillTest extends TestCase
{
    use RefreshDatabase;

    public function test_template_seeder_loads_complete_dos_metadata_from_the_canonical_json_files(): void
    {
        $this->seed(ChecklistTemplateSeeder::class);

        $sales = ChecklistTemplate::query()
            ->where('slug', 'dealer-operations-standards-sales')
            ->firstOrFail();
        $aftersales = ChecklistTemplate::query()
            ->where('slug', 'dealer-operations-standards')
            ->firstOrFail();

        $this->assertSame(22, $sales->items()->count());
        $this->assertSame(75, $aftersales->items()->count());

        $salesMetadata = $sales->items()->where('key', 'dos-1')->firstOrFail()->metadata;
        $this->assertSame('Basic', $salesMetadata['category']);
        $this->assertSame('SALES MANAGER', $salesMetadata['checker']);
        $this->assertSame(
            '1. Check through observation if it meets the MMPC VI Standard Requirements',
            $salesMetadata['how_to_check']
        );
        $this->assertStringContainsString('Accomplish Inspection Request', $salesMetadata['bom_task']);

        $aftersalesMetadata = $aftersales->items()
            ->where('key', 'dos-as-36')
            ->firstOrFail()
            ->metadata;
        $this->assertSame('WORKSHOP SUP', $aftersalesMetadata['checker']);
        $this->assertSame('Workshop Scheduling', $aftersalesMetadata['coverage']);
        $this->assertNotSame('', $aftersalesMetadata['how_to_check']);
        $this->assertNotSame('', $aftersalesMetadata['bom_task']);

        $this->assertSame([
            'dos-facade' => 'Facilities — Facade',
            'dos-showroom-area' => 'Facilities — Showroom Area',
            'dos-test-drive' => 'Product Presentation and Test Drive — Test Drive',
        ], $sales->sections()->pluck('title', 'key')->all());
    }

    public function test_backfill_is_idempotent_and_preserves_valid_admin_metadata(): void
    {
        $this->seed(ChecklistTemplateSeeder::class);

        $sales = ChecklistTemplate::query()
            ->where('slug', 'dealer-operations-standards-sales')
            ->firstOrFail();
        $aftersales = ChecklistTemplate::query()
            ->where('slug', 'dealer-operations-standards')
            ->firstOrFail();

        $salesItem = $sales->items()->where('key', 'dos-1')->firstOrFail();
        $salesMetadata = $salesItem->metadata;
        unset($salesMetadata['how_to_check'], $salesMetadata['checker']);
        $salesMetadata['bom_task'] = 'Admin-authored remediation steps';
        $salesMetadata['subject'] = 'Admin-maintained facade subject';
        $salesMetadata['escalation'] = "PM \u{FFFD} Purchasing";
        $salesMetadata['admin_note'] = 'Retain this custom field';
        $salesItem->update(['metadata' => $salesMetadata]);

        $legacyAftersalesItem = $aftersales->items()->where('key', 'dos-as-2')->firstOrFail();
        $legacyAftersalesItem->update([
            'key' => 'dos-item-2',
            'metadata' => [
                'number' => 2,
                'level' => 'Admin-defined level',
                'subject' => 'Admin-maintained training subject',
                'bom_task' => 'Broken â€” workbook text',
                'how_to_check' => '',
                'admin_note' => 'Retain this too',
            ],
        ]);

        $keyMatchedAftersalesItem = $aftersales->items()->where('key', 'dos-as-3')->firstOrFail();
        $keyMatchedAftersalesItem->update([
            'key' => 'dos-item-3',
            'metadata' => null,
        ]);

        $corruptedTitles = [
            'dos-facade' => 'Facilities ? Facade',
            'dos-showroom-area' => 'Facilities â€” Showroom Area',
            'dos-test-drive' => "Product Presentation and Test Drive \u{FFFD} Test Drive",
        ];
        foreach ($corruptedTitles as $key => $title) {
            ChecklistSection::query()
                ->where('checklist_template_id', $sales->id)
                ->where('key', $key)
                ->update(['title' => $title]);
        }

        $migration = $this->backfillMigration();
        $migration->up();

        $salesMetadata = $salesItem->fresh()->metadata;
        $this->assertSame(
            '1. Check through observation if it meets the MMPC VI Standard Requirements',
            $salesMetadata['how_to_check']
        );
        $this->assertSame('SALES MANAGER', $salesMetadata['checker']);
        $this->assertSame('PM', $salesMetadata['escalation']);
        $this->assertSame('Admin-authored remediation steps', $salesMetadata['bom_task']);
        $this->assertSame('Admin-maintained facade subject', $salesMetadata['subject']);
        $this->assertSame('Retain this custom field', $salesMetadata['admin_note']);

        $legacyMetadata = $legacyAftersalesItem->fresh()->metadata;
        $this->assertSame('Admin-defined level', $legacyMetadata['level']);
        $this->assertSame('Admin-maintained training subject', $legacyMetadata['subject']);
        $this->assertSame('follow up action plan and monitor compliance', $legacyMetadata['bom_task']);
        $this->assertSame(
            'Verify if dealer have assigned 1 Aftersales Training PIC as aligned with MMPC NTD Database.',
            $legacyMetadata['how_to_check']
        );
        $this->assertSame('Standard', $legacyMetadata['category']);
        $this->assertSame('ASM', $legacyMetadata['checker']);
        $this->assertSame('Retain this too', $legacyMetadata['admin_note']);

        $keyMatchedMetadata = $keyMatchedAftersalesItem->fresh()->metadata;
        $this->assertSame(3, $keyMatchedMetadata['number']);
        $this->assertSame('Training Requirements', $keyMatchedMetadata['subject']);
        $this->assertSame('Check the training record from Training Department', $keyMatchedMetadata['how_to_check']);

        $this->assertSame([
            'dos-facade' => 'Facilities — Facade',
            'dos-showroom-area' => 'Facilities — Showroom Area',
            'dos-test-drive' => 'Product Presentation and Test Drive — Test Drive',
        ], $sales->sections()->pluck('title', 'key')->all());

        $metadataAfterFirstRun = [
            $salesItem->id => $salesMetadata,
            $legacyAftersalesItem->id => $legacyMetadata,
            $keyMatchedAftersalesItem->id => $keyMatchedMetadata,
        ];

        ChecklistSection::query()
            ->where('checklist_template_id', $sales->id)
            ->where('key', 'dos-facade')
            ->update(['title' => 'Admin-defined Facade Zone']);

        $migration->up();

        foreach ($metadataAfterFirstRun as $itemId => $expectedMetadata) {
            $this->assertSame(
                $expectedMetadata,
                ChecklistItem::query()->findOrFail($itemId)->metadata
            );
        }

        $this->assertSame(
            'Admin-defined Facade Zone',
            $sales->sections()->where('key', 'dos-facade')->firstOrFail()->title
        );
    }

    private function backfillMigration(): Migration
    {
        return require database_path(
            'migrations/2026_09_07_001000_backfill_dos_workbook_metadata.php'
        );
    }
}
