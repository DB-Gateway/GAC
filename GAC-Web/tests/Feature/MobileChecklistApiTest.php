<?php

namespace Tests\Feature;

use App\Models\ChecklistTemplate;
use App\Models\User;
use Database\Seeders\ChecklistTemplateSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class MobileChecklistApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->seed(ChecklistTemplateSeeder::class);
    }

    public function test_checklist_catalog_requires_a_sanctum_token(): void
    {
        $this->getJson(route('api.checklists.index'))
            ->assertUnauthorized();
    }

    public function test_pic_receives_only_the_assigned_active_database_templates_and_items(): void
    {
        Sanctum::actingAs($this->pic());

        $this->getJson(route('api.checklists.index', ['date' => '2026-08-29']))
            ->assertOk()
            ->assertJsonPath('branch', 'Pasong Tamo')
            ->assertJsonCount(2, 'checklists')
            ->assertJsonMissing(['slug' => 'gateway-5s'])
            ->assertJsonFragment(['slug' => 'sales', 'item_count' => 44])
            ->assertJsonFragment(['slug' => 'service', 'item_count' => 33])
            ->assertJsonMissing(['slug' => 'dealer-operations-standards'])
            ->assertJsonMissing(['slug' => 'restroom']);
    }

    public function test_database_template_edits_are_returned_to_the_pic_immediately(): void
    {
        $template = ChecklistTemplate::query()
            ->where('slug', 'sales')
            ->firstOrFail();
        $item = $template->items()->where('key', 'item-1')->firstOrFail();
        $template->update(['name' => 'Updated by Compliance Admin', 'version' => 2]);
        $item->update(['prompt' => 'Updated parking-area requirement.']);

        Sanctum::actingAs($this->pic());

        $this->getJson(route('api.checklists.show', [
            'template' => $template,
            'date' => '2026-08-29',
        ]))
            ->assertOk()
            ->assertJsonPath('template.name', 'Updated by Compliance Admin')
            ->assertJsonPath('template.version', 2)
            ->assertJsonPath('template.sections.0.items.0.prompt', 'Updated parking-area requirement.');
    }

    public function test_pic_can_save_a_mobile_draft_for_the_assigned_branch(): void
    {
        $pic = $this->pic();
        $template = ChecklistTemplate::query()
            ->where('slug', 'sales')
            ->firstOrFail();
        $item = $template->items()->firstOrFail();
        Sanctum::actingAs($pic);

        $this->postJson(route('api.checklists.save-draft', $template), [
            'date' => '2026-08-29',
            'responses' => [[
                'item_id' => $item->id,
                'status' => 'yes',
            ]],
        ])
            ->assertCreated()
            ->assertJsonPath('submission.status', 'draft')
            ->assertJsonPath('submission.branch', 'Pasong Tamo')
            ->assertJsonPath("submission.responses.{$item->key}.status", 'yes');

        $this->assertDatabaseHas('checklist_submissions', [
            'user_id' => $pic->id,
            'checklist_template_id' => $template->id,
            'branch' => 'Pasong Tamo',
            'status' => 'draft',
        ]);
    }

    public function test_utilities_pic_can_upload_photo_attachment_and_save_draft_with_attachment(): void
    {
        \Illuminate\Support\Facades\Storage::fake('public');

        $utilitiesPic = User::factory()->create([
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_PERSON_IN_CHARGE,
            'pic_assignment_type' => User::PIC_ASSIGNMENT_UTILITIES,
            'account_status' => 'active',
        ]);

        $template = ChecklistTemplate::query()
            ->where('slug', 'restroom')
            ->firstOrFail();
        $item = $template->items()->firstOrFail();

        Sanctum::actingAs($utilitiesPic);

        // Upload attachment
        $file = \Illuminate\Http\UploadedFile::fake()->createWithContent(
            'restroom_issue.png',
            base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42AAAAAASUVORK5CYII=', true)
        );
        $uploadResponse = $this->post(route('api.checklists.attachments.upload', ['template' => 'utilities']), [
            'photo' => $file,
        ], ['Accept' => 'application/json'])
            ->assertCreated()
            ->assertJsonStructure(['path', 'url']);

        $path = $uploadResponse->json('path');
        \Illuminate\Support\Facades\Storage::disk('public')->assertExists($path);

        // Save draft with the attachment and remark
        $this->postJson(route('api.checklists.save-draft', ['template' => 'utilities']), [
            'date' => '2026-08-29',
            'responses' => [[
                'item_id' => $item->id,
                'item_key' => $item->key,
                'status' => 'no',
                'remark' => 'Sink faucet is leaking water',
                'attachment_path' => $path,
                'details' => [
                    'slots' => ['08:00' => 'not_good'],
                ],
            ]],
        ])
            ->assertCreated()
            ->assertJsonPath('submission.status', 'draft')
            ->assertJsonPath("submission.responses.{$item->key}.remark", 'Sink faucet is leaking water')
            ->assertJsonPath("submission.responses.{$item->key}.attachment_path", $path);

        $this->assertDatabaseHas('checklist_responses', [
            'item_key' => $item->key,
            'remark' => 'Sink faucet is leaking water',
            'attachment_path' => $path,
        ]);
    }

    public function test_utilities_cannot_record_future_time_slot_but_can_backtrack_to_earlier_hours(): void
    {
        $this->seed(ChecklistTemplateSeeder::class);
        $template = ChecklistTemplate::where('slug', 'restroom')->firstOrFail();
        $item = $template->items()->firstOrFail();

        $user = User::factory()->create([
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_PERSON_IN_CHARGE,
            'pic_assignment_type' => User::PIC_ASSIGNMENT_UTILITIES,
            'account_status' => 'active',
        ]);
        Sanctum::actingAs($user);

        $today = now()->format('Y-m-d');
        // Pick a future time slot for today (e.g. 23:00)
        $futureSlot = '23:00';

        // Attempting to record future slot is rejected
        $this->postJson(route('api.checklists.save-draft', $template), [
            'date' => $today,
            'branch' => 'Pasong Tamo',
            'responses' => [[
                'item_id' => $item->id,
                'item_key' => $item->key,
                'details' => [
                    'slots' => [$futureSlot => 'good'],
                ],
            ]],
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(["responses.0.details.slots.$futureSlot"]);

        // Backtracking to an earlier slot (08:00) on today's date succeeds
        $pastSlot = '08:00';
        $this->postJson(route('api.checklists.save-draft', $template), [
            'date' => $today,
            'branch' => 'Pasong Tamo',
            'responses' => [[
                'item_id' => $item->id,
                'item_key' => $item->key,
                'details' => [
                    'slots' => [$pastSlot => 'good'],
                ],
            ]],
        ])
            ->assertCreated()
            ->assertJsonPath("submission.responses.{$item->key}.details.slots.{$pastSlot}", 'good');
    }

    public function test_sales_and_service_requires_remark_on_no_or_na_and_supports_photo_attachment(): void
    {
        \Illuminate\Support\Facades\Storage::fake('public');

        $pic = $this->pic();
        $template = ChecklistTemplate::query()->where('slug', 'sales')->firstOrFail();
        $items = $template->items;
        Sanctum::actingAs($pic);

        // Upload a photo attachment for Sales template
        $file = \Illuminate\Http\UploadedFile::fake()->createWithContent(
            'sales_defect.png',
            base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42AAAAAASUVORK5CYII=', true)
        );
        $uploadResponse = $this->post(route('api.checklists.attachments.upload', ['template' => $template]), [
            'photo' => $file,
        ], ['Accept' => 'application/json'])
            ->assertCreated()
            ->assertJsonStructure(['path', 'url']);

        $photoPath = $uploadResponse->json('path');

        // Prepare responses where the first item is 'no' without remark
        $responses = $items->map(fn ($item, $idx) => [
            'item_id' => $item->id,
            'item_key' => $item->key,
            'status' => $idx === 0 ? 'no' : 'yes',
            'remark' => null,
        ])->all();

        // Submitting with NO and blank remark fails validation
        $this->postJson(route('api.checklists.submit', $template), [
            'date' => now()->format('Y-m-d'),
            'branch' => 'Pasong Tamo',
            'responses' => $responses,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(["responses.{$items[0]->key}.remark"]);

        // Setting status to 'na' without remark also fails validation
        $responses[0]['status'] = 'na';
        $this->postJson(route('api.checklists.submit', $template), [
            'date' => now()->format('Y-m-d'),
            'branch' => 'Pasong Tamo',
            'responses' => $responses,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(["responses.{$items[0]->key}.remark"]);

        // Providing required remark and optional photo attachment succeeds
        $responses[0]['status'] = 'no';
        $responses[0]['remark'] = 'Showroom front door glass has finger smudges';
        $responses[0]['attachment_path'] = $photoPath;

        $this->postJson(route('api.checklists.submit', $template), [
            'date' => now()->format('Y-m-d'),
            'branch' => 'Pasong Tamo',
            'responses' => $responses,
        ])
            ->assertCreated()
            ->assertJsonPath('submission.status', 'submitted')
            ->assertJsonPath("submission.responses.{$items[0]->key}.remark", 'Showroom front door glass has finger smudges')
            ->assertJsonPath("submission.responses.{$items[0]->key}.attachment_path", $photoPath);

        $this->assertDatabaseHas('checklist_responses', [
            'item_key' => $items[0]->key,
            'status' => 'no',
            'remark' => 'Showroom front door glass has finger smudges',
            'attachment_path' => $photoPath,
        ]);
    }

    private function pic(): User
    {
        return User::factory()->create([
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_PERSON_IN_CHARGE,
            'pic_assignment_type' => User::PIC_ASSIGNMENT_SALES_SERVICE,
            'account_status' => 'active',
        ]);
    }
}
