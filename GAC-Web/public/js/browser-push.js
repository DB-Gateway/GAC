(() => {
    const configElement = document.getElementById('browserPushConfig');
    if (!configElement || window.__gacBrowserPushInitialized) return;
    window.__gacBrowserPushInitialized = true;
    const config = JSON.parse(configElement.textContent);
    const prompt = document.getElementById('browserPushPrompt');
    const enableButtons = [...document.querySelectorAll('[data-push-enable]')];
    const disableButtons = [...document.querySelectorAll('[data-push-disable]')];
    const statusLabels = [...document.querySelectorAll('[data-push-status]')];
    const storageKey = `gac-push:${config.workerUrl}:${config.userId}`;
    let registrationPromise;
    let busy = false;
    let enabled = false;
    const braveBrowser = Promise.resolve()
        .then(() => navigator.brave?.isBrave?.())
        .then((value) => value === true)
        .catch(() => false);

    const readPreference = () => {
        try { return JSON.parse(localStorage.getItem(storageKey) || '{}'); } catch { return {}; }
    };
    const savePreference = (value) => {
        try { localStorage.setItem(storageKey, JSON.stringify(value)); } catch { /* Private browsing may block storage. */ }
    };
    const getStatusLabels = () => {
        const live = document.querySelectorAll('[data-push-status]');
        return live.length ? [...live] : statusLabels;
    };
    const getEnableButtons = () => {
        const live = document.querySelectorAll('[data-push-enable]');
        return live.length ? [...live] : enableButtons;
    };
    const getDisableButtons = () => {
        const live = document.querySelectorAll('[data-push-disable]');
        return live.length ? [...live] : disableButtons;
    };
    const setStatus = (message) => getStatusLabels().forEach((label) => { label.textContent = message; });
    const setFeedback = (message) => {
        setStatus(message);
        const feedback = prompt?.querySelector?.('[data-push-feedback]');
        if (feedback) feedback.textContent = message;
    };
    const setBusy = (value) => {
        busy = value;
        [...getEnableButtons(), ...getDisableButtons()].forEach((button) => { button.disabled = value; });
    };
    const setEnabled = (value) => {
        enabled = value;
        getEnableButtons().forEach((button) => { button.hidden = value; });
        getDisableButtons().forEach((button) => { button.hidden = !value; });
        setStatus(value ? 'Notifications are on for this account on this device.' : 'Turn on notifications for this account on this device.');
        if (value && prompt) prompt.hidden = true;
    };
    const request = async (url, method, body) => {
        const response = await fetch(url, {
            method, credentials: 'same-origin', cache: 'no-store',
            headers: {
                Accept: 'application/json', 'Content-Type': 'application/json',
                'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.content || '',
                'X-GAC-Account': config.userId,
            },
            body: JSON.stringify(body),
        });
        if (!response.ok || response.redirected) {
            throw new Error(response.status === 401 || response.status === 409 || response.status === 419 || response.redirected
                ? 'Please reload the page and sign in again.'
                : 'Could not save notification settings. Please try again.');
        }
    };
    const registration = () => {
        if (!registrationPromise) {
            registrationPromise = navigator.serviceWorker.register(config.workerUrl, { updateViaCache: 'none' })
                .then(async (result) => {
                    // An active worker can still be activating on the first visit.
                    if (result.active?.state === 'activated') return result;
                    await new Promise((resolve, reject) => {
                        const worker = result.active || result.installing || result.waiting;
                        if (!worker) return reject(new Error('Please reload and try enabling notifications again.'));
                        const finish = (error) => {
                            clearTimeout(timeout);
                            worker.removeEventListener('statechange', checkState);
                            if (error) reject(error); else resolve();
                        };
                        const checkState = () => {
                            if (worker.state === 'activated') finish();
                            if (worker.state === 'redundant') finish(new Error('Notification setup failed. Please reload.'));
                        };
                        const timeout = setTimeout(() => finish(new Error('Notification setup timed out. Please try again.')), 15000);
                        worker.addEventListener('statechange', checkState);
                        checkState();
                    });
                    return result;
                }).catch((error) => { registrationPromise = null; throw error; });
        }
        return registrationPromise;
    };
    const applicationKey = () => {
        const value = String(config.publicKey || '').trim().replace(/-/g, '+').replace(/_/g, '/');
        let key;
        try { key = Uint8Array.from(atob(value + '='.repeat((4 - value.length % 4) % 4)), (char) => char.charCodeAt(0)); } catch { /* Report configuration errors separately from browser failures. */ }
        if (key?.length !== 65 || key[0] !== 4) {
            throw new Error('Notification setup is incomplete. Please contact your administrator.');
        }
        return key;
    };
    const subscribe = async (worker, key) => {
        for (let attempt = 0; attempt < 2; attempt++) {
            try {
                return await worker.pushManager.subscribe({ userVisibleOnly: true, applicationServerKey: key });
            } catch (cause) {
                // Retry one transient browser/provider failure. Do not erase registrations or permissions.
                const serviceFailure = cause.name === 'AbortError' || /push service (error|not available)/i.test(cause.message || '');
                if (!serviceFailure) throw cause;
                if (attempt === 0 && navigator.onLine !== false) {
                    setFeedback('Connecting to your browser’s notification service. Retrying once...');
                    await new Promise((resolve) => setTimeout(resolve, 800));
                    continue;
                }
                const error = new Error('The browser could not connect to its notification service.', { cause });
                error.code = 'push-service-unavailable';
                throw error;
            }
        }
    };
    const syncSubscription = async () => {
        const worker = await registration();
        let subscription = await worker.pushManager.getSubscription();
        const key = applicationKey();
        if (subscription?.options.applicationServerKey
            && String(new Uint8Array(subscription.options.applicationServerKey)) !== String(key)) {
            await request(config.unsubscribeUrl, 'DELETE', { endpoint: subscription.endpoint });
            await subscription.unsubscribe();
            subscription = null;
        }
        subscription ||= await subscribe(worker, key);
        await request(config.subscribeUrl, 'POST', subscription.toJSON());
        savePreference({ enabled: true });
        const feedback = prompt?.querySelector?.('[data-push-feedback]');
        if (feedback) feedback.textContent = '';
        setEnabled(true);
    };
    const showError = async (error) => {
        let message = error.message || 'Could not enable notifications. Please try again.';
        if (error.code === 'push-service-unavailable') {
            if (navigator.onLine === false) {
                message = 'You are offline. Reconnect to the internet, then click Enable notifications again.';
            } else if (await braveBrowser) {
                message = 'Brave could not register notifications. Open brave://settings/privacy and turn on “Use Google services for push messaging”. Relaunch Brave if prompted, then return here and click Enable notifications. If it is already on, check your internet or network restrictions.';
            } else {
                message = 'Your browser could not reach its push service. Check your internet connection and browser notification settings, restart the browser, then try again. Private windows or network restrictions can prevent registration.';
            }
        }
        setFeedback(message);
    };
    const explainBlocked = () => {
        getEnableButtons().forEach((button) => { button.hidden = true; });
        if (prompt) prompt.hidden = true;
        setStatus('Notifications are blocked. Allow them in your browser’s site settings, then reload this page.');
    };
    enableButtons.forEach((button) => button.addEventListener('click', async () => {
        if (busy) return;
        setBusy(true);
        try {
            // Keep the native permission request directly inside the user's click handler.
            const permission = await Notification.requestPermission();
            if (permission === 'granted') await syncSubscription();
            else if (permission === 'denied') explainBlocked();
            else setStatus('Permission was not granted. You can enable notifications whenever you are ready.');
        } catch (error) { await showError(error); }
        finally { setBusy(false); }
    }));
    disableButtons.forEach((button) => button.addEventListener('click', async () => {
        if (busy) return;
        setBusy(true);
        try {
            const worker = await registration();
            const subscription = await worker.pushManager.getSubscription();
            // Save the opt-out on the server before attempting browser cleanup.
            await request(config.unsubscribeUrl, 'DELETE', subscription ? { endpoint: subscription.endpoint } : {});
            savePreference({ enabled: false, dismissedUntil: Date.now() + 365 * 86400000 });
            setEnabled(false);
            if (subscription) await subscription.unsubscribe().catch(() => {});
        } catch (error) { await showError(error); }
        finally { setBusy(false); }
    }));
    document.querySelector('[data-push-dismiss]')?.addEventListener('click', () => {
        savePreference({ ...readPreference(), dismissedUntil: Date.now() + 7 * 86400000 });
        if (prompt) prompt.hidden = true;
    });

    const init = async () => {
        let unavailable = '';
        const ios = /iPad|iPhone|iPod/.test(navigator.userAgent)
            || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
        if (!window.isSecureContext) unavailable = 'Device notifications need a secure HTTPS connection. On this PC, localhost also works.';
        else if (ios && !window.matchMedia('(display-mode: standalone)').matches && !navigator.standalone) {
            unavailable = 'On iPhone or iPad, add GAC to your Home Screen from Safari, then open it there to enable notifications.';
        } else if (!('serviceWorker' in navigator) || !('PushManager' in window) || !('Notification' in window)) {
            unavailable = 'This browser does not support device notifications. Try a browser with Web Push support.';
        } else if (!config.configured) unavailable = 'Device notifications are not set up yet. Please contact your administrator.';
        if (unavailable) {
            [...getEnableButtons(), ...getDisableButtons()].forEach((button) => { button.hidden = true; });
            setStatus(unavailable);
            return;
        }
        if (Notification.permission === 'denied') {
            explainBlocked();
            await request(config.unsubscribeUrl, 'DELETE', {}).catch(() => {});
            return;
        }
        const preference = readPreference();
        if (Notification.permission === 'granted') {
            const worker = await registration().catch(() => null);
            const subscription = worker ? await worker.pushManager.getSubscription().catch(() => null) : null;
            if (preference.enabled || subscription) {
                setBusy(true);
                try {
                    await syncSubscription();
                } catch (error) {
                    await showError(error);
                } finally {
                    setBusy(false);
                }
                return;
            }
        }
        setEnabled(false);
        if (!preference.dismissedUntil || preference.dismissedUntil < Date.now()) {
            if (prompt) prompt.hidden = false;
        }
    };

    navigator.serviceWorker?.addEventListener('message', (event) => {
        if (event.data?.type === 'gac:notification-received') {
            window.dispatchEvent(new CustomEvent('gateway:push-received'));
        }
    });
    window.addEventListener('online', () => {
        if (enabled && readPreference().enabled && !busy) void syncSubscription().catch(showError);
    });
    window.addEventListener('storage', (event) => {
        if (event.key === storageKey && !readPreference().enabled) setEnabled(false);
    });
    void init();
})();
