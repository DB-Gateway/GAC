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
     * @var list<array{name: string, email: string, role: string}>
     */
    private const ACCOUNTS = [
        [
            'name' => 'Sales Manager',
            'email' => 'sm@gateway.com',
            'role' => User::ROLE_SALES_MANAGER,
        ],
        [
            'name' => 'Aftersales Manager',
            'email' => 'asm@gateway.com',
            'role' => User::ROLE_AFTERSALES_MANAGER,
        ],
        [
            'name' => 'Customer Experience Service',
            'email' => 'ce@gateway.com',
            'role' => User::ROLE_CE_SERVICE,
        ],
        [
            'name' => 'Job Controller',
            'email' => 'jc@gateway.com',
            'role' => User::ROLE_JOB_CONTROLLER,
        ],
        [
            'name' => 'Parts Supervisor',
            'email' => 'parts@gateway.com',
            'role' => User::ROLE_PARTS_SUPERVISOR,
        ],
        [
            'name' => 'Workshop Supervisor',
            'email' => 'ws.sup@gateway.com',
            'role' => User::ROLE_WORKSHOP_SUPERVISOR,
        ],
    ];

    public function run(): void
    {
        $existingByEmail = User::query()
            ->whereIn('email', array_column(self::ACCOUNTS, 'email'))
            ->get()
            ->keyBy(fn (User $user): string => strtolower(trim($user->email)));
        $missingAccounts = collect(self::ACCOUNTS)
            ->reject(fn (array $account): bool => $existingByEmail->has($account['email']));

        $branch = trim((string) config('gac.seeded_dos_accounts.branch'));
        $initialPassword = (string) config('gac.seeded_dos_accounts.initial_password');

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

        foreach (self::ACCOUNTS as $account) {
            /** @var User|null $user */
            $user = $existingByEmail->get($account['email']);

            if ($user !== null) {
                // Keep the operator's name, branch, status, and password intact.
                $user->forceFill([
                    'user_type' => $account['role'],
                    'pic_assignment_type' => null,
                ])->save();
                $reused++;

                continue;
            }

            $user = new User;
            $user->forceFill([
                'name' => $account['name'],
                'email' => $account['email'],
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
