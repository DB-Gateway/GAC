<?php

namespace App\Http\Middleware;

use App\Models\User;
use Closure;
use Illuminate\Http\Request;
use Laravel\Sanctum\PersonalAccessToken;
use Symfony\Component\HttpFoundation\Response;

class AuthenticateNotificationDevice
{
    public function handle(Request $request, Closure $next): Response
    {
        // This device credential deliberately outlives the interactive session.
        // It is accepted only on the inbox routes and can never edit checklists.
        $token = PersonalAccessToken::findToken($request->bearerToken() ?? '');
        $user = $token?->tokenable;
        abort_unless($token && $token->abilities === ['notifications:read']
            && (! $token->expires_at || $token->expires_at->isFuture())
            && $user instanceof User && $user->account_status === 'active', 401);

        $request->setUserResolver(fn () => $user);

        return $next($request);
    }
}
