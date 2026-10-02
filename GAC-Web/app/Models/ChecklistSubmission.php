<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ChecklistSubmission extends Model
{
    use HasFactory;

    protected $fillable = [
        'checklist_template_id',
        'branch_restroom_id',
        'restroom_area',
        'restroom_gender',
        'user_id',
        'submitted_by_user_id',
        'submitted_by_name',
        'submitted_by_email',
        'submitted_by_user_type',
        'status',
        'branch',
        'scope_key',
        'audit_date',
        'template_version',
        'context',
        'template_snapshot',
        'scores',
        'submitted_at',
    ];

    protected function casts(): array
    {
        return [
            'audit_date' => 'date',
            'template_version' => 'integer',
            'context' => 'array',
            'template_snapshot' => 'array',
            'scores' => 'array',
            'submitted_at' => 'datetime',
        ];
    }

    public function template(): BelongsTo
    {
        return $this->belongsTo(ChecklistTemplate::class, 'checklist_template_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function submittedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'submitted_by_user_id');
    }

    public function responses(): HasMany
    {
        return $this->hasMany(ChecklistResponse::class)->orderBy('id');
    }

    public function reports(): HasMany
    {
        return $this->hasMany(Report::class);
    }
}
