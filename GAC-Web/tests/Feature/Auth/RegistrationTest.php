<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RegistrationTest extends TestCase
{
    use RefreshDatabase;

    public function test_registration_screen_can_be_rendered(): void
    {
        $response = $this->get('/register');

        $response
            ->assertStatus(200)
            ->assertSee('Pasong Tamo')
            ->assertSee('Person In Charge')
            ->assertSee('Utilities')
            ->assertSee('Sales &amp; Service', false)
            ->assertSee('Branch Operations Manager')
            ->assertSee('Compliance Administrator');
    }

    public function test_new_users_can_register(): void
    {
        $response = $this->post('/register', [
            'name' => 'Test User',
            'email' => 'test@example.com',
            'branch' => 'Pasong Tamo',
            'user_type' => 'Person In Charge',
            'pic_assignment_type' => User::PIC_ASSIGNMENT_UTILITIES,
            'password' => 'password',
            'password_confirmation' => 'password',
        ]);

        $this->assertGuest();
        $response
            ->assertRedirect(route('login'))
            ->assertSessionHas('status');

        $this->assertDatabaseHas('users', [
            'name' => 'Test User',
            'email' => 'test@example.com',
            'branch' => 'Pasong Tamo',
            'user_type' => 'PIC',
            'pic_assignment_type' => User::PIC_ASSIGNMENT_UTILITIES,
            'account_status' => 'pending',
        ]);
    }

    public function test_registration_rejects_unknown_branches_and_roles(): void
    {
        $response = $this->from('/register')->post('/register', [
            'name' => 'Untrusted User',
            'email' => 'untrusted@example.com',
            'branch' => 'Unknown Branch',
            'user_type' => 'Unknown Role',
            'password' => 'password',
            'password_confirmation' => 'password',
        ]);

        $response
            ->assertRedirect('/register')
            ->assertSessionHasErrors(['branch', 'user_type']);

        $this->assertDatabaseMissing('users', ['email' => 'untrusted@example.com']);
    }

    public function test_pic_registration_requires_an_assignment_type(): void
    {
        $this->from('/register')->post('/register', [
            'name' => 'Unassigned PIC',
            'email' => 'unassigned@example.com',
            'branch' => 'Pasong Tamo',
            'user_type' => 'Person In Charge',
            'password' => 'password',
            'password_confirmation' => 'password',
        ])
            ->assertRedirect('/register')
            ->assertSessionHasErrors('pic_assignment_type');

        $this->assertDatabaseMissing('users', ['email' => 'unassigned@example.com']);
    }
}
