<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureUserCanManageUsers
{
    public function handle(Request $request, Closure $next): Response
    {
        abort_unless(
            $request->user()?->hasAdministrativeAccess() === true,
            403,
            'Only a compliance administrator can manage user accounts.'
        );

        return $next($request);
    }
}
