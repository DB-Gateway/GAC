<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WebPushSubscription extends Model
{
    public const COOKIE = 'gac_push_device';

    protected $guarded = ['id'];

    protected $hidden = ['endpoint', 'public_key', 'auth_token', 'device_token_hash'];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
