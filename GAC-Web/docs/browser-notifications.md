# Browser and device notifications

Signed-in users see an **Enable notifications** invitation on supported devices. Clicking it opens the browser's permission request. Each account and device opts in separately. **Not now** hides the invitation for seven days; the notification bell always provides enable/disable controls. Blocking permission displays instructions instead of repeatedly prompting.

New database notifications (task completions, finding follow-ups, and draft reminders) queue encrypted Web Push messages for the recipient's subscribed devices. A service worker displays the device notification even when the GAC tab is closed. Clicking it opens an authenticated destination, with ownership checked on the server. Existing bell polling remains, and open pages also refresh when a push arrives. The computed monthly system-alert summaries are not emitted repeatedly as push messages.

## Server setup

1. Install dependencies: `composer install`.
2. Run `php artisan migrate`. To apply only this feature's migration to an existing development database, use `php artisan migrate --path=database/migrations/2026_09_14_000000_create_web_push_subscriptions_table.php`.
3. Generate keys once: `php artisan webpush:setup --subject=mailto:admin@your-domain.com`. Use your real contact address. Without this option, the command uses the configured mail sender. Keys are stored privately in `.env`; rerunning the command preserves them. Keep the same keys when deploying or restoring the site.
4. Serve the application over **HTTPS**, with a certificate trusted by each receiving device, and set `APP_URL` to that address. `http://localhost` and `http://127.0.0.1` work for development on the same PC. An HTTP LAN address such as `http://192.168.x.x:8000` cannot request device notification permission. A phone's localhost refers to the phone itself.
5. Keep `php artisan queue:work database --queue=default --sleep=3 --tries=3 --timeout=30` running. In production, run it under your server's process manager so it restarts after reboot. `composer run dev` already starts a queue listener when the default queue connection is `database`. Avoid starting another worker if one is already running. Use the connection/queue from `WEBPUSH_QUEUE_CONNECTION` and `WEBPUSH_QUEUE` if overridden. Push defaults to a database queue even when other jobs use `sync`.
6. After deployment, run `php artisan config:cache` and `php artisan queue:restart`. Ensure outbound HTTPS to browser push services is permitted. No Firebase account is required.

The worker handles retries for temporary delivery failures and removes subscriptions rejected as expired. Jobs skip users who are inactive, deleted devices, notifications already read, and notifications more than one hour old. Delivery depends on the browser/OS allowing background activity, connectivity, and notification settings such as Do Not Disturb; force-quitting the browser may stop delivery.

For this local XAMPP workspace, the keys and subscription migration have already been applied, and a queue worker is running for the current development session. It does not automatically restart after Windows reboots. Run the worker command above again, or configure your process manager, after a reboot. Testing on `http://127.0.0.1:8000` works on this PC; an HTTP LAN URL still needs a trusted HTTPS replacement for other devices.

## “Registration failed - push service error” in Brave

This happens while the browser subscribes with its push provider, before it saves a subscription to Laravel. Allowing notifications for the website alone is not enough if Brave's browser-wide push service is disabled.

1. Open `brave://settings/privacy` in Brave's address bar.
2. Turn on **Use Google services for push messaging**. Use Settings search if the option is not visible.
3. Relaunch Brave if it requests a restart, then reopen `http://127.0.0.1:8000`.
4. Click **Enable notifications** again. Allow the site when asked.

If that switch is already on, try a normal browser window and check that the network, VPN, or filtering software allows the browser to reach its push service. A website cannot enable Brave's browser-wide privacy setting. The app now waits for worker activation, retries a transient push-service failure once, and shows browser-specific recovery instructions if registration still fails. It only reports notifications enabled after the subscription is saved successfully; it does not replace closed-tab push delivery with polling.

See [Brave's push-messaging setting](https://support.brave.com/hc/en-us/articles/360017989132-How-do-I-change-my-Privacy-Settings).

## Phones and shared devices

- Android: enable notifications in a browser with Web Push support and allow notifications in the device's settings.
- iPhone/iPad: iOS/iPadOS 16.4 or later, add GAC to the Home Screen from Safari, open that app, sign in, and enable notifications. The site includes a web app manifest and installation icons.
- **Turn off on this device** removes that device's subscription. Explicit logout also removes the current device's server subscription; other devices remain subscribed. Signing back into the same account can restore previously granted permission. New accounts receive their own invitation.
- Notification previews contain the notification title and a shortened message; the OS may display them on the lock screen according to the user's settings.

## Verification

Run `php artisan test --filter="BrowserPushNotificationTest|SetupWebPushTest"` and `node --test tests/js/browser-push.test.mjs`. The PHP transport test encrypts/signs a real Web Push request against a mocked provider; tests never send device notifications.

For a live check, sign in as a recipient, enable notifications and select **Allow**, then close the tab. From another signed-in device, perform a task submission or send a draft reminder that normally notifies that recipient. The receiving device should show the alert; clicking it should require the recipient's login and open the relevant destination. Verify disabling the device and logging out stop future alerts.

References: [MDN Push API](https://developer.mozilla.org/en-US/docs/Web/API/Push_API), [notification permission requirements](https://developer.mozilla.org/en-US/docs/Web/API/Notifications_API/Using_the_Notifications_API), [WebKit iOS Web Push](https://webkit.org/blog/13878/web-push-for-web-apps-on-ios-and-ipados/), [PHP Web Push library](https://github.com/web-push-libs/web-push-php).
