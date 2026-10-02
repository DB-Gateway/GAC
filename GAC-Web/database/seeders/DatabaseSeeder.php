<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        if (filled(config('gac.seeded_admin_account.initial_password'))) {
            $this->call(AdministratorSeeder::class);
        } else {
            $this->command?->warn('System administrator not seeded: GAC_ADMIN_INITIAL_PASSWORD is not configured.');
        }

        $this->call([
            ChecklistTemplateSeeder::class,
            BranchPicSeeder::class,
            DosOperationalUserSeeder::class,
        ]);
    }
}
