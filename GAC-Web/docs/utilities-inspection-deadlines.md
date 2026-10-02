# Utilities inspection deadlines

The Flutter home-screen due banner and unconditional daily Utilities alarms are replaced by server-generated inbox notifications. Each enabled inspection has a one-hour window in Asia/Manila time. For an 08:00 inspection:

- 08:50: finish-and-submit reminder, if unsubmitted.
- 09:00: due-now reminder, if unsubmitted.
- 09:01: mark the missed inspection's active items NO, save its submission/report, and notify the Utilities user, GM accounts, and active BOM accounts for the same branch using the existing management routing.

The deadline minute is reserved for the final reminder. Missed inspections are processed from the following minute. Saved drafts do not count as submissions. Other inspection slots, notes, plans, and attachments are preserved. Disabled questions/slots and inactive users are skipped. Each event is recorded once per user, date, template, and slot. Later checks catch up on missed windows for the current business day; prior-day windows that close at or after midnight retain their original audit date.

Deploy both the GAC Flutter changes and GAC-systems backend changes together. Run Laravel's scheduler continuously on the backend, for example during development:

```powershell
Set-Location C:\xampp\htdocs\JR-files\GAC-systems
php artisan schedule:work
```

For a permanent Windows deployment, configure Task Scheduler to run `C:\xampp\php\php.exe artisan schedule:run` every minute with GAC-systems as its working directory. The registered `utilities:sync-inspections` command uses overlap protection. Do not rely on a browser or mobile screen being open. The mobile notification endpoint also catches up the signed-in Utilities user when polled.

No new database migration is needed. Browser push uses the existing push configuration/queue worker. Android currently retrieves inbox alerts every 15 seconds in the foreground and through WorkManager (nominally every 15 minutes) in the background. Server event times are deterministic, but background Android notification display is not exact and requires connectivity/notification permission. Exact closed-app delivery requires a remote push transport such as FCM; this change does not add that infrastructure. Local lead-time preferences still apply to other checklist roles; Utilities uses the fixed server deadlines above.

Validation:

```text
php artisan test --filter=UtilitiesInspectionDeadlineTest
php artisan schedule:list
```

Run tests against the configured isolated test database. Running the sync command outside tests creates real failed submissions and notifications for overdue users.
