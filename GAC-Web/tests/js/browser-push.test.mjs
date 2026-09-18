import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';
import vm from 'node:vm';

const pageSource = readFileSync(new URL('../../public/js/browser-push.js', import.meta.url), 'utf8');
const workerSource = readFileSync(new URL('../../public/notification-worker.js', import.meta.url), 'utf8');
const settle = () => new Promise((resolve) => setImmediate(resolve));
const element = () => ({
    hidden: false, disabled: false, textContent: '', listeners: {},
    addEventListener(event, callback) { this.listeners[event] = callback; },
});

function page({
    secure = true, permission = 'default', preference = {}, responseOk = true,
    existingSubscription = false, subscribeFailures = [], brave = false, online = true,
    activeWorker = { state: 'activated' }, publicKey, includePrompt = true,
} = {}) {
    const enable = element();
    const disable = element();
    const dismiss = element();
    const status = element();
    const feedback = element();
    const prompt = { ...element(), hidden: true, querySelector: () => feedback };
    const config = {
        configured: true, publicKey: publicKey ?? Buffer.from([4, ...Array(64).fill(97)]).toString('base64url'),
        userId: '1', workerUrl: '/notification-worker.js',
        subscribeUrl: '/notifications/push/subscription', unsubscribeUrl: '/notifications/push/subscription',
    };
    const calls = [];
    let requestsForPermission = 0;
    let subscribeCalls = 0;
    let unsubscribeCalls = 0;
    const subscription = {
        endpoint: 'https://fcm.googleapis.com/test', options: {},
        toJSON: () => ({ endpoint: 'https://fcm.googleapis.com/test', keys: { p256dh: 'test', auth: 'test' } }),
        unsubscribe: async () => { unsubscribeCalls++; return true; },
    };
    const registration = {
        active: activeWorker, pushManager: {
            getSubscription: async () => existingSubscription ? subscription : null,
            subscribe: async () => {
                subscribeCalls++;
                const failure = subscribeFailures.shift();
                if (failure) throw failure;
                existingSubscription = true;
                return subscription;
            },
        },
    };
    const browserEvents = {};
    const context = {
        window: {
            isSecureContext: secure, matchMedia: () => ({ matches: false }),
            addEventListener: (event, callback) => { browserEvents[event] = callback; },
            dispatchEvent() {},
        },
        navigator: {
            userAgent: 'Test browser', platform: 'Win32', maxTouchPoints: 0,
            onLine: online, brave: brave ? { isBrave: async () => true } : undefined,
            serviceWorker: { register: async () => registration, addEventListener() {} },
        },
        Notification: { permission, requestPermission: async () => { requestsForPermission++; return permission; } },
        document: {
            getElementById: (id) => id === 'browserPushConfig' ? { textContent: JSON.stringify(config) } : (includePrompt ? prompt : null),
            querySelectorAll: (selector) => ({
                '[data-push-enable]': [enable], '[data-push-disable]': [disable], '[data-push-status]': [status],
            })[selector] || [],
            querySelector: (selector) => selector === '[data-push-dismiss]' ? dismiss : { content: 'csrf-token' },
        },
        localStorage: {
            getItem: () => JSON.stringify(preference),
            setItem: (key, value) => { preference = JSON.parse(value); },
        },
        fetch: async (url, options) => {
            calls.push({ url, ...options });
            return { ok: responseOk, status: responseOk ? 200 : 503, redirected: false };
        },
        atob: (value) => Buffer.from(value, 'base64').toString('binary'),
        Uint8Array, setTimeout: (callback, delay) => setTimeout(callback, delay === 800 ? 0 : delay),
        clearTimeout, CustomEvent: class {},
    };
    context.window.Notification = context.Notification;
    context.window.PushManager = {};
    vm.runInNewContext(pageSource, context);
    return {
        enable, disable, dismiss, prompt, status, feedback, calls, browserEvents,
        permissionRequests: () => requestsForPermission,
        subscribes: () => subscribeCalls, unsubscribes: () => unsubscribeCalls,
        preference: () => preference,
    };
}

test('entry displays an invitation without requesting native permission automatically', async () => {
    const view = page();
    await settle();
    assert.equal(view.prompt.hidden, false);
    assert.equal(view.permissionRequests(), 0);
    assert.equal(view.calls.length, 0);
});

test('an explicit click saves the browser subscription with CSRF and account binding', async () => {
    const view = page({ permission: 'granted' });
    await view.enable.listeners.click();
    assert.equal(view.permissionRequests(), 1);
    assert.equal(view.calls[0].method, 'POST');
    assert.equal(view.calls[0].headers['X-CSRF-TOKEN'], 'csrf-token');
    assert.equal(view.calls[0].headers['X-GAC-Account'], '1');
    assert.equal(view.prompt.hidden, true);
    assert.equal(view.disable.hidden, false);
    assert.equal(view.preference().enabled, true);
});

test('returning opted-in devices resync without another permission prompt', async () => {
    const view = page({ permission: 'granted', preference: { enabled: true } });
    await settle();
    assert.equal(view.permissionRequests(), 0);
    assert.equal(view.calls.length, 1);
    assert.equal(view.disable.hidden, false);
    assert.match(view.status.textContent, /Notifications are on/);
});

test('reloading when prompt banner is missing still updates status without errors', async () => {
    const view = page({ permission: 'granted', preference: { enabled: true }, includePrompt: false });
    await settle();
    assert.equal(view.permissionRequests(), 0);
    assert.equal(view.calls.length, 1);
    assert.equal(view.disable.hidden, false);
    assert.match(view.status.textContent, /Notifications are on/);
});

test('HTTP network addresses explain HTTPS and never register a subscription', async () => {
    const view = page({ secure: false });
    await settle();
    assert.match(view.status.textContent, /HTTPS/);
    assert.equal(view.enable.hidden, true);
    assert.equal(view.prompt.hidden, true);
    assert.equal(view.calls.length, 0);
});

test('denied permission stops prompts and removes the current server subscription', async () => {
    const view = page({ permission: 'denied' });
    await settle();
    assert.equal(view.permissionRequests(), 0);
    assert.equal(view.prompt.hidden, true);
    assert.match(view.status.textContent, /blocked/);
    assert.equal(view.calls[0].method, 'DELETE');
});

test('Not now persists a dismissal', async () => {
    const view = page();
    await settle();
    view.dismiss.listeners.click();
    assert.equal(view.prompt.hidden, true);
    assert.ok(view.preference().dismissedUntil > Date.now());
    const nextVisit = page({ preference: view.preference() });
    await settle();
    assert.equal(nextVisit.prompt.hidden, true);
});

test('opting out removes the server subscription and does not reenable on reload', async () => {
    const view = page({ permission: 'granted', preference: { enabled: true } });
    await settle();
    await view.disable.listeners.click();
    assert.equal(view.calls.at(-1).method, 'DELETE');
    assert.equal(view.unsubscribes(), 1);
    assert.equal(view.preference().enabled, false);
    const nextVisit = page({ permission: 'granted', preference: view.preference() });
    await settle();
    assert.equal(nextVisit.calls.length, 0);
    assert.equal(nextVisit.disable.hidden, true);
});

test('failed subscription save never reports success', async () => {
    const view = page({ permission: 'granted', responseOk: false });
    await view.enable.listeners.click();
    assert.equal(view.disable.hidden, true);
    assert.equal(view.preference().enabled, undefined);
    assert.match(view.feedback.textContent, /try again/);
    assert.equal(view.enable.disabled, false);
});

const pushServiceError = () => Object.assign(new Error('Registration failed - push service error'), { name: 'AbortError' });

test('Brave push-service failure explains the browser setting and never reports enabled', async () => {
    const view = page({ permission: 'granted', brave: true, subscribeFailures: [pushServiceError(), pushServiceError()] });
    await view.enable.listeners.click();
    assert.equal(view.subscribes(), 2);
    assert.equal(view.calls.length, 0);
    assert.equal(view.preference().enabled, undefined);
    assert.equal(view.disable.hidden, true);
    assert.equal(view.enable.disabled, false);
    assert.match(view.feedback.textContent, /brave:\/\/settings\/privacy/);
    assert.match(view.feedback.textContent, /Use Google services for push messaging/);
    // After the user enables the browser-wide switch, the same button can finish setup.
    await view.enable.listeners.click();
    assert.equal(view.preference().enabled, true);
    assert.equal(view.disable.hidden, false);
    assert.equal(view.feedback.textContent, '');
});

test('a transient provider error retries once and successfully saves the subscription', async () => {
    const view = page({ permission: 'granted', subscribeFailures: [pushServiceError()] });
    await view.enable.listeners.click();
    assert.equal(view.subscribes(), 2);
    assert.equal(view.calls.length, 1);
    assert.equal(view.preference().enabled, true);
    assert.equal(view.feedback.textContent, '');
});

test('other browsers receive provider recovery instructions instead of Brave instructions', async () => {
    const view = page({ permission: 'granted', subscribeFailures: [pushServiceError(), pushServiceError()] });
    await view.enable.listeners.click();
    assert.match(view.feedback.textContent, /browser could not reach its push service/);
    assert.doesNotMatch(view.feedback.textContent, /Brave/);
    assert.equal(view.calls.length, 0);
});

test('offline registration fails promptly without retrying', async () => {
    const view = page({ permission: 'granted', online: false, subscribeFailures: [pushServiceError()] });
    await view.enable.listeners.click();
    assert.equal(view.subscribes(), 1);
    assert.match(view.feedback.textContent, /offline/);
    assert.equal(view.calls.length, 0);
});

test('permission errors are not retried as push-service failures', async () => {
    const denied = Object.assign(new Error('Permission denied'), { name: 'NotAllowedError' });
    const view = page({ permission: 'granted', subscribeFailures: [denied] });
    await view.enable.listeners.click();
    assert.equal(view.subscribes(), 1);
    assert.equal(view.calls.length, 0);
    assert.equal(view.preference().enabled, undefined);
});

test('subscription waits until the first service worker finishes activating', async () => {
    const listeners = new Map();
    const worker = {
        state: 'activating',
        addEventListener: (name, callback) => listeners.set(name, callback),
        removeEventListener: (name) => listeners.delete(name),
    };
    const view = page({ permission: 'granted', activeWorker: worker });
    const enabling = view.enable.listeners.click();
    await settle();
    assert.equal(view.subscribes(), 0);
    worker.state = 'activated';
    listeners.get('statechange')();
    await enabling;
    assert.equal(view.subscribes(), 1);
    assert.equal(view.preference().enabled, true);
    assert.equal(listeners.size, 0);
});

test('invalid public keys report setup errors before contacting the browser provider', async () => {
    const view = page({ permission: 'granted', publicKey: 'AQID' });
    await view.enable.listeners.click();
    assert.equal(view.subscribes(), 0);
    assert.equal(view.calls.length, 0);
    assert.match(view.feedback.textContent, /setup is incomplete/);
});

function worker() {
    const events = {};
    const notifications = [];
    const opened = [];
    const messages = [];
    const focused = [];
    const self = {
        registration: {
            scope: 'https://gac.test/app/',
            showNotification: async (title, options) => notifications.push({ title, ...options }),
        },
        clients: {
            claim: async () => {},
            matchAll: async () => [{
                url: 'https://gac.test/app/dashboard',
                postMessage: (message) => messages.push(message),
                focus: async () => focused.push('https://gac.test/app/dashboard'),
            }],
            openWindow: async (url) => opened.push(url),
        },
        skipWaiting: async () => {},
        addEventListener: (name, callback) => { events[name] = callback; },
    };
    vm.runInNewContext(workerSource, { self, URL });
    return { events, notifications, opened, messages, focused };
}

test('background pushes display once and signal open tabs to refresh', async () => {
    const view = worker();
    let work;
    view.events.push({ data: { json: () => ({ id: 'abc', title: 'Task completed', body: 'Ready to review', url: '/app/notifications/push/abc' }) }, waitUntil: (promise) => { work = promise; } });
    await work;
    assert.equal(view.notifications.length, 1);
    assert.equal(view.notifications[0].tag, 'gac-abc');
    assert.equal(view.notifications[0].data.url, 'https://gac.test/app/notifications/push/abc');
    assert.equal(view.messages[0].type, 'gac:notification-received');
});

test('malformed payloads still display a notification and unsafe click URLs stay inside GAC', async () => {
    const view = worker();
    let work;
    view.events.push({ data: { json: () => { throw new Error('bad JSON'); } }, waitUntil: (promise) => { work = promise; } });
    await work;
    assert.equal(view.notifications[0].title, 'GAC notification');
    for (const url of ['https://evil.test/', 'javascript:alert(1)', 'https://gac.test/another-app/']) {
        view.events.notificationclick({ notification: { close() {}, data: { url } }, waitUntil: (promise) => { work = promise; } });
        await work;
        assert.equal(view.focused.at(-1), 'https://gac.test/app/dashboard');
        assert.equal(view.opened.length, 0);
    }
});
