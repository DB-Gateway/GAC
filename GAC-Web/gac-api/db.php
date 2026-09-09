<?php

declare(strict_types=1);

$databaseHost = '127.0.0.1';
$databaseName = 'gac-database';
$databaseUser = 'root';
$databasePassword = '';

try {
    $pdo = new PDO(
        "mysql:host={$databaseHost};dbname={$databaseName};charset=utf8mb4",
        $databaseUser,
        $databasePassword,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]
    );
} catch (PDOException $exception) {
    header('Content-Type: application/json; charset=utf-8');
    http_response_code(500);

    echo json_encode([
        'success' => false,
        'message' => 'Unable to connect to the database.',
    ]);

    exit;
}
