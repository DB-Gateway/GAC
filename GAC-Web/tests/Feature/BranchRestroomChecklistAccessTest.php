<?php

namespace Tests\Feature;

use App\Models\BranchRestroom;
use App\Models\ChecklistSubmission;
use App\Models\ChecklistTemplate;
use App\Models\DealerChecklistSetting;
use App\Models\User;
use Database\Seeders\ChecklistTemplateSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class BranchRestroomChecklistAccessTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(ChecklistTemplateSeeder::class);
    }

    public function test_admin_can_add_update_and_delete_branch_restrooms(): void
    {
        $admin = User::factory()->create(['user_type' => User::ROLE_ADMINISTRATOR]);
        $dealer = 'Pasong Tamo';

        // 1. Store Office Restroom (PWD should be forced to false)
        $response = $this->actingAs($admin)->post(route('admin.checklist-access.restrooms.store', ['dealer' => $dealer]), [
            'name' => '2nd Floor Office Restroom',
            'area_type' => 'office',
            'has_male' => 1,
            'has_female' => 1,
            'has_pwd' => 1, // should be forced to 0 for office
        ]);

        $response->assertRedirect();
        $this->assertDatabaseHas('branch_restrooms', [
            'branch' => $dealer,
            'name' => '2nd Floor Office Restroom',
            'area_type' => 'office',
            'has_male' => true,
            'has_female' => true,
            'has_pwd' => false,
        ]);

        $restroom = BranchRestroom::query()
            ->where('branch', $dealer)
            ->where('name', '2nd Floor Office Restroom')
            ->firstOrFail();

        // 2. Update Restroom switches
        $this->actingAs($admin)->patch(route('admin.checklist-access.restrooms.update', ['dealer' => $dealer, 'restroom' => $restroom->id]), [
            'name' => 'Executive Office Restroom',
            'has_male' => 1,
            'has_female' => 0,
            'is_active' => 1,
        ])->assertRedirect();

        $restroom->refresh();
        $this->assertSame('Executive Office Restroom', $restroom->name);
        $this->assertTrue($restroom->has_male);
        $this->assertFalse($restroom->has_female);

        // 3. Delete Restroom
        $this->actingAs($admin)->delete(route('admin.checklist-access.restrooms.destroy', ['dealer' => $dealer, 'restroom' => $restroom->id]))
            ->assertRedirect();

        $this->assertDatabaseMissing('branch_restrooms', ['id' => $restroom->id]);
    }

    public function test_non_admin_cannot_modify_branch_restrooms(): void
    {
        $bom = User::factory()->create([
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'branch' => 'Pasong Tamo',
        ]);

        $this->actingAs($bom)->post(route('admin.checklist-access.restrooms.store', ['dealer' => 'Pasong Tamo']), [
            'name' => 'Unauthorized Restroom',
            'area_type' => 'customer',
        ])->assertForbidden();
    }

    public function test_turning_off_utility_disables_restroom_types_additions_and_app_account_access(): void
    {
        $dealer = 'Pasong Tamo';
        $restrooms = BranchRestroom::ensureDefaultsForBranch($dealer);
        $admin = User::factory()->create(['user_type' => User::ROLE_ADMINISTRATOR]);
        $utility = User::factory()->create([
            'email' => 'Utility.Disabled',
            'password' => 'password',
            'user_type' => User::ROLE_5S_UTILITIES,
            'branch' => $dealer,
            'account_status' => 'active',
        ]);
        $utility->createToken('existing-mobile-session');

        $availability = collect(DealerChecklistSetting::CATEGORIES)
            ->mapWithKeys(fn (array $definition, string $category): array => [
                $category => $category !== DealerChecklistSetting::CATEGORY_5S_UTILITY,
            ])
            ->all();
        $restroomPayload = $restrooms->mapWithKeys(fn (BranchRestroom $restroom): array => [
            $restroom->id => [
                'has_male' => true,
                'has_female' => true,
                'has_pwd' => $restroom->isCustomerArea(),
                'is_active' => true,
            ],
        ])->all();

        $this->actingAs($admin)
            ->patch(route('admin.checklist-access.update', ['dealer' => $dealer]), [
                'availability' => $availability,
                'restrooms' => $restroomPayload,
            ])
            ->assertRedirect();

        $this->assertDatabaseHas('dealer_checklist_settings', [
            'dealer' => $dealer,
            'category' => DealerChecklistSetting::CATEGORY_5S_UTILITY,
            'is_enabled' => false,
        ]);
        $this->assertSame(0, BranchRestroom::where('branch', $dealer)->where('has_male', true)->count());
        $this->assertSame(0, BranchRestroom::where('branch', $dealer)->where('has_female', true)->count());
        $this->assertSame(0, BranchRestroom::where('branch', $dealer)->where('has_pwd', true)->count());
        $this->assertSame(0, $utility->tokens()->count());

        $this->actingAs($admin)
            ->get(route('admin.checklist-access.index'))
            ->assertOk()
            ->assertSee('data-utility-enabled="0"', false)
            ->assertSee('Turn on 5S - Utility and save before configuring Male, Female, PWD, or adding a restroom.');

        $this->post(route('admin.checklist-access.restrooms.store', ['dealer' => $dealer]), [
            'name' => 'Blocked Restroom',
            'area_type' => 'customer',
            'has_male' => true,
        ])->assertForbidden();
        $this->assertDatabaseMissing('branch_restrooms', ['name' => 'Blocked Restroom']);

        $this->postJson('/api/login', [
            'username' => 'Utility.Disabled',
            'password' => 'password',
        ])
            ->assertForbidden()
            ->assertJsonPath(
                'message',
                'Your assigned checklist is currently unavailable for your dealer. Contact your system administrator.'
            );

        $this->actingAs($utility, 'sanctum')
            ->getJson(route('api.checklists.index'))
            ->assertForbidden();
    }

    public function test_api_checklists_returns_restrooms_split_by_gender_and_reflects_switches(): void
    {
        $branch = 'Pasong Tamo';
        BranchRestroom::ensureDefaultsForBranch($branch);

        $inspector = User::factory()->create([
            'user_type' => User::ROLE_5S_UTILITIES,
            'branch' => $branch,
        ]);

        // Default: Customer Area Restroom (Male, Female, PWD) + Office Restroom (Male, Female)
        $response = $this->actingAs($inspector)->getJson('/api/checklists');
        $response->assertOk();

        $slugs = collect($response->json('checklists'))->pluck('slug')->all();

        // All restroom slugs should follow restroom-{id}-{gender}
        $customerRestroom = BranchRestroom::query()->where('branch', $branch)->where('area_type', 'customer')->firstOrFail();
        $officeRestroom = BranchRestroom::query()->where('branch', $branch)->where('area_type', 'office')->firstOrFail();

        $this->assertContains("restroom-{$customerRestroom->id}-male", $slugs);
        $this->assertContains("restroom-{$customerRestroom->id}-female", $slugs);
        $this->assertContains("restroom-{$customerRestroom->id}-pwd", $slugs);

        $this->assertContains("restroom-{$officeRestroom->id}-male", $slugs);
        $this->assertContains("restroom-{$officeRestroom->id}-female", $slugs);
        $this->assertNotContains("restroom-{$officeRestroom->id}-pwd", $slugs); // Office never has PWD

        // Disable male switch on customer restroom
        $customerRestroom->update(['has_male' => false]);

        $response2 = $this->actingAs($inspector)->getJson('/api/checklists');
        $slugs2 = collect($response2->json('checklists'))->pluck('slug')->all();

        $this->assertNotContains("restroom-{$customerRestroom->id}-male", $slugs2);
        $this->assertContains("restroom-{$customerRestroom->id}-female", $slugs2);
    }

    public function test_a_branch_cannot_open_or_write_another_branch_restroom_checklist(): void
    {
        $sucat = 'Mitsubishi Sucat';
        $fairview = 'Honda Fairview';
        $sucatRestroom = BranchRestroom::ensureDefaultsForBranch($sucat)->first();
        $fairviewRestroom = BranchRestroom::ensureDefaultsForBranch($fairview)->first();
        $inspector = User::factory()->create([
            'user_type' => User::ROLE_5S_UTILITIES,
            'branch' => $sucat,
        ]);

        Sanctum::actingAs($inspector);
        $ownSlug = $sucatRestroom->slugForGender('male');
        $otherSlug = $fairviewRestroom->slugForGender('male');

        $this->getJson(route('api.checklists.show', ['template' => $ownSlug]))->assertOk();
        $this->getJson(route('api.checklists.show', ['template' => $otherSlug]))->assertForbidden();
        $this->postJson(route('api.checklists.save-draft', ['template' => $otherSlug]), [
            'date' => now()->toDateString(),
            'responses' => [],
        ])->assertForbidden();
        $this->assertDatabaseCount('checklist_submissions', 0);
    }

    public function test_restroom_checklist_submission_saves_area_and_gender_and_filters_on_dashboard(): void
    {
        $branch = 'Pasong Tamo';
        BranchRestroom::ensureDefaultsForBranch($branch);

        $inspector = User::factory()->create([
            'user_type' => User::ROLE_5S_UTILITIES,
            'branch' => $branch,
        ]);

        $customerRestroom = BranchRestroom::query()->where('branch', $branch)->where('area_type', 'customer')->firstOrFail();
        $targetSlug = "restroom-{$customerRestroom->id}-male";

        Sanctum::actingAs($inspector);

        // Fetch template
        $getTemplateResponse = $this->getJson(route('api.checklists.show', ['template' => $targetSlug]));
        $getTemplateResponse->assertOk();
        $templateData = $getTemplateResponse->json('template');
        $firstItem = $templateData['sections'][0]['items'][0];

        // Save draft checklist
        $draftResponse = $this->postJson(route('api.checklists.save-draft', ['template' => $targetSlug]), [
            'date' => now()->toDateString(),
            'branch' => $branch,
            'responses' => [
                [
                    'item_id' => $firstItem['id'],
                    'item_key' => $firstItem['key'],
                    'status' => 'yes',
                    'details' => [
                        'slots' => [
                            '08:00' => 'good',
                        ],
                    ],
                ],
            ],
        ]);

        $draftResponse->assertCreated();

        // Verify database entry
        $this->assertDatabaseHas('checklist_submissions', [
            'user_id' => $inspector->id,
            'branch' => $branch,
            'branch_restroom_id' => $customerRestroom->id,
            'restroom_area' => 'customer',
            'restroom_gender' => 'male',
        ]);

        // Check Dashboard filtering
        $gm = User::factory()->create([
            'user_type' => User::ROLE_GENERAL_MANAGER,
            'branch' => $branch,
        ]);

        // Filter for customer area and male
        $dashboardResponse = $this->actingAs($gm)->get(route('dashboard', [
            'branch' => $branch,
            'checklist' => 'utilities',
            'restroom_area' => 'customer',
            'restroom_gender' => 'male',
        ]));

        $dashboardResponse->assertOk();
        $dashboardResponse->assertSee('Customer Area Restroom');
        $dashboardResponse->assertSee('value="customer" selected', false);
        $dashboardResponse->assertSee('value="male" selected', false);

        // Filter for office area should not select customer restroom
        $dashboardResponseOffice = $this->actingAs($gm)->get(route('dashboard', [
            'branch' => $branch,
            'checklist' => 'utilities',
            'restroom_area' => 'office',
        ]));

        $dashboardResponseOffice->assertOk();
        $dashboardResponseOffice->assertSee('value="office" selected', false);
        $dashboardResponseOffice->assertDontSee('value="customer" selected', false);
    }

    public function test_restroom_notification_opens_the_exact_submitted_answers_for_gm_and_bom(): void
    {
        $branch = 'Mitsubishi Sucat';
        $restrooms = BranchRestroom::ensureDefaultsForBranch($branch);
        $restroom = $restrooms->firstWhere('area_type', 'customer');
        $inspector = User::factory()->create([
            'user_type' => User::ROLE_5S_UTILITIES,
            'branch' => $branch,
        ]);
        $gm = User::factory()->create([
            'user_type' => User::ROLE_GENERAL_MANAGER,
            'branch' => $branch,
        ]);
        $bom = User::factory()->create([
            'user_type' => User::ROLE_BRANCH_OPERATIONS_MANAGER,
            'branch' => $branch,
        ]);
        $slug = $restroom->slugForGender('female');
        $date = '2026-09-11';
        $template = ChecklistTemplate::where('slug', 'restroom')->firstOrFail();
        $items = $template->items()->where('is_active', true)->orderBy('sort_order')->get();
        $responses = $items->values()->map(fn ($item, int $index): array => [
            'item_id' => $item->id,
            'status' => $index === 0 ? 'no' : 'yes',
            'remark' => $index === 0 ? 'Needs cleaning' : null,
            'details' => [
                'slots' => ['08:00' => $index === 0 ? 'not_good' : 'good'],
                'submitted_slots' => ['08:00'],
            ],
        ])->all();

        Sanctum::actingAs($inspector);
        $submitted = $this->withHeader('X-Client-Time', '2026-09-11 08:15:00')
            ->postJson(route('api.checklists.submit', ['template' => $slug]), [
                'date' => $date,
                'branch' => $branch,
                'responses' => $responses,
            ])
            ->assertCreated();
        $submissionId = $submitted->json('submission.id');
        $this->assertDatabaseHas('checklist_submissions', [
            'id' => $submissionId,
            'branch_restroom_id' => $restroom->id,
            'restroom_area' => 'customer',
            'restroom_gender' => 'female',
        ]);

        $maleSlug = $restroom->slugForGender('male');
        $maleResponses = $items->map(fn ($item): array => [
            'item_id' => $item->id,
            'status' => 'yes',
            'details' => [
                'slots' => ['08:00' => 'good'],
                'submitted_slots' => ['08:00'],
            ],
        ])->all();
        $maleSubmissionId = $this->withHeader('X-Client-Time', '2026-09-11 08:15:00')
            ->postJson(route('api.checklists.submit', ['template' => $maleSlug]), [
                'date' => $date,
                'branch' => $branch,
                'responses' => $maleResponses,
            ])
            ->assertCreated()
            ->json('submission.id');
        $this->assertNotSame($submissionId, $maleSubmissionId);
        $this->assertDatabaseHas('checklist_submissions', [
            'id' => $maleSubmissionId,
            'branch_restroom_id' => $restroom->id,
            'restroom_gender' => 'male',
        ]);

        $officeRestroom = $restrooms->firstWhere('area_type', 'office');
        $this->withHeader('X-Client-Time', '2026-09-11 08:15:00')
            ->postJson(route('api.checklists.submit', ['template' => $officeRestroom->slugForGender('male')]), [
                'date' => $date,
                'branch' => $branch,
                'responses' => $maleResponses,
            ])
            ->assertCreated();
        $admin = User::factory()->create(['user_type' => User::ROLE_ADMINISTRATOR]);
        $this->actingAs($admin)->patch(route('admin.checklist-access.update', ['dealer' => $branch]), [
            'availability' => array_fill_keys(array_keys(DealerChecklistSetting::CATEGORIES), true),
            'restrooms' => [
                $restroom->id => ['has_male' => true, 'has_female' => true, 'has_pwd' => true, 'is_active' => true],
                $officeRestroom->id => ['has_male' => false, 'has_female' => false, 'has_pwd' => false, 'is_active' => true],
            ],
        ])->assertRedirect();
        $this->assertSame([], $officeRestroom->fresh()->enabledGenders());

        $summaryQuery = [
            'tab' => 'overview',
            'form' => 'five_s',
            'five_s_area' => 'restroom',
            'branch' => $branch,
            'user_id' => $inspector->id,
            'utility_day' => $date,
        ];
        $this->actingAs($gm)->get(route('dashboard', $summaryQuery))
            ->assertOk()
            ->assertViewHas('summarySheet', fn (array $sheet): bool =>
                $sheet['cards']['restroom_type_count'] === 3
                && $sheet['cards']['total_questions'] === 360
                && $sheet['cards']['answered'] === 60
                && $sheet['cards']['count_yes'] === 59
                && $sheet['cards']['count_no'] === 1
                && $sheet['overallSummaryRow']['total'] === 360
                && $sheet['overallSummaryRow']['score'] === 59
                && $sheet['overallSummaryRow']['percent'] === round(59 / 360 * 100, 1)
                && $sheet['coverageSummaryRow']['total'] === 360
                && $sheet['coverageSummaryRow']['score'] === 59
                && array_sum(array_column($sheet['coverageRows'], 'total')) === 360
                && ! $sheet['branchRestrooms']->contains('id', $officeRestroom->id)
            );
        $this->actingAs($gm)->get(route('dashboard', $summaryQuery + ['restroom_gender' => 'female']))
            ->assertOk()
            ->assertViewHas('summarySheet', fn (array $sheet): bool =>
                $sheet['cards']['total_questions'] === 120
                && $sheet['cards']['count_yes'] === 29
                && $sheet['cards']['count_no'] === 1
                && $sheet['coverageSummaryRow']['total'] === 120
            );
        $this->actingAs($bom)->get(route('dashboard', $summaryQuery + [
            'restroom_area' => 'customer',
            'restroom_id' => $restroom->id,
        ]))
            ->assertOk()
            ->assertViewHas('summarySheet', fn (array $sheet): bool =>
                $sheet['cards']['total_questions'] === 360
                && $sheet['overallSummaryRow']['total'] === 360
                && $sheet['coverageSummaryRow']['total'] === 360
            );
        $this->actingAs($gm)->get(route('dashboard', $summaryQuery + ['utility_time' => '08:00']))
            ->assertOk()
            ->assertViewHas('summarySheet', fn (array $sheet): bool =>
                $sheet['cards']['total_questions'] === 90
                && $sheet['cards']['count_yes'] === 59
                && $sheet['cards']['count_no'] === 1
                && $sheet['overallSummaryRow']['total'] === 90
                && $sheet['coverageSummaryRow']['total'] === 90
            );
        $this->actingAs($gm)->get(route('dashboard', $summaryQuery + ['restroom_id' => $officeRestroom->id]))
            ->assertOk()
            ->assertViewHas('summarySheet', fn (array $sheet): bool =>
                $sheet['cards']['total_questions'] === 0
                && $sheet['cards']['answered'] === 0
            );

        foreach ([$gm, $bom] as $manager) {
            $notification = $manager->notifications()->get()->first(
                fn ($record): bool => $record->data['submission_id'] === $submissionId
            );
            $this->assertNotNull($notification);
            $this->assertSame('five_s_checklist_submitted', $notification->data['event']);
            $this->assertSame('Utilities 5S checklist submitted (Customer Area - Female)', $notification->data['title']);
            $this->assertStringContainsString('Customer Area - Female Utilities 5S checklist', $notification->data['message']);
            $this->assertSame($slug, $notification->data['template_slug']);
            $this->assertSame($restroom->id, $notification->data['restroom_id']);

            $redirect = $this->actingAs($manager)
                ->get(route('notifications.view-task', $notification->id))
                ->assertRedirect(route('dashboard', [
                    'tab' => 'overview',
                    'form' => 'five_s',
                    'five_s_area' => 'restroom',
                    'branch' => $branch,
                    'user_id' => $inspector->id,
                    'user_type' => User::ROLE_5S_UTILITIES,
                    'submission_id' => $submissionId,
                    'restroom_area' => 'customer',
                    'restroom_id' => $restroom->id,
                    'restroom_gender' => 'female',
                ]));
            $this->actingAs($manager)->get($redirect->headers->get('Location'))
                ->assertOk()
                ->assertViewHas('summarySheet', fn (array $sheet): bool =>
                    $sheet['selectedSubmissionId'] === $submissionId
                    && $sheet['selectedRestroomId'] === $restroom->id
                    && $sheet['selectedRestroomGender'] === 'female'
                    && $sheet['cards']['total_questions'] === 120
                    && $sheet['cards']['count_no'] === 1
                    && $sheet['cards']['count_yes'] === $items->count() - 1
                    && $sheet['overallSummaryRow']['total'] === 120
                    && $sheet['coverageSummaryRow']['total'] === 120
                );
        }

        DB::table('checklist_submissions')->where('id', $submissionId)->update([
            'branch_restroom_id' => null,
            'restroom_area' => null,
            'restroom_gender' => null,
        ]);
        $backfill = require database_path('migrations/2026_09_25_000100_backfill_restroom_submission_scope.php');
        $backfill->up();
        $this->assertDatabaseHas('checklist_submissions', [
            'id' => $submissionId,
            'branch_restroom_id' => $restroom->id,
            'restroom_area' => 'customer',
            'restroom_gender' => 'female',
        ]);

        $oldNotification = $gm->notifications()->get()->first(
            fn ($record): bool => $record->data['submission_id'] === $submissionId
        );
        $legacyData = $oldNotification->data;
        unset($legacyData['standards_type'], $legacyData['five_s_area'], $legacyData['restroom_id'], $legacyData['restroom_area'], $legacyData['restroom_gender']);
        $oldNotification->update(['data' => $legacyData]);
        $this->actingAs($gm)
            ->get(route('notifications.view-task', $oldNotification->id))
            ->assertRedirect(route('dashboard', [
                'tab' => 'overview',
                'form' => 'five_s',
                'five_s_area' => 'restroom',
                'branch' => $branch,
                'user_id' => $inspector->id,
                'user_type' => User::ROLE_5S_UTILITIES,
                'submission_id' => $submissionId,
                'restroom_area' => 'customer',
                'restroom_id' => $restroom->id,
                'restroom_gender' => 'female',
            ]));
    }
}
