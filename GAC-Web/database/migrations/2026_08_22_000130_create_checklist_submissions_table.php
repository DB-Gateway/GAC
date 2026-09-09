<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('checklist_submissions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('checklist_template_id')
                ->nullable()
                ->constrained()
                ->nullOnDelete();
            $table->foreignId('user_id')
                ->nullable()
                ->constrained()
                ->nullOnDelete();
            $table->foreignId('submitted_by_user_id')
                ->nullable()
                ->constrained('users')
                ->nullOnDelete();
            $table->string('status', 20)->default('draft');
            $table->string('branch')->nullable();
            $table->string('scope_key', 64);
            $table->date('audit_date');
            $table->unsignedInteger('template_version');
            $table->json('context')->nullable();
            $table->json('template_snapshot');
            $table->json('scores')->nullable();
            $table->timestamp('submitted_at')->nullable();
            $table->timestamps();

            $table->index(
                ['checklist_template_id', 'audit_date', 'scope_key', 'status'],
                'checklist_submission_lookup'
            );
            $table->index(['status', 'submitted_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('checklist_submissions');
    }
};
