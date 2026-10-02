<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('users') || ! Schema::hasColumn('users', 'user_type')) {
            return;
        }

        // ADMIN historically represented the GM. The new SYSTEM_ADMIN role is
        // deliberately separate and is provisioned by AdministratorSeeder.
        DB::table('users')
            ->whereRaw('LOWER(TRIM(user_type)) IN (?, ?, ?, ?, ?)', [
                'admin',
                'administrator',
                'compliance administrator',
                'gac administrator',
                'gateway administrator',
            ])
            ->update(['user_type' => 'GM']);
    }

    public function down(): void
    {
        if (Schema::hasTable('users') && Schema::hasColumn('users', 'user_type')) {
            DB::table('users')->where('user_type', 'GM')->update(['user_type' => 'ADMIN']);
        }
    }
};
