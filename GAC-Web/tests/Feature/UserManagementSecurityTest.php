<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class UserManagementSecurityTest extends TestCase
{
    use RefreshDatabase;

    public function test_administrator_role_variants_can_open_the_user_directory(): void
    {
        foreach (['ADMIN', 'Compliance Administrator'] as $role) {
            $manager = User::factory()->create([
                'user_type' => $role,
                'account_status' => 'active',
            ]);

            $this->actingAs($manager)
                ->get(route('users.index'))
                ->assertOk()
                ->assertSee('User Management');
        }
    }

    public function test_non_managers_cannot_view_or_mutate_the_user_directory(): void
    {
        $pic = User::factory()->create([
            'user_type' => 'PIC',
            'account_status' => 'active',
        ]);
        $target = User::factory()->create(['account_status' => 'active']);
        $originalPassword = $target->password;

        $this->actingAs($pic)->get(route('users.index'))->assertForbidden();
        $this->actingAs($pic)->patch(route('users.status', $target), [
            'account_status' => 'inactive',
        ])->assertForbidden();
        $this->actingAs($pic)->patch(route('users.password.update', $target), [
            'password' => 'Unauthorized-password-123!',
            'password_confirmation' => 'Unauthorized-password-123!',
        ])->assertForbidden();

        $this->assertSame('active', $target->fresh()->account_status);
        $this->assertSame($originalPassword, $target->fresh()->password);
    }

    public function test_non_manager_navigation_hides_user_management_but_keeps_reports(): void
    {
        $pic = User::factory()->create([
            'user_type' => 'PIC',
            'account_status' => 'active',
        ]);

        $this->actingAs($pic)
            ->get(route('dashboard'))
            ->assertOk()
            ->assertDontSee('User Management')
            ->assertDontSee(route('users.index'), false)
            ->assertSee('id="reportsDropdown"', false)
            ->assertSee('id="reportsMenu"', false)
            ->assertSee('data-report-view="analytics"', false)
            ->assertSee(route('dashboard', ['tab' => 'reports']), false)
            ->assertDontSee('data-report-view="user-usages"', false);
    }

    public function test_paginated_user_directory_uses_scoped_table_pagination_markup(): void
    {
        $administrator = $this->administrator();
        User::factory()->count(20)->create();

        $response = $this->actingAs($administrator)->get(route('users.index'));

        $response
            ->assertOk()
            ->assertSeeInOrder([
                'class="table-pagination"',
                'aria-label="Pagination Navigation"',
            ], false)
            ->assertSee('class="w-5 h-5"', false);

        $theme = file_get_contents(public_path('css/gateway-theme.css'));
        $this->assertIsString($theme);
        $this->assertSame(1, preg_match(
            '/\.gateway-dashboard\s+\.table-pagination\s+svg\s*\{(?<rules>[^}]*)\}/',
            $theme,
            $matches
        ));
        $this->assertMatchesRegularExpression('/\bwidth:\s*16px\s*;/', $matches['rules']);
        $this->assertMatchesRegularExpression('/\bheight:\s*16px\s*;/', $matches['rules']);
    }

    public function test_status_endpoint_revokes_personal_access_tokens(): void
    {
        $administrator = $this->administrator();
        $target = User::factory()->create(['account_status' => 'active']);
        $tokenId = $target->createToken('mobile')->accessToken->id;

        $this->actingAs($administrator)
            ->patch(route('users.status', $target), ['account_status' => 'inactive'])
            ->assertRedirect();

        $this->assertDatabaseMissing('personal_access_tokens', ['id' => $tokenId]);
    }

    public function test_full_update_accepts_a_branch_from_mariadb_and_cannot_bypass_status_token_revocation(): void
    {
        $administrator = $this->administrator();
        $target = User::factory()->create([
            'name' => 'Gateway PIC',
            'email' => 'gateway-pic@example.com',
            'branch' => 'HONDA MAKATI',
            'user_type' => 'PIC',
            'account_status' => 'active',
        ]);
        $tokenId = $target->createToken('mobile')->accessToken->id;

        $this->actingAs($administrator)
            ->patch(route('users.update', $target), [
                'name' => $target->name,
                'email' => $target->email,
                'branch' => $target->branch,
                'user_type' => $target->user_type,
                'account_status' => 'rejected',
                'password' => '',
                'password_confirmation' => '',
            ])
            ->assertRedirect();

        $this->assertSame('rejected', $target->fresh()->account_status);
        $this->assertDatabaseMissing('personal_access_tokens', ['id' => $tokenId]);
    }

    public function test_administrator_cannot_deactivate_self_through_either_update_endpoint(): void
    {
        $administrator = $this->administrator();

        $this->actingAs($administrator)
            ->patch(route('users.status', $administrator), ['account_status' => 'inactive'])
            ->assertStatus(422);

        $this->actingAs($administrator)
            ->patch(route('users.update', $administrator), [
                'name' => $administrator->name,
                'email' => $administrator->email,
                'branch' => $administrator->branch,
                'user_type' => $administrator->user_type,
                'account_status' => 'inactive',
                'password' => '',
                'password_confirmation' => '',
            ])
            ->assertStatus(422);

        $this->assertSame('active', $administrator->fresh()->account_status);
    }

    public function test_database_seeder_does_not_create_a_predictable_demo_account(): void
    {
        $this->seed();

        $this->assertDatabaseMissing('users', ['email' => 'test@example.com']);
    }

    public function test_administrator_can_change_a_users_password(): void
    {
        $administrator = $this->administrator();
        $target = User::factory()->create(['branch' => 'HONDA MAKATI']);
        $oldRememberToken = $target->remember_token;
        $tokenId = $target->createToken('mobile')->accessToken->id;

        $this->actingAs($administrator)
            ->from(route('users.index'))
            ->patch(route('users.password.update', $target), [
                '_editing_user_id' => (string) $target->id,
                'password' => 'Updated-password-123!',
                'password_confirmation' => 'Updated-password-123!',
            ])
            ->assertRedirect(route('users.index'))
            ->assertSessionHasNoErrors()
            ->assertSessionHas('status', 'User password updated.');

        $this->assertTrue(Hash::check('Updated-password-123!', $target->fresh()->password));
        $this->assertFalse(Hash::check('password', $target->fresh()->password));
        $this->assertNotSame($oldRememberToken, $target->fresh()->remember_token);
        $this->assertDatabaseMissing('personal_access_tokens', ['id' => $tokenId]);

        $this->get(route('users.index'))
            ->assertOk()
            ->assertSee('id="userSuccessDialog"', false)
            ->assertSee('Password changed successfully')
            ->assertSee('form method="dialog"', false);

        $this->get(route('users.index'))
            ->assertOk()
            ->assertDontSee('id="userSuccessDialog"', false);

        $this->post(route('logout'));
        $this->post(route('login'), [
            'email' => $target->email,
            'password' => 'Updated-password-123!',
        ])->assertSessionHasNoErrors();
        $this->assertAuthenticatedAs($target);
    }

    public function test_account_details_endpoint_cannot_bypass_the_password_change_safeguards(): void
    {
        $target = User::factory()->create();
        $originalHash = $target->password;

        $this->actingAs($this->administrator())
            ->from(route('users.index'))
            ->patch(route('users.update', $target), [
                'name' => $target->name,
                'email' => $target->email,
                'branch' => $target->branch,
                'user_type' => $target->user_type,
                'pic_assignment_type' => $target->picAssignmentType(),
                'account_status' => $target->account_status,
                'password' => 'Bypass-password-123!',
                'password_confirmation' => 'Bypass-password-123!',
            ])
            ->assertRedirect(route('users.index'))
            ->assertSessionHasErrors('password');

        $this->assertSame($originalHash, $target->fresh()->password);
    }

    public function test_blank_password_is_rejected_and_keeps_the_existing_password(): void
    {
        $target = User::factory()->create();
        $originalHash = $target->password;

        $this->actingAs($this->administrator())
            ->from(route('users.index'))
            ->patch(route('users.password.update', $target), [
                '_editing_user_id' => (string) $target->id,
                'password' => '',
                'password_confirmation' => '',
            ])
            ->assertRedirect(route('users.index'))
            ->assertSessionHasErrors('password');

        $this->assertSame($originalHash, $target->fresh()->password);
    }

    public function test_user_forms_have_password_visibility_controls_and_a_clickable_edit_cursor(): void
    {
        $administrator = $this->administrator();

        $this->actingAs($administrator)
            ->get(route('users.index'))
            ->assertOk()
            ->assertDontSee('id="userSuccessDialog"', false)
            ->assertSee('action="'.route('users.password.update', $administrator).'" data-password-form', false)
            ->assertSee('type="button" data-password-toggle aria-controls="edit-password-'.$administrator->id.'"', false)
            ->assertSee('type="button" data-password-toggle aria-controls="edit-password-confirmation-'.$administrator->id.'"', false)
            ->assertSee('type="button" data-password-toggle aria-controls="userPasswordInput"', false)
            ->assertSee('type="button" data-password-toggle aria-controls="userPasswordConfirmationInput"', false)
            ->assertSee('aria-label="Show new password" aria-pressed="false"', false);

        $this->assertMatchesRegularExpression(
            '/\.gateway-page-users\s+summary\.button\s*\{[^}]*cursor:\s*pointer\s*;/',
            file_get_contents(public_path('css/users-des.css'))
        );
    }

    public function test_invalid_password_keeps_the_edit_form_open_without_repopulating_passwords(): void
    {
        $target = User::factory()->create();
        $originalHash = $target->password;

        foreach ([
            ['short', 'short'],
            ['Updated-password-123!', 'Different-password-123!'],
            ['Updated-password-123!', ''],
        ] as [$password, $confirmation]) {
            $this->actingAs($this->administrator())
                ->from(route('users.index'))
                ->patch(route('users.password.update', $target), [
                    '_editing_user_id' => (string) $target->id,
                    'password' => $password,
                    'password_confirmation' => $confirmation,
                ])
                ->assertRedirect(route('users.index'))
                ->assertSessionHasErrors('password');

            $this->assertSame($originalHash, $target->fresh()->password);
            $this->assertArrayNotHasKey('password', session()->getOldInput());
            $this->assertArrayNotHasKey('password_confirmation', session()->getOldInput());

            $this->get(route('users.index'))
                ->assertOk()
                ->assertDontSee('id="userSuccessDialog"', false)
                ->assertSee('id="edit-user-'.$target->id.'" open', false)
                ->assertSee('id="edit-password-error-'.$target->id.'"', false)
                ->assertDontSee('value="'.$password.'"', false);
        }
    }

    private function administrator(): User
    {
        return User::factory()->create([
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);
    }
}
