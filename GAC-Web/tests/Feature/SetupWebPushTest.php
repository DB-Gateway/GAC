<?php

namespace Tests\Feature;

use Dotenv\Dotenv;
use Illuminate\Support\Str;
use Minishlink\WebPush\VAPID;
use Tests\TestCase;

class SetupWebPushTest extends TestCase
{
    private string $temporaryEnv;

    protected function setUp(): void
    {
        parent::setUp();
        $this->temporaryEnv = sys_get_temp_dir().'/gac-webpush-test-'.Str::uuid().'.env';
        file_put_contents($this->temporaryEnv, "APP_NAME=GAC\n");
        $this->app->useEnvironmentPath(dirname($this->temporaryEnv));
        $this->app->loadEnvironmentFrom(basename($this->temporaryEnv));
    }

    protected function tearDown(): void
    {
        if (isset($this->temporaryEnv) && is_file($this->temporaryEnv)) {
            unlink($this->temporaryEnv);
        }
        parent::tearDown();
    }

    public function test_setup_generates_valid_keys_and_preserves_them_even_with_stale_config(): void
    {
        $this->artisan('webpush:setup', ['--subject' => 'mailto:admin@example.com'])->assertSuccessful();
        $first = Dotenv::parse(file_get_contents($this->temporaryEnv));
        $validated = VAPID::validate([
            'subject' => $first['WEBPUSH_SUBJECT'],
            'publicKey' => $first['WEBPUSH_PUBLIC_KEY'],
            'privateKey' => $first['WEBPUSH_PRIVATE_KEY'],
        ]);
        $this->assertNotEmpty($validated['publicKey']);
        config(['webpush.public_key' => null, 'webpush.private_key' => null]);
        $this->artisan('webpush:setup', ['--subject' => 'mailto:new-contact@example.com'])->assertSuccessful();
        $second = Dotenv::parse(file_get_contents($this->temporaryEnv));
        $this->assertSame($first['WEBPUSH_PUBLIC_KEY'], $second['WEBPUSH_PUBLIC_KEY']);
        $this->assertSame($first['WEBPUSH_PRIVATE_KEY'], $second['WEBPUSH_PRIVATE_KEY']);
        $this->assertSame('mailto:new-contact@example.com', $second['WEBPUSH_SUBJECT']);
    }

    public function test_setup_refuses_to_replace_a_partially_configured_pair(): void
    {
        $contents = "WEBPUSH_PUBLIC_KEY=existing-key\nWEBPUSH_PRIVATE_KEY=\n";
        file_put_contents($this->temporaryEnv, $contents);
        $this->artisan('webpush:setup', ['--subject' => 'mailto:admin@example.com'])->assertFailed();
        $this->assertSame($contents, file_get_contents($this->temporaryEnv));
    }

    public function test_setup_rejects_invalid_subject_without_changing_the_environment(): void
    {
        $contents = file_get_contents($this->temporaryEnv);
        $this->artisan('webpush:setup', ['--subject' => "mailto:invalid\nOTHER_KEY=value"])->assertFailed();
        $this->assertSame($contents, file_get_contents($this->temporaryEnv));
    }
}
