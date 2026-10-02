<?php

namespace Tests\Feature;

use App\Http\Controllers\UserManagementController;
use App\Models\ChecklistTemplate;
use App\Models\Report;
use App\Models\User;
use Database\Seeders\ChecklistTemplateSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class DatabaseBackedAdminTest extends TestCase
{
    use RefreshDatabase;

    public function test_administrator_can_create_and_update_database_users(): void
    {
        $administrator = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);

        $this->actingAs($administrator)
            ->post(route('users.store'), [
                'name' => 'Gateway PIC',
                'email' => 'pic@gateway.test',
                'branch' => 'Pasong Tamo',
                'user_type' => 'PIC',
                'pic_assignment_type' => User::PIC_ASSIGNMENT_SALES_SERVICE,
                'account_status' => 'active',
                'password' => 'password123',
                'password_confirmation' => 'password123',
            ])
            ->assertRedirect();

        $user = User::where('email', 'pic@gateway.test')->firstOrFail();
        $this->assertTrue(Hash::check(UserManagementController::PRESET_PASSWORD, $user->password));

        $this->actingAs($administrator)
            ->patch(route('users.status', $user), ['account_status' => 'inactive'])
            ->assertRedirect();

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'branch' => 'Pasong Tamo',
            'user_type' => 'PIC',
            'pic_assignment_type' => User::PIC_ASSIGNMENT_SALES_SERVICE,
            'account_status' => 'inactive',
        ]);
    }

    public function test_non_manager_cannot_create_users(): void
    {
        $this->actingAs(User::factory()->create(['user_type' => 'PIC']))
            ->post(route('users.store'), [
                'name' => 'Blocked User',
                'email' => 'blocked@gateway.test',
                'user_type' => 'PIC',
                'account_status' => 'active',
                'password' => 'password123',
                'password_confirmation' => 'password123',
            ])
            ->assertForbidden();

        $this->assertDatabaseMissing('users', ['email' => 'blocked@gateway.test']);
    }

    public function test_csv_export_uses_database_submissions_and_records_report_metadata(): void
    {
        $this->seed(ChecklistTemplateSeeder::class);
        $administrator = User::factory()->create([
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);
        $template = ChecklistTemplate::where('slug', 'restroom')->firstOrFail();
        $slots = collect($template->settings['time_slots'])
            ->pluck('key')
            ->mapWithKeys(fn (string $slot): array => [$slot => 'good'])
            ->all();
        $responses = $template->items()->get()->map(fn ($item): array => [
            'item_id' => $item->id,
            'status' => 'yes',
            'details' => ['slots' => $slots],
        ])->all();

        $this->actingAs($administrator)->postJson(route('checklists.submit', $template), [
            'date' => '2026-08-22',
            'branch' => 'Pasong Tamo',
            'responses' => $responses,
        ])->assertCreated();

        $response = $this->get(route('reports.export', [
            'template' => 'restroom',
            'status' => 'submitted',
        ]));

        $response->assertOk();
        $this->assertStringContainsString('text/csv', (string) $response->headers->get('content-type'));
        $this->assertStringContainsString('gateway-audit-report-', (string) $response->headers->get('content-disposition'));
        $this->assertDatabaseHas('reports', [
            'generated_by_user_id' => $administrator->id,
            'type' => 'csv_export',
            'status' => 'ready',
        ]);
        $this->assertSame(2, Report::count());
    }
}
