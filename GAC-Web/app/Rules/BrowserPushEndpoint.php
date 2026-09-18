<?php

namespace App\Rules;

use Closure;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Support\Str;

class BrowserPushEndpoint implements ValidationRule
{
    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        $parts = is_string($value) ? parse_url($value) : false;
        $host = strtolower($parts['host'] ?? '');
        $allowed = collect(config('webpush.allowed_hosts', []))
            ->contains(fn (string $pattern): bool => Str::is($pattern, $host));

        if (! $parts || ($parts['scheme'] ?? '') !== 'https' || ! $allowed
            || isset($parts['user']) || isset($parts['pass']) || isset($parts['fragment'])
            || (isset($parts['port']) && $parts['port'] !== 443)) {
            $fail('The subscription must use a supported browser push service.');
        }
    }
}
