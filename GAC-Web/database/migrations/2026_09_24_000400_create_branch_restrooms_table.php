<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('branch_restrooms', function (Blueprint $table) {
            $table->id();
            $table->string('branch')->index();
            $table->string('name');
            $table->string('area_type')->default('customer'); // 'customer' or 'office'
            $table->boolean('has_male')->default(true);
            $table->boolean('has_female')->default(true);
            $table->boolean('has_pwd')->default(false);
            $table->boolean('is_active')->default(true);
            $table->integer('sort_order')->default(0);
            $table->timestamps();
        });

        Schema::table('checklist_submissions', function (Blueprint $table) {
            $table->foreignId('branch_restroom_id')->nullable()->after('checklist_template_id')->constrained('branch_restrooms')->nullOnDelete();
            $table->string('restroom_area')->nullable()->after('branch_restroom_id')->index();
            $table->string('restroom_gender')->nullable()->after('restroom_area')->index();
        });

        // Ensure time slots for restroom template include 8 AM, 11 AM, 1 PM, 4 PM
        $templates = DB::table('checklist_templates')
            ->whereIn('slug', ['restroom', 'utilities'])
            ->get();

        foreach ($templates as $template) {
            $settings = json_decode($template->settings ?? '{}', true) ?: [];
            $settings['time_slots'] = [
                ['key' => '08:00', 'label' => '8 AM'],
                ['key' => '11:00', 'label' => '11 AM'],
                ['key' => '13:00', 'label' => '1 PM'],
                ['key' => '16:00', 'label' => '4 PM'],
            ];
            $description = 'Restroom condition and orderliness inspection at 8 AM, 11 AM, 1 PM, and 4 PM.';

            DB::table('checklist_templates')->where('id', $template->id)->update([
                'settings' => json_encode($settings, JSON_THROW_ON_ERROR),
                'description' => $description,
                'updated_at' => now(),
            ]);
        }

        // Initialize default restrooms for existing known branches
        $branches = DB::table('users')
            ->whereNotNull('branch')
            ->where('branch', '<>', '')
            ->distinct()
            ->pluck('branch')
            ->merge(config('gac.branches', []))
            ->filter(fn ($b): bool => is_string($b) && trim($b) !== '')
            ->unique(fn (string $b): string => Str::lower(trim($b)))
            ->values();

        foreach ($branches as $branch) {
            $branchName = trim($branch);
            $now = now();

            // Default Customer Area Restroom
            DB::table('branch_restrooms')->insert([
                'branch' => $branchName,
                'name' => 'Customer Area Restroom',
                'area_type' => 'customer',
                'has_male' => true,
                'has_female' => true,
                'has_pwd' => true,
                'is_active' => true,
                'sort_order' => 1,
                'created_at' => $now,
                'updated_at' => $now,
            ]);

            // Default Office Restroom (no PWD)
            DB::table('branch_restrooms')->insert([
                'branch' => $branchName,
                'name' => 'Office Restroom',
                'area_type' => 'office',
                'has_male' => true,
                'has_female' => true,
                'has_pwd' => false,
                'is_active' => true,
                'sort_order' => 2,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        }
    }

    public function down(): void
    {
        Schema::table('checklist_submissions', function (Blueprint $table) {
            $table->dropForeign(['branch_restroom_id']);
            $table->dropColumn(['branch_restroom_id', 'restroom_area', 'restroom_gender']);
        });

        Schema::dropIfExists('branch_restrooms');
    }
};
