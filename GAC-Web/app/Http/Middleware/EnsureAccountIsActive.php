<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class EnsureAccountIsActive
{
    /**
     * Remove stale web sessions as soon as an account is no longer active.
     */
    public function handle(Request $request, Closure $next): Response|RedirectResponse
    {
        // Always allow logout so the session is torn down cleanly (avoids 419 CSRF mismatch).
        if ($request->routeIs('logout')) {
            return $next($request);
        }

        if ($request->user() !== null && $request->user()->account_status !== 'active') {
            Auth::guard('web')->logout();

            $request->session()->invalidate();
            $request->session()->regenerateToken();

            return redirect()
                ->route('login')
                ->withErrors(['email' => 'Your account is not active. Please contact a compliance administrator.']);
        }

        return $next($request);
    }
}
