<?php

namespace Tests\Feature;

use App\Models\ChecklistItem;
use App\Models\ChecklistSubmission;
use App\Models\ChecklistTemplate;
use App\Models\Report;
use App\Models\User;
use Database\Seeders\ChecklistTemplateSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class DosRoleAccessTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(ChecklistTemplateSeeder::class);
    }

    public function test_dos_role_aliases_are_canonical_and_non_administrative(): void
    {
        $aliases = [
            'SM' => User::ROLE_SALES_MANAGER,
            'Sales Manager' => User::ROLE_SALES_MANAGER,
            'Aftersales Manager' => User::ROLE_AFTERSALES_MANAGER,
            'CE' => User::ROLE_CE_SERVICE,
            'JC' => User::ROLE_JOB_CONTROLLER,
            'Parts' => User::ROLE_PARTS_SUPERVISOR,
            'WS SUP' => User::ROLE_WORKSHOP_SUPERVISOR,
            'WORSHOP SUP' => User::ROLE_WORKSHOP_SUPERVISOR,
            'WS' => User::ROLE_WORKSHOP,
        ];

        foreach ($aliases as $alias => $expected) {
            $this->assertSame($expected, User::roleCodeFor($alias));
        }

        foreach (array_unique($aliases) as $role) {
            $user = User::factory()->make(['user_type' => $role]);
            $this->assertTrue($user->isDosOperationalRole());
            $this->assertFalse($user->hasAdministrativeAccess());
            $this->assertArrayHasKey($role, User::roleOptions());
        }
    }

    public function test_unknown_non_admin_role_fails_closed_for_checklist_access(): void
    {
        $user = User::factory()->create([
            'user_type' => 'WORKSHOP SUPERVISOR TYPO',
            'branch' => 'Pasong Tamo',
            'account_status' => 'active',
        ]);

        $this->assertFalse($user->hasAdministrativeAccess());
        $this->assertSame([], $user->allowedChecklistSlugs());
        $this->assertFalse($user->canAccessChecklist('dealer-operations-standards'));

        Sanctum::actingAs($user);
        $this->getJson(route('api.checklists.index'))
            ->assertOk()
            ->assertJsonCount(0, 'checklists');
        $this->getJson(route('api.checklists.show', [
            'template' => 'dealer-operations-standards',
            'date' => '2026-09-07',
        ]))->assertForbidden();
    }

    public function test_each_dos_role_catalog_and_loaded_template_are_limited_to_its_assignment(): void
    {
        $cases = [
            User::ROLE_SALES_MANAGER => ['dealer-operations-standards-sales', 22],
            User::ROLE_AFTERSALES_MANAGER => ['dealer-operations-standards', 50],
            User::ROLE_CE_SERVICE => ['dealer-operations-standards', 9],
            User::ROLE_JOB_CONTROLLER => ['dealer-operations-standards', 1],
            User::ROLE_PARTS_SUPERVISOR => ['dealer-operations-standards', 3],
            User::ROLE_WORKSHOP_SUPERVISOR => ['dealer-operations-standards', 1],
            User::ROLE_WORKSHOP => ['dealer-operations-standards', 11],
        ];

        foreach ($cases as $role => [$slug, $expectedItemCount]) {
            $user = $this->dosUser($role);
            Sanctum::actingAs($user);

            $catalog = $this->getJson(route('api.checklists.index', ['date' => '2026-09-07']))
                ->assertOk()
                ->assertJsonCount(1, 'checklists')
                ->assertJsonPath('checklists.0.slug', $slug)
                ->assertJsonPath('checklists.0.item_count', $expectedItemCount)
                ->assertJsonPath('checklists.0.work_unit_count', $expectedItemCount);

            $this->assertSame($slug, $catalog->json('checklists.0.slug'));

            $loaded = $this->getJson(route('api.checklists.show', [
                'template' => $slug,
                'date' => '2026-09-07',
            ]))->assertOk();
            $items = collect($loaded->json('template.sections'))
                ->flatMap(fn (array $section): array => $section['items']);

            $this->assertCount($expectedItemCount, $items, "Unexpected item count for $role");
            $this->assertTrue($items->every(
                fn (array $item): bool => $user->canAccessChecklistItem(
                    $slug,
                    data_get($item, 'metadata.checker')
                )
            ));

            $wrongDosSlug = $slug === 'dealer-operations-standards-sales'
                ? 'dealer-operations-standards'
                : 'dealer-operations-standards-sales';
            $this->getJson(route('api.checklists.show', [
                'template' => $wrongDosSlug,
                'date' => '2026-09-07',
            ]))->assertForbidden();
            $this->getJson(route('api.checklists.show', [
                'template' => 'sales',
                'date' => '2026-09-07',
            ]))->assertForbidden();
            $this->getJson(route('api.checklists.show', [
                'template' => 'restroom',
                'date' => '2026-09-07',
            ]))->assertForbidden();
        }
    }

    public function test_workshop_supervisor_matches_the_legacy_worshop_sup_checker_typo(): void
    {
        $template = ChecklistTemplate::where('slug', 'dealer-operations-standards')->firstOrFail();
        $item = $this->itemForChecker($template, 'WORKSHOP SUP');
        $metadata = $item->metadata;
        $metadata['checker'] = 'WORSHOP SUP';
        $item->update(['metadata' => $metadata]);

        $user = $this->dosUser(User::ROLE_WORKSHOP_SUPERVISOR);
        Sanctum::actingAs($user);

        $response = $this->getJson(route('api.checklists.show', [
            'template' => $template,
            'date' => '2026-09-07',
        ]))->assertOk();
        $items = collect($response->json('template.sections'))
            ->flatMap(fn (array $section): array => $section['items']);

        $this->assertCount(1, $items);
        $this->assertSame($item->key, $items->first()['key']);
    }

    public function test_checker_backfill_migration_normalizes_existing_dos_templates(): void
    {
        $templates = ChecklistTemplate::query()
            ->whereIn('slug', [
                'dealer-operations-standards',
                'dealer-operations-standards-sales',
            ])
            ->get()
            ->keyBy('slug');

        foreach ($templates as $template) {
            foreach ($template->items()->get() as $item) {
                $metadata = $item->metadata;
                $metadata['checker'] = 'LEGACY CHECKER';
                $item->update(['metadata' => $metadata]);
            }
        }

        $migration = require database_path(
            'migrations/2026_09_07_000800_backfill_dos_checker_metadata.php'
        );
        $migration->up();

        $salesCounts = $templates['dealer-operations-standards-sales']
            ->items()
            ->get()
            ->countBy(fn (ChecklistItem $item): string => User::roleCodeFor(
                data_get($item->metadata, 'checker')
            ));
        $aftersalesCounts = $templates['dealer-operations-standards']
            ->items()
            ->get()
            ->countBy(fn (ChecklistItem $item): string => User::roleCodeFor(
                data_get($item->metadata, 'checker')
            ));

        $this->assertSame([User::ROLE_SALES_MANAGER => 22], $salesCounts->all());
        $this->assertCount(6, $aftersalesCounts);
        $this->assertSame(50, $aftersalesCounts->get(User::ROLE_AFTERSALES_MANAGER));
        $this->assertSame(9, $aftersalesCounts->get(User::ROLE_CE_SERVICE));
        $this->assertSame(11, $aftersalesCounts->get(User::ROLE_WORKSHOP));
        $this->assertSame(3, $aftersalesCounts->get(User::ROLE_PARTS_SUPERVISOR));
        $this->assertSame(1, $aftersalesCounts->get(User::ROLE_JOB_CONTROLLER));
        $this->assertSame(1, $aftersalesCounts->get(User::ROLE_WORKSHOP_SUPERVISOR));
    }

    public function test_dos_role_cannot_write_an_item_assigned_to_another_checker(): void
    {
        $template = ChecklistTemplate::where('slug', 'dealer-operations-standards')->firstOrFail();
        $asmItem = $this->itemForChecker($template, 'ASM');
        $ceItem = $this->itemForChecker($template, 'CE SERVICE');
        $user = $this->dosUser(User::ROLE_CE_SERVICE);
        Sanctum::actingAs($user);

        $this->postJson(route('api.checklists.save-draft', $template), [
            'date' => '2026-09-07',
            'responses' => [[
                'item_id' => $asmItem->id,
                'item_key' => $asmItem->key,
                'status' => 'yes',
            ]],
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('responses.0.item_key');
        $this->assertDatabaseCount('checklist_submissions', 0);

        $this->postJson(route('api.checklists.save-draft', $template), [
            'date' => '2026-09-07',
            'responses' => [[
                'item_id' => $ceItem->id,
                'item_key' => $ceItem->key,
                'status' => 'yes',
            ]],
        ])
            ->assertCreated()
            ->assertJsonPath("submission.responses.{$ceItem->key}.status", 'yes');
    }

    public function test_role_scoped_submission_validates_and_scores_only_assigned_items(): void
    {
        $template = ChecklistTemplate::where('slug', 'dealer-operations-standards')->firstOrFail();
        $item = $this->itemForChecker($template, 'JC');
        $user = $this->dosUser(User::ROLE_JOB_CONTROLLER);
        Sanctum::actingAs($user);

        $this->postJson(route('api.checklists.submit', $template), [
            'date' => '2026-09-07',
            'responses' => [[
                'item_id' => $item->id,
                'item_key' => $item->key,
                'status' => 'yes',
            ]],
        ])
            ->assertCreated()
            ->assertJsonPath('submission.scores.total', 1)
            ->assertJsonPath('submission.scores.answered', 1)
            ->assertJsonCount(1, 'submission.responses');

        $this->assertDatabaseHas('checklist_submissions', [
            'user_id' => $user->id,
            'checklist_template_id' => $template->id,
            'status' => 'submitted',
        ]);
        $this->assertSame(1, ChecklistSubmission::firstOrFail()->scores['total']);

        $this->getJson(route('api.checklists.index', ['date' => '2026-09-07']))
            ->assertOk()
            ->assertJsonPath('checklists.0.item_count', 1)
            ->assertJsonPath('checklists.0.submission.total_items', 1)
            ->assertJsonPath('checklists.0.submission.answered_items', 1)
            ->assertJsonPath('checklists.0.submission.completion_percentage', 100);
    }

    public function test_dos_web_dashboard_reports_and_export_show_only_own_assigned_records(): void
    {
        $aftersales = ChecklistTemplate::where('slug', 'dealer-operations-standards')->firstOrFail();
        $sales = ChecklistTemplate::where('slug', 'dealer-operations-standards-sales')->firstOrFail();
        $restroom = ChecklistTemplate::where('slug', 'restroom')->firstOrFail();
        $ce = $this->dosUser(User::ROLE_CE_SERVICE);
        $ce->update(['name' => 'DOS CE Viewer']);
        $asm = $this->dosUser(User::ROLE_AFTERSALES_MANAGER);
        $asm->update(['name' => 'Other ASM Auditor']);
        $otherCe = $this->dosUser(User::ROLE_CE_SERVICE);
        $otherCe->update(['name' => 'Other CE Auditor']);
        $salesManager = $this->dosUser(User::ROLE_SALES_MANAGER);
        $salesManager->update(['name' => 'Other Sales Auditor']);

        $own = $this->reportSubmission($ce, $aftersales);
        $this->reportSubmission($asm, $aftersales);
        $this->reportSubmission($otherCe, $aftersales);
        $this->reportSubmission($salesManager, $sales);
        $this->reportSubmission($ce, $restroom);

        $dashboard = $this->actingAs($ce)->get(route('dashboard'));
        $dashboard
            ->assertOk()
            ->assertViewHas('reportHistory', fn ($history): bool => $history->pluck('id')->all() === [$own->id])
            ->assertViewHas('recentActivities', fn ($activities): bool => $activities->count() === 1
                && $activities->first()['user'] === 'DOS CE Viewer')
            ->assertViewHas('dashboardSummary', fn (array $summary): bool => $summary['submitted_count'] === 1
                && $summary['dos_completed'] === 1)
            ->assertViewHas('reportTemplateOptions', fn ($options): bool => $options->pluck('slug')->all() === [
                'dealer-operations-standards',
            ]);

        $report = $this->get(route('reports.index'));
        $report
            ->assertOk()
            ->assertViewHas('history', fn ($history): bool => $history->pluck('id')->all() === [$own->id])
            ->assertViewHas('templateOptions', fn ($options): bool => $options->pluck('slug')->all() === [
                'dealer-operations-standards',
            ]);

        $csv = $this->get(route('reports.export'))
            ->assertOk()
            ->streamedContent();
        $this->assertStringContainsString('DOS CE Viewer', $csv);
        $this->assertStringNotContainsString('Other ASM Auditor', $csv);
        $this->assertStringNotContainsString('Other CE Auditor', $csv);
        $this->assertStringNotContainsString('Other Sales Auditor', $csv);
        $this->assertSame(
            [$own->id],
            Report::where('type', 'csv_export')
                ->latest('id')
                ->firstOrFail()
                ->data_snapshot['submission_ids']
        );
    }

    public function test_dos_web_reporting_scopes_allowed_and_disallowed_archived_snapshots(): void
    {
        $ce = $this->dosUser(User::ROLE_CE_SERVICE);
        $allowed = $this->reportSubmission(
            $ce,
            null,
            'dealer-operations-standards',
            'Archived Aftersales DOS'
        );
        $this->reportSubmission($ce, null, 'restroom', 'Archived Restroom');

        $this->actingAs($ce)
            ->get(route('reports.index'))
            ->assertOk()
            ->assertViewHas('history', fn ($history): bool => $history->pluck('id')->all() === [$allowed->id]);

        $this->get(route('dashboard'))
            ->assertOk()
            ->assertViewHas('reportHistory', fn ($history): bool => $history->pluck('id')->all() === [$allowed->id]);

        $this->get(route('reports.index', ['template' => 'restroom']))
            ->assertOk()
            ->assertViewHas('history', fn ($history): bool => $history->isEmpty());
    }

    public function test_sales_dos_submission_counts_in_the_web_dos_dashboard_metrics(): void
    {
        $this->travelTo('2026-09-07 12:00:00');
        $salesManager = $this->dosUser(User::ROLE_SALES_MANAGER);
        $sales = ChecklistTemplate::where('slug', 'dealer-operations-standards-sales')->firstOrFail();
        $this->reportSubmission($salesManager, $sales);

        $this->actingAs($salesManager)
            ->get(route('dashboard'))
            ->assertOk()
            ->assertViewHas('dashboardSummary', fn (array $summary): bool => $summary['submitted_count'] === 1
                && $summary['dos_completed'] === 1
                && $summary['dos_completion_rate'] === 100.0)
            ->assertViewHas('monthlyTrend', fn ($trend): bool => $trend->last()['count'] === 1)
            ->assertViewHas('reportTemplateOptions', fn ($options): bool => $options->pluck('slug')->all() === [
                'dealer-operations-standards-sales',
            ]);
    }

    private function dosUser(string $role): User
    {
        return User::factory()->create([
            'email' => strtolower(str_replace(' ', '.', $role)).uniqid('@example.test'),
            'branch' => 'Pasong Tamo',
            'user_type' => $role,
            'pic_assignment_type' => null,
            'account_status' => 'active',
        ]);
    }

    private function itemForChecker(ChecklistTemplate $template, string $checker): ChecklistItem
    {
        /** @var ChecklistItem $item */
        $item = $template->items
            ->first(fn (ChecklistItem $candidate): bool => data_get(
                $candidate->metadata,
                'checker'
            ) === $checker);

        $this->assertNotNull($item, "Missing seeded DOS checker: $checker");

        return $item;
    }

    private function reportSubmission(
        User $user,
        ?ChecklistTemplate $template,
        ?string $snapshotSlug = null,
        ?string $snapshotName = null
    ): ChecklistSubmission {
        $slug = $template?->slug ?? $snapshotSlug;
        $name = $template?->name ?? $snapshotName ?? 'Archived checklist';
        $branch = trim((string) $user->branch);

        return ChecklistSubmission::create([
            'checklist_template_id' => $template?->id,
            'user_id' => $user->id,
            'submitted_by_user_id' => $user->id,
            'submitted_by_name' => $user->name,
            'submitted_by_email' => $user->email,
            'submitted_by_user_type' => $user->roleCode(),
            'status' => 'submitted',
            'branch' => $branch,
            'scope_key' => hash('sha256', mb_strtolower($branch)),
            'audit_date' => now()->toDateString(),
            'template_version' => $template?->version ?? 1,
            'template_snapshot' => [
                'slug' => $slug,
                'name' => $name,
            ],
            'scores' => [
                'total' => 1,
                'answered' => 1,
                'yes' => 1,
                'no' => 0,
                'na' => 0,
                'applicable' => 1,
                'percentage' => 100,
                'completion_percentage' => 100,
            ],
            'submitted_at' => now(),
        ]);
    }
}
