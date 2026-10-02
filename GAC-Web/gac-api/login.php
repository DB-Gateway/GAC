<?php

declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: POST, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

function respond(int $statusCode, array $payload): void
{
    http_response_code($statusCode);
    echo json_encode($payload);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respond(405, [
        'success' => false,
        'message' => 'Method not allowed.',
    ]);
}

require __DIR__ . '/db.php';

$requestBody = file_get_contents('php://input');
$requestData = json_decode($requestBody ?: '', true);

if (!is_array($requestData)) {
    respond(400, [
        'success' => false,
        'message' => 'The request must contain valid JSON.',
    ]);
}

$username = trim((string) ($requestData['username'] ?? $requestData['email'] ?? ''));
$password = (string) ($requestData['password'] ?? '');

if ($username === '' || $password === '') {
    respond(422, [
        'success' => false,
        'message' => 'Username and password are required.',
    ]);
}

$statement = $pdo->prepare(
    'SELECT id, name, email, branch, user_type, password
     FROM users
     WHERE LOWER(email) = LOWER(:username)
     LIMIT 1'
);

$statement->execute(['username' => $username]);
$user = $statement->fetch();

if (!$user || !password_verify($password, $user['password'])) {
    respond(401, [
        'success' => false,
        'message' => 'Invalid username or password.',
    ]);
}

respond(200, [
    'success' => true,
    'message' => 'Login successful.',
    'user' => [
        'id' => (int) $user['id'],
        'name' => $user['name'],
        'username' => $user['email'],
        'email' => $user['email'],
        'branch' => $user['branch'],
        'userType' => $user['user_type'],
    ],
]);
