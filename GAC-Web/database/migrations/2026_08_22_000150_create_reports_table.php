<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('checklist_submission_id')
                ->nullable()
                ->constrained()
                ->nullOnDelete();
            $table->foreignId('checklist_template_id')
                ->nullable()
                ->constrained()
                ->nullOnDelete();
            $table->foreignId('generated_by_user_id')
                ->nullable()
                ->constrained('users')
                ->nullOnDelete();
            $table->string('type', 50)->default('checklist_submission');
            $table->string('title');
            $table->string('status', 20)->default('ready');
            $table->json('filters')->nullable();
            $table->json('data_snapshot');
            $table->timestamp('generated_at');
            $table->timestamps();

            $table->index(['type', 'generated_at']);
            $table->index(['checklist_template_id', 'generated_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('reports');
    }
};
