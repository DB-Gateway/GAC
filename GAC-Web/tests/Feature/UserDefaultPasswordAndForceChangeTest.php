<?php

namespace Tests\Feature;

use App\Http\Controllers\UserManagementController;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class UserDefaultPasswordAndForceChangeTest extends TestCase
{
    use RefreshDatabase;

    public function test_gm_creates_user_with_preset_password_and_must_change_password_flag(): void
    {
        $admin = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
            'branch' => 'Pasong Tamo',
        ]);

        $response = $this->actingAs($admin)->post(route('users.store'), [
            'name' => 'Jane Auditor',
            'email' => 'jane.auditor@gateway.com',
            'user_type' => User::ROLE_SALES_MANAGER,
            'branch' => 'Pasong Tamo',
            'account_status' => 'active',
        ]);

        $response->assertRedirect();
        $response->assertSessionHas('status', 'User account created with the default password.');

        $user = User::where('email', 'jane.auditor@gateway.com')->first();
        $this->assertNotNull($user);
        $this->assertTrue(Hash::check(UserManagementController::PRESET_PASSWORD, $user->password));
        $this->assertTrue($user->must_change_password);
        $this->assertSame('active', $user->account_status);
        $this->assertSame(User::ROLE_SALES_MANAGER, $user->user_type);
    }

    public function test_api_login_returns_must_change_password_flag(): void
    {
        $user = User::factory()->create([
            'email' => 'newuser@gateway.com',
            'password' => Hash::make(UserManagementController::PRESET_PASSWORD),
            'must_change_password' => true,
            'account_status' => 'active',
        ]);

        $response = $this->postJson('/api/login', [
            'username' => 'newuser@gateway.com',
            'password' => UserManagementController::PRESET_PASSWORD,
        ]);

        $response->assertOk();
        $response->assertJsonPath('user.must_change_password', true);
    }

    public function test_api_password_update_clears_must_change_password_flag(): void
    {
        $user = User::factory()->create([
            'email' => 'newuser@gateway.com',
            'password' => Hash::make(UserManagementController::PRESET_PASSWORD),
            'must_change_password' => true,
            'account_status' => 'active',
        ]);

        Sanctum::actingAs($user);

        $response = $this->putJson('/api/profile/password', [
            'current_password' => UserManagementController::PRESET_PASSWORD,
            'password' => 'MyNewSecretPass123!',
            'password_confirmation' => 'MyNewSecretPass123!',
        ]);

        $response->assertOk();
        $response->assertJsonPath('user.must_change_password', false);

        $freshUser = $user->fresh();
        $this->assertFalse($freshUser->must_change_password);
        $this->assertTrue(Hash::check('MyNewSecretPass123!', $freshUser->password));
    }

    public function test_gm_can_reset_user_password_to_default_and_rearm_must_change_flag(): void
    {
        $admin = User::factory()->create([
            'user_type' => User::ROLE_ADMINISTRATOR,
            'account_status' => 'active',
        ]);

        $user = User::factory()->create([
            'password' => Hash::make('CustomPass123!'),
            'must_change_password' => false,
            'account_status' => 'active',
        ]);

        $response = $this->actingAs($admin)->post(route('users.password.reset', $user));

        $response->assertRedirect();
        $response->assertSessionHas('status', 'Password reset to the default. The user will be asked to change it on next login.');

        $freshUser = $user->fresh();
        $this->assertTrue(Hash::check(UserManagementController::PRESET_PASSWORD, $freshUser->password));
        $this->assertTrue($freshUser->must_change_password);
    }
}
