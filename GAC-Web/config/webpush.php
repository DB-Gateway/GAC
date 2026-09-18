<?php

return [
    'public_key' => env('WEBPUSH_PUBLIC_KEY'),
    'private_key' => env('WEBPUSH_PRIVATE_KEY'),
    'subject' => env('WEBPUSH_SUBJECT'),
    // Always use a worker-backed connection so submissions do not wait on push services.
    'connection' => env('WEBPUSH_QUEUE_CONNECTION', 'database'),
    'queue' => env('WEBPUSH_QUEUE', 'default'),
    'ttl' => 3600,
    // Only browser-operated push services may be contacted by the server.
    'allowed_hosts' => [
        'fcm.googleapis.com',
        'updates.push.services.mozilla.com',
        '*.push.services.mozilla.com',
        'web.push.apple.com',
        '*.notify.windows.com',
    ],
];
