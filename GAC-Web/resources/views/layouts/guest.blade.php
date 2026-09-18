<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
    <head>
        @include('partials.browser-push-head')
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="csrf-token" content="{{ csrf_token() }}">
        <meta name="theme-color" content="#0B0F1A">

        <title>{{ config('app.name', 'Gateway Audit Compliance') }}</title>
        <link rel="icon" type="image/png" href="{{ asset('images/G-logo-no-bg.png') }}">

        <!-- Fonts -->
        <link rel="preconnect" href="https://fonts.bunny.net">
        <link href="https://fonts.bunny.net/css?family=inter:400,500,600,700,800&display=swap" rel="stylesheet" />

        <!-- Scripts -->
        @vite(['resources/css/app.css', 'resources/js/app.js'])
    </head>
    <body class="gac-site-body antialiased">
        <div class="gac-guest-shell">
            <div class="gac-guest-content">
                <a href="/" class="gac-guest-brand" aria-label="Gateway Audit Compliance home">
                    <span class="gac-brand-orb">
                        <x-application-logo />
                    </span>
                    <strong>GATEWAY</strong>
                    <small>Audit Compliance System</small>
                </a>

                <div class="gac-guest-card">
                    {{ $slot }}
                </div>
            </div>
        </div>
    </body>
</html>
