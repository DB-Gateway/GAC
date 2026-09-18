@auth
    @once
        <aside class="browser-push-prompt" id="browserPushPrompt" aria-labelledby="browserPushTitle" hidden>
            <span class="browser-push-icon" aria-hidden="true"><i class="fas fa-bell"></i></span>
            <div class="browser-push-copy">
                <strong id="browserPushTitle">Stay updated on this device</strong>
                <p>Receive task updates and reminders, even when this tab is closed.</p>
                <p class="browser-push-feedback" data-push-feedback role="status" aria-live="polite"></p>
                <div class="browser-push-actions">
                    <button type="button" class="browser-push-enable" data-push-enable>Enable notifications</button>
                    <button type="button" class="browser-push-later" data-push-dismiss>Not now</button>
                </div>
            </div>
        </aside>

        <script id="browserPushConfig" type="application/json">{!! \Illuminate\Support\Js::encode([
            'configured' => \App\Services\WebPushService::configured(),
            'publicKey' => config('webpush.public_key'),
            'userId' => (string) auth()->id(),
            'workerUrl' => route('notifications.push.worker', [], false),
            'subscribeUrl' => route('notifications.push.store', [], false),
            'unsubscribeUrl' => route('notifications.push.destroy', [], false),
        ]) !!}</script>
        <script src="{{ asset('js/browser-push.js') }}?v={{ filemtime(public_path('js/browser-push.js')) }}" defer></script>
    @endonce
@endauth
