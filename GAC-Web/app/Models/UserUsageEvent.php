<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserUsageEvent extends Model
{
    use HasFactory;

    public const CHANNEL_WEB = 'web';

    public const CHANNEL_APP = 'app';

    public $timestamps = false;

    protected $fillable = [
        'user_id',
        'channel',
        'event',
        'occurred_at',
    ];

    protected function casts(): array
    {
        return [
            'occurred_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public static function recordLogin(User $user, string $channel): void
    {
        static::query()->create([
            'user_id' => $user->getKey(),
            'channel' => $channel,
            'event' => 'login',
            'occurred_at' => now(),
        ]);
    }
}
