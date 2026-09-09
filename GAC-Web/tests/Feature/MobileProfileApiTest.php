<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class MobileProfileApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_profile_endpoints_require_a_sanctum_token(): void
    {
        $this->getJson(route('api.profile.show'))->assertUnauthorized();
        $this->patchJson(route('api.profile.update'), [])->assertUnauthorized();
        $this->putJson(route('api.profile.password.update'), [])->assertUnauthorized();
        $this->postJson(route('api.profile.avatar.update'), [])->assertUnauthorized();
        $this->deleteJson(route('api.profile.avatar.destroy'))->assertUnauthorized();
    }

    public function test_current_profile_returns_the_authenticated_user_payload(): void
    {
        $user = User::factory()->create([
            'name' => 'Gateway PIC',
            'email' => 'pic@example.com',
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_PERSON_IN_CHARGE,
            'pic_assignment_type' => User::PIC_ASSIGNMENT_UTILITIES,
        ]);
        Sanctum::actingAs($user);

        $this->getJson(route('api.profile.show'))
            ->assertOk()
            ->assertJsonPath('user.id', $user->id)
            ->assertJsonPath('user.name', 'Gateway PIC')
            ->assertJsonPath('user.email', 'pic@example.com')
            ->assertJsonPath('user.branch', 'Pasong Tamo')
            ->assertJsonPath('user.user_type', User::ROLE_PERSON_IN_CHARGE)
            ->assertJsonPath('user.role_label', 'Person In Charge')
            ->assertJsonPath('user.pic_assignment_type', User::PIC_ASSIGNMENT_UTILITIES)
            ->assertJsonPath('user.pic_assignment_label', 'Utilities')
            ->assertJsonPath('user.account_status', 'active')
            ->assertJsonPath('user.avatar_url', null);
    }

    public function test_user_can_update_name_and_email_but_not_managed_account_fields(): void
    {
        $user = User::factory()->create([
            'branch' => 'Pasong Tamo',
            'user_type' => User::ROLE_PERSON_IN_CHARGE,
            'pic_assignment_type' => User::PIC_ASSIGNMENT_UTILITIES,
            'account_status' => 'active',
        ]);
        Sanctum::actingAs($user);

        $this->patchJson(route('api.profile.update'), [
            'name' => '  Updated PIC  ',
            'email' => '  UPDATED.PIC@EXAMPLE.COM ',
            'branch' => 'Cebu',
            'user_type' => User::ROLE_ADMINISTRATOR,
            'pic_assignment_type' => User::PIC_ASSIGNMENT_SALES_SERVICE,
            'account_status' => 'rejected',
        ])
            ->assertOk()
            ->assertJsonPath('message', 'Profile updated successfully.')
            ->assertJsonPath('user.name', 'Updated PIC')
            ->assertJsonPath('user.email', 'updated.pic@example.com')
            ->assertJsonPath('user.branch', 'Pasong Tamo')
            ->assertJsonPath('user.user_type', User::ROLE_PERSON_IN_CHARGE)
            ->assertJsonPath('user.pic_assignment_type', User::PIC_ASSIGNMENT_UTILITIES)
            ->assertJsonPath('user.account_status', 'active');

        $user->refresh();

        $this->assertSame('Updated PIC', $user->name);
        $this->assertSame('updated.pic@example.com', $user->email);
        $this->assertSame('Pasong Tamo', $user->branch);
        $this->assertSame(User::ROLE_PERSON_IN_CHARGE, $user->user_type);
        $this->assertSame(User::PIC_ASSIGNMENT_UTILITIES, $user->pic_assignment_type);
        $this->assertSame('active', $user->account_status);
        $this->assertNull($user->email_verified_at);
    }

    public function test_profile_update_validates_unique_email_and_preserves_verification_when_unchanged(): void
    {
        $user = User::factory()->create();
        $other = User::factory()->create();
        Sanctum::actingAs($user);

        $this->patchJson(route('api.profile.update'), [
            'name' => 'Renamed User',
            'email' => $user->email,
        ])->assertOk();

        $this->assertNotNull($user->refresh()->email_verified_at);

        $this->patchJson(route('api.profile.update'), [
            'email' => $other->email,
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('email');

        $this->assertSame($user->email, $user->refresh()->email);
    }

    public function test_password_change_requires_the_current_password_and_confirmation(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->putJson(route('api.profile.password.update'), [
            'current_password' => 'incorrect-password',
            'password' => 'Updated-password-123!',
            'password_confirmation' => 'Updated-password-123!',
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('current_password');

        $this->assertTrue(Hash::check('password', $user->refresh()->password));

        $this->putJson(route('api.profile.password.update'), [
            'current_password' => 'password',
            'password' => 'Updated-password-123!',
            'password_confirmation' => 'Updated-password-123!',
        ])
            ->assertOk()
            ->assertJsonPath('message', 'Password updated successfully.');

        $this->assertTrue(Hash::check('Updated-password-123!', $user->refresh()->password));
    }

    public function test_user_can_upload_replace_and_remove_a_profile_photo(): void
    {
        Storage::fake('public');

        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $firstResponse = $this->post(
            route('api.profile.avatar.update'),
            ['avatar' => $this->fakePng('first-avatar.png')],
            ['Accept' => 'application/json']
        );

        $firstResponse
            ->assertOk()
            ->assertJsonPath('message', 'Profile photo updated successfully.');

        $firstPath = $user->refresh()->avatar_path;
        $this->assertNotNull($firstPath);
        Storage::disk('public')->assertExists($firstPath);
        $firstResponse->assertJsonPath(
            'user.avatar_url',
            Storage::disk('public')->url($firstPath)
        );

        $secondResponse = $this->post(
            route('api.profile.avatar.update'),
            ['avatar' => $this->fakePng('second-avatar.png')],
            ['Accept' => 'application/json']
        );

        $secondResponse->assertOk();

        $secondPath = $user->refresh()->avatar_path;
        $this->assertNotNull($secondPath);
        $this->assertNotSame($firstPath, $secondPath);
        Storage::disk('public')->assertMissing($firstPath);
        Storage::disk('public')->assertExists($secondPath);

        $this->deleteJson(route('api.profile.avatar.destroy'))
            ->assertOk()
            ->assertJsonPath('message', 'Profile photo removed successfully.')
            ->assertJsonPath('user.avatar_url', null);

        $this->assertNull($user->refresh()->avatar_path);
        Storage::disk('public')->assertMissing($secondPath);
    }

    public function test_invalid_profile_photo_is_rejected_without_removing_the_existing_photo(): void
    {
        Storage::fake('public');

        $user = User::factory()->create(['avatar_path' => 'avatars/existing.png']);
        Storage::disk('public')->put($user->avatar_path, 'existing image');
        Sanctum::actingAs($user);

        $this->post(
            route('api.profile.avatar.update'),
            ['avatar' => UploadedFile::fake()->create('avatar.txt', 5, 'text/plain')],
            ['Accept' => 'application/json']
        )
            ->assertUnprocessable()
            ->assertJsonValidationErrors('avatar');

        $this->assertSame('avatars/existing.png', $user->refresh()->avatar_path);
        Storage::disk('public')->assertExists('avatars/existing.png');
    }

    public function test_login_and_me_payloads_include_the_public_avatar_url(): void
    {
        Storage::fake('public');

        $user = User::factory()->create([
            'email' => 'avatar.pic@example.com',
            'avatar_path' => 'avatars/123/profile.png',
        ]);
        $expectedUrl = Storage::disk('public')->url($user->avatar_path);

        $login = $this->postJson('/api/login', [
            'email' => 'avatar.pic@example.com',
            'password' => 'password',
            'device_name' => 'profile-api-test',
        ])
            ->assertOk()
            ->assertJsonPath('user.avatar_url', $expectedUrl);

        $this->withToken($login->json('token'))
            ->getJson('/api/me')
            ->assertOk()
            ->assertJsonPath('user.avatar_url', $expectedUrl);
    }

    private function fakePng(string $name): UploadedFile
    {
        return UploadedFile::fake()->createWithContent(
            $name,
            base64_decode(
                'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42AAAAAASUVORK5CYII=',
                true
            )
        );
    }
}
