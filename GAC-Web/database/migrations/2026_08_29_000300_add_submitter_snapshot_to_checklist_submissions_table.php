<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('checklist_submissions', function (Blueprint $table): void {
            $table->string('submitted_by_name')->nullable()->after('submitted_by_user_id');
            $table->string('submitted_by_email')->nullable()->after('submitted_by_name');
            $table->string('submitted_by_user_type', 100)->nullable()->after('submitted_by_email');
            $table->index(
                ['submitted_by_user_type', 'submitted_at'],
                'checklist_submission_submitter_type_time'
            );
            $table->index(
                ['user_id', 'checklist_template_id', 'audit_date', 'scope_key', 'status'],
                'checklist_submission_user_lookup'
            );
        });

        if (! Schema::hasTable('users')) {
            return;
        }

        DB::table('checklist_submissions')
            ->whereNotNull('submitted_by_user_id')
            ->whereNull('submitted_by_name')
            ->orderBy('id')
            ->chunkById(200, function ($submissions): void {
                $users = DB::table('users')
                    ->whereIn('id', $submissions->pluck('submitted_by_user_id')->filter()->unique())
                    ->get(['id', 'name', 'email', 'user_type'])
                    ->keyBy('id');

                foreach ($submissions as $submission) {
                    $user = $users->get($submission->submitted_by_user_id);

                    if (! $user) {
                        continue;
                    }

                    DB::table('checklist_submissions')
                        ->where('id', $submission->id)
                        ->update([
                            'submitted_by_name' => $user->name,
                            'submitted_by_email' => $user->email,
                            'submitted_by_user_type' => $this->roleCode($user->user_type),
                        ]);
                }
            });
    }

    public function down(): void
    {
        Schema::table('checklist_submissions', function (Blueprint $table): void {
            $table->dropIndex('checklist_submission_submitter_type_time');
            $table->dropIndex('checklist_submission_user_lookup');
            $table->dropColumn([
                'submitted_by_name',
                'submitted_by_email',
                'submitted_by_user_type',
            ]);
        });
    }

    private function roleCode(?string $role): string
    {
        return match (strtolower(trim((string) $role))) {
            'admin', 'administrator', 'compliance administrator', 'gac administrator',
            'gateway administrator', 'gm', 'general manager' => 'ADMIN',
            'bom', 'branch operations manager' => 'BOM',
            'pic', 'person in charge' => 'PIC',
            default => strtoupper(trim((string) $role)),
        };
    }
};
