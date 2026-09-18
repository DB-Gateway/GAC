<?php

namespace App\Console\Commands;

use Dotenv\Dotenv;
use Illuminate\Console\Command;

class SetupWebPush extends Command
{
    protected $signature = 'webpush:setup {--subject= : Contact mailto: address or public HTTPS URL}';

    protected $description = 'Create and save stable Web Push keys without displaying the private key';

    public function handle(): int
    {
        $path = app()->environmentFilePath();
        if (! is_file($path)) {
            $this->error('Create your .env file first.');

            return self::FAILURE;
        }
        $env = file_get_contents($path);
        $existing = Dotenv::parse($env);
        $publicKey = $existing['WEBPUSH_PUBLIC_KEY'] ?? config('webpush.public_key');
        $privateKey = $existing['WEBPUSH_PRIVATE_KEY'] ?? config('webpush.private_key');
        $subject = $this->option('subject') ?: ($existing['WEBPUSH_SUBJECT'] ?? null) ?: config('webpush.subject') ?: 'mailto:'.config('mail.from.address');
        if (! ((str_starts_with($subject, 'mailto:') && filter_var(substr($subject, 7), FILTER_VALIDATE_EMAIL))
            || (str_starts_with($subject, 'https://') && filter_var($subject, FILTER_VALIDATE_URL)))) {
            $this->error('Provide --subject=mailto:admin@your-domain.com or a public HTTPS URL.');

            return self::FAILURE;
        }

        $values = ['WEBPUSH_SUBJECT' => $subject];
        if (! filled($publicKey) && ! filled($privateKey)) {
            $options = ['private_key_type' => OPENSSL_KEYTYPE_EC, 'curve_name' => 'prime256v1'];
            $opensslConfig = dirname(PHP_BINARY).'/extras/ssl/openssl.cnf';
            if (is_file($opensslConfig)) {
                $options['config'] = $opensslConfig;
            }
            $key = openssl_pkey_new($options);
            if ($key === false) {
                $this->error('OpenSSL could not generate keys. Set OPENSSL_CONF to your openssl.cnf path and retry.');

                return self::FAILURE;
            }
            $ec = openssl_pkey_get_details($key)['ec'];
            $encode = fn (string $bytes): string => rtrim(strtr(base64_encode($bytes), '+/', '-_'), '=');
            $values['WEBPUSH_PUBLIC_KEY'] = $encode("\x04".str_pad($ec['x'], 32, "\0", STR_PAD_LEFT).str_pad($ec['y'], 32, "\0", STR_PAD_LEFT));
            $values['WEBPUSH_PRIVATE_KEY'] = $encode(str_pad($ec['d'], 32, "\0", STR_PAD_LEFT));
        } elseif (! filled($publicKey) || ! filled($privateKey)) {
            $this->error('Only one Web Push key is configured. Restore the matching key; existing keys will not be overwritten.');

            return self::FAILURE;
        }

        foreach ($values as $key => $value) {
            $line = $key.'="'.addcslashes($value, '\\"$').'"';
            $pattern = '/^'.preg_quote($key, '/').'=.*$/m';
            $env = preg_match($pattern, $env)
                ? preg_replace_callback($pattern, fn () => $line, $env)
                : rtrim($env).PHP_EOL.$line.PHP_EOL;
        }
        if (file_put_contents($path, $env, LOCK_EX) === false) {
            $this->error('Unable to save Web Push settings to .env.');

            return self::FAILURE;
        }
        $this->callSilent('config:clear');
        $this->info('Web Push settings saved. Existing keys were preserved.');
        $this->line('Use HTTPS (or localhost for development) and keep php artisan queue:work running.');

        return self::SUCCESS;
    }
}
