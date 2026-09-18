<?php

namespace Tests\Feature;

use App\Models\User;
use Database\Seeders\DosOperationalUserSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class DosOperationalUserSeederTest extends TestCase
{
    use RefreshDatabase;

    public function test_seeder_idempotently_creates_the_six_dos_accounts_without_resetting_password_or_state(): void
    {
        config()->set('gac.seeded_dos_accounts', [
            'branch' => 'Pasong Tamo',
            'initial_password' => 'Test-only-DOS-password!',
        ]);

        $this->seed(DosOperationalUserSeeder::class);

        $expectedRoles = [
            'sm@gateway.com' => User::ROLE_SALES_MANAGER,
            'asm@gateway.com' => User::ROLE_AFTERSALES_MANAGER,
            'ce@gateway.com' => User::ROLE_CE_SERVICE,
            'jc@gateway.com' => User::ROLE_JOB_CONTROLLER,
            'parts@gateway.com' => User::ROLE_PARTS_SUPERVISOR,
            'ws.sup@gateway.com' => User::ROLE_WORKSHOP_SUPERVISOR,
        ];

        $accounts = User::query()
            ->whereIn('email', array_keys($expectedRoles))
            ->get()
            ->keyBy('email');
        $this->assertCount(6, $accounts);
        $this->assertDatabaseMissing('users', ['email' => 'ws@gateway.com']);

        foreach ($expectedRoles as $email => $role) {
            $account = $accounts->get($email);
            $this->assertNotNull($account);
            $this->assertSame($role, $account->user_type);
            $this->assertSame('Pasong Tamo', $account->branch);
            $this->assertSame('active', $account->account_status);
            $this->assertTrue(Hash::check('Test-only-DOS-password!', $account->password));
            $this->assertFalse($account->hasAdministrativeAccess());
        }

        $salesManager = $accounts->get('sm@gateway.com');
        $replacementHash = Hash::make('Operator-changed-password!');
        $salesManager->forceFill([
            'name' => 'Named Sales Manager',
            'branch' => 'Makati',
            'account_status' => 'inactive',
            'password' => $replacementHash,
        ])->save();

        config()->set('gac.seeded_dos_accounts.initial_password', 'Different-seed-password!');
        $this->seed(DosOperationalUserSeeder::class);

        $salesManager->refresh();
        $this->assertSame('Named Sales Manager', $salesManager->name);
        $this->assertSame('Makati', $salesManager->branch);
        $this->assertSame('inactive', $salesManager->account_status);
        $this->assertSame($replacementHash, $salesManager->password);
        $this->assertSame(User::ROLE_SALES_MANAGER, $salesManager->user_type);
        $this->assertSame(6, User::query()->whereIn('email', array_keys($expectedRoles))->count());
    }

    public function test_missing_accounts_require_an_environment_backed_password(): void
    {
        config()->set('gac.seeded_dos_accounts', [
            'branch' => 'Pasong Tamo',
            'initial_password' => null,
        ]);

        $this->expectException(\RuntimeException::class);
        $this->expectExceptionMessage('GAC_DOS_INITIAL_PASSWORD');

        $this->seed(DosOperationalUserSeeder::class);
    }
}
