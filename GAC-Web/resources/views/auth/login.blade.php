<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="theme-color" content="#0B0F1A">
    <title>Login - Gateway Audit Compliance</title>
    <link rel="icon" type="image/png" href="{{ asset('images/G-logo-no-bg.png') }}">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="{{ asset('css/login-des.css') }}">
</head>
<body>
    <div class="ambient-lines" aria-hidden="true">
        <span class="beam beam-red beam-red-one"></span>
        <span class="beam beam-red beam-red-two"></span>
        <span class="beam beam-red beam-red-three"></span>
        <span class="beam beam-blue beam-blue-one"></span>
        <span class="beam beam-red beam-red-four"></span>
        <span class="beam beam-red beam-red-five"></span>
    </div>

    <main class="login-shell">
        <section class="login-card" aria-labelledby="loginHeading">
            <header class="login-header">
                <a class="brand-orb" href="{{ url('/') }}" aria-label="Gateway Audit Compliance home">
                    <img src="{{ asset('images/G-logo-no-bg.png') }}" alt="Gateway">
                </a>
                <p class="brand-kicker">Gateway Audit Compliance</p>
                <h1 id="loginHeading" class="sr-only">Sign in to Gateway Audit Compliance</h1>
                <p class="login-intro">Sign in to access your compliance dashboard.</p>
            </header>

            @if (session('status'))
                <div class="alert alert-status" role="status">
                    <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M20 6 9 17l-5-5"></path></svg>
                    <span>{{ session('status') }}</span>
                </div>
            @endif

            @if ($errors->any())
                <div class="alert alert-error" id="loginErrors" role="alert">
                    <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 9v4"></path><path d="M12 17h.01"></path><path d="M10.3 3.7 2.4 17.4A2 2 0 0 0 4.1 20h15.8a2 2 0 0 0 1.7-2.6L13.7 3.7a2 2 0 0 0-3.4 0Z"></path></svg>
                    <span>{{ $errors->first() }}</span>
                </div>
            @endif

            <form method="POST" action="{{ route('login') }}" class="login-form">
                @csrf

                <div class="form-group">
                    <label class="sr-only" for="email">{{ __('Email') }}</label>
                    <div class="input-shell @error('email') has-error @enderror">
                        <svg class="field-icon" viewBox="0 0 24 24" aria-hidden="true"><path d="M20 21a8 8 0 0 0-16 0"></path><circle cx="12" cy="7" r="4"></circle></svg>
                        <input
                            id="email"
                            type="email"
                            name="email"
                            value="{{ old('email') }}"
                            required
                            autofocus
                            autocomplete="username"
                            placeholder="you@company.com"
                            @error('email') aria-invalid="true" aria-describedby="emailError" @enderror
                        >
                    </div>
                    @error('email')
                        <p class="field-error" id="emailError">{{ $message }}</p>
                    @enderror
                </div>

                <div class="form-group">
                    <label class="sr-only" for="password">{{ __('Password') }}</label>
                    <div class="input-shell @error('password') has-error @enderror">
                        <svg class="field-icon" viewBox="0 0 24 24" aria-hidden="true"><rect x="5" y="10" width="14" height="10" rx="2"></rect><path d="M8 10V7a4 4 0 0 1 8 0v3"></path></svg>
                        <input
                            id="password"
                            type="password"
                            name="password"
                            required
                            autocomplete="current-password"
                            placeholder="••••••••"
                            @error('password') aria-invalid="true" aria-describedby="passwordError" @enderror
                        >
                        <button
                            class="password-toggle"
                            id="passwordToggle"
                            type="button"
                            aria-label="Show password"
                            aria-controls="password"
                            aria-pressed="false"
                        >
                            <svg class="eye-open" viewBox="0 0 24 24" aria-hidden="true"><path d="M2 12s3.5-6 10-6 10 6 10 6-3.5 6-10 6S2 12 2 12Z"></path><circle cx="12" cy="12" r="3"></circle></svg>
                            <svg class="eye-closed" viewBox="0 0 24 24" aria-hidden="true"><path d="m3 3 18 18"></path><path d="M10.6 10.6a2 2 0 0 0 2.8 2.8"></path><path d="M9.4 5.4A10.7 10.7 0 0 1 12 5c6.5 0 10 7 10 7a17.8 17.8 0 0 1-2 2.8"></path><path d="M6.6 6.6C3.6 8.3 2 12 2 12s3.5 7 10 7a9.8 9.8 0 0 0 4.4-1"></path></svg>
                        </button>
                    </div>
                    @error('password')
                        <p class="field-error" id="passwordError">{{ $message }}</p>
                    @enderror
                </div>

                <div class="form-options">
                    <label class="remember-option" for="remember_me">
                        <input id="remember_me" type="checkbox" name="remember" @checked(old('remember'))>
                        <span>{{ __('Remember me') }}</span>
                    </label>

                    @if (Route::has('password.request'))
                        <a href="{{ route('password.request') }}">{{ __('Forgot your password?') }}</a>
                    @endif
                </div>

                <button type="submit" class="login-button">{{ __('Log in') }}</button>
            </form>

            <p class="copyright">© {{ date('Y') }} Gateway Audit Compliance. All Rights Reserved.</p>
        </section>
    </main>

    <script>
        (() => {
            const password = document.getElementById('password');
            const toggle = document.getElementById('passwordToggle');

            if (!password || !toggle) return;

            toggle.addEventListener('click', () => {
                const reveal = password.type === 'password';
                password.type = reveal ? 'text' : 'password';
                toggle.classList.toggle('is-visible', reveal);
                toggle.setAttribute('aria-pressed', String(reveal));
                toggle.setAttribute('aria-label', reveal ? 'Hide password' : 'Show password');
                password.focus({ preventScroll: true });
            });
        })();
    </script>
</body>
</html>
