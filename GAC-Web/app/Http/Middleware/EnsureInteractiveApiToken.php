<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureInteractiveApiToken
{
    public function handle(Request $request, Closure $next): Response
    {
        abort_if($request->user()?->tokenCan('notifications:read')
            && ! $request->user()?->tokenCan('*'), 403);

        $user = $request->user();
        abort_if(
            $user?->hasAssignedChecklists() === true
                && ! $user->hasAnyAvailableAssignedChecklist(),
            403,
            'Your assigned checklist is currently unavailable for your dealer. Contact your system administrator.'
        );

        return $next($request);
    }
}
