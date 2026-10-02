<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthenticationTest extends TestCase
{
    use RefreshDatabase;

    public function test_login_screen_can_be_rendered(): void
    {
        $response = $this->get('/login');

        $response->assertStatus(200);
        $response->assertSee('name="username"', false);
        $response->assertDontSee('type="email"', false);
    }

    public function test_users_can_authenticate_using_the_login_screen(): void
    {
        $user = User::factory()->create([
            'email' => 'BOM.MitsubishiSucat',
            'account_status' => 'active',
        ]);

        $response = $this->post('/login', [
            'username' => 'bom.mitsubishisucat',
            'password' => 'password',
        ]);

        $this->assertAuthenticated();
        $response->assertRedirect(route('dashboard', absolute: false));
    }

    public function test_users_can_not_authenticate_with_invalid_password(): void
    {
        $user = User::factory()->create();

        $this->post('/login', [
            'username' => $user->email,
            'password' => 'wrong-password',
        ]);

        $this->assertGuest();
    }

    public function test_non_active_users_cannot_authenticate(): void
    {
        foreach (['pending', 'inactive', 'rejected'] as $status) {
            $user = User::factory()->create([
                'email' => "{$status}@example.com",
                'account_status' => $status,
            ]);

            $response = $this->from('/login')->post('/login', [
                'username' => $user->email,
                'password' => 'password',
            ]);

            $response
                ->assertRedirect('/login')
                ->assertSessionHasErrors('username');
            $this->assertGuest();
        }
    }

    public function test_an_existing_web_session_is_revoked_when_the_account_becomes_inactive(): void
    {
        $user = User::factory()->create(['account_status' => 'active']);

        $this->actingAs($user);
        $user->update(['account_status' => 'inactive']);

        $this->get(route('dashboard'))
            ->assertRedirect(route('login'))
            ->assertSessionHasErrors('email');

        $this->assertGuest();
    }

    public function test_users_can_logout(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)->post('/logout');

        $this->assertGuest();
        $response->assertRedirect('/');
    }
}
