<?php
require_once __DIR__ . '/config.php';

$user = require_auth($pdo);

$photoUrl = null;
if (!empty($user['photo'])) {
    $baseUrl = get_base_url();
    $photoUrl = str_starts_with($user['photo'], 'http')
        ? $user['photo']
        : rtrim(dirname($baseUrl), '/\\') . '/' . ltrim($user['photo'], '/');
}

json_response([
    "user" => [
        "id" => (int) $user['id'],
        "username" => $user['username'],
        "role" => $user['role'],
        "photo_url" => $photoUrl,
    ],
]);
