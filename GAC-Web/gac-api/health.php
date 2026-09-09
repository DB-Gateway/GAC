<?php

declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');

require __DIR__ . '/db.php';

$pdo->query('SELECT 1');

echo json_encode([
    'success' => true,
    'message' => 'GAC API and database are connected.',
]);
