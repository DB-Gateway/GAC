<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use RuntimeException;

class DosOperationalUserSeeder extends Seeder
{
    /**
     * Stable operational identities requested for the DOS mobile workspace.
     * Passwords are intentionally absent and come from environment config only.
     *
     * @var list<array{name: string, legacy_email: string, role: string}>
     */
    private const ACCOUNTS = [
        [
            'name' => 'Sales Manager',
            'legacy_email' => 'sm@gateway.com',
            'role' => User::ROLE_SALES_MANAGER,
        ],
        [
            'name' => 'Aftersales Manager',
            'legacy_email' => 'asm@gateway.com',
            'role' => User::ROLE_AFTERSALES_MANAGER,
        ],
        [
            'name' => 'Customer Experience Service',
            'legacy_email' => 'ce@gateway.com',
            'role' => User::ROLE_CE_SERVICE,
        ],
        [
            'name' => 'Job Controller',
            'legacy_email' => 'jc@gateway.com',
            'role' => User::ROLE_JOB_CONTROLLER,
        ],
        [
            'name' => 'Parts Supervisor',
            'legacy_email' => 'parts@gateway.com',
            'role' => User::ROLE_PARTS_SUPERVISOR,
        ],
        [
            'name' => 'Workshop Supervisor',
            'legacy_email' => 'ws.sup@gateway.com',
            'role' => User::ROLE_WORKSHOP_SUPERVISOR,
        ],
    ];

    public function run(): void
    {
        $branch = trim((string) config('gac.seeded_dos_accounts.branch'));
        $initialPassword = (string) config('gac.seeded_dos_accounts.initial_password');
        $accounts = collect(self::ACCOUNTS)->map(fn (array $account): array => [
            ...$account,
            'username' => User::usernameFor($account['role'], $branch, name: $account['name']),
        ]);
        $existingUsers = User::query()->get()->filter(
            fn (User $user): bool => $accounts->contains(
                fn (array $account): bool => $user->roleCode() === $account['role']
            )
        );
        $missingAccounts = $accounts->reject(
            fn (array $account): bool => $existingUsers->contains(
                fn (User $user): bool => $user->roleCode() === $account['role']
            )
        );

        if ($missingAccounts->isNotEmpty()) {
            if (! in_array($branch, config('gac.branches', []), true)) {
                throw new RuntimeException(
                    'GAC_DOS_ACCOUNT_BRANCH must be one of the configured Gateway branches.'
                );
            }

            if (strlen($initialPassword) < 12) {
                throw new RuntimeException(
                    'Set GAC_DOS_INITIAL_PASSWORD to at least 12 characters before seeding missing DOS accounts.'
                );
            }
        }

        $created = 0;
        $reused = 0;

        foreach ($accounts as $account) {
            $user = $existingUsers->first(
                fn (User $candidate): bool => $candidate->roleCode() === $account['role']
            );

            if ($user !== null) {
                // Keep the operator's name, branch, status, and password intact.
                $user->forceFill([
                    'email' => User::usernameFor(
                        $account['role'],
                        $user->branch ?: $branch,
                        name: $user->name
                    ),
                    'user_type' => $account['role'],
                    'pic_assignment_type' => null,
                ])->save();
                $reused++;

                continue;
            }

            $user = new User;
            $user->forceFill([
                'name' => $account['name'],
                'email' => $account['username'],
                'email_verified_at' => now(),
                'branch' => $branch,
                'user_type' => $account['role'],
                'pic_assignment_type' => null,
                'account_status' => 'active',
                'password' => Hash::make($initialPassword),
            ])->save();
            $created++;
        }

        $this->command?->info(sprintf(
            'Ensured six DOS operational accounts (%d created, %d reused). Existing passwords and account state were preserved.',
            $created,
            $reused
        ));
    }
}
