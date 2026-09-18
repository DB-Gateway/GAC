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

        return $next($request);
    }
}
