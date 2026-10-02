<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use RuntimeException;

class AdministratorSeeder extends Seeder
{
    public function run(): void
    {
        $username = trim((string) config('gac.seeded_admin_account.username', 'Admin.Gateway'));
        $initialPassword = (string) config('gac.seeded_admin_account.initial_password');

        $existing = User::query()
            ->whereRaw('LOWER(email) = ?', [strtolower($username)])
            ->first();

        if ($existing !== null) {
            $existing->forceFill([
                'user_type' => User::ROLE_ADMINISTRATOR,
                'pic_assignment_type' => null,
                'account_status' => 'active',
            ])->save();

            $this->command?->info("System administrator {$username} already exists; its password was preserved.");

            return;
        }

        if (strlen($initialPassword) < 12) {
            throw new RuntimeException(
                'Set GAC_ADMIN_INITIAL_PASSWORD to at least 12 characters before seeding the system administrator.'
            );
        }

        User::query()->create([
            'name' => config('gac.seeded_admin_account.name', 'Gateway System Administrator'),
            'email' => $username,
            'email_verified_at' => now(),
            'branch' => null,
            'user_type' => User::ROLE_ADMINISTRATOR,
            'pic_assignment_type' => null,
            'account_status' => 'active',
            'must_change_password' => true,
            'password' => Hash::make($initialPassword),
        ]);

        $this->command?->info("Created system administrator {$username}; a password change is required at first login.");
    }
}
