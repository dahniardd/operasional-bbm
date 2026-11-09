<?php
require_once __DIR__ . '/config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_response(["message" => "Method not allowed"], 405);
}

$input = get_request_input();
$username = trim($input['username'] ?? '');
$password = (string) ($input['password'] ?? '');

if ($username === '' || $password === '') {
    json_response(["message" => "Username dan password wajib diisi."], 422);
}

$stmt = $pdo->prepare("SELECT * FROM users WHERE username = ? LIMIT 1");
$stmt->execute([$username]);
$user = $stmt->fetch();

if (!$user) {
    json_response(["message" => "Username atau password salah."], 401);
}

$validPassword = password_verify($password, $user['password_hash'])
    || $password === $user['password_hash'];

if (!$validPassword) {
    json_response(["message" => "Username atau password salah."], 401);
}

if (!is_allowed_role($user)) {
    json_response(["message" => "Akun ini tidak memiliki akses ke aplikasi."], 403);
}

$tokenPayload = [
    'id' => (int) $user['id'],
    'username' => $user['username'],
    'role' => $user['role'],
    'time' => time(),
];
$token = base64_encode(json_encode($tokenPayload));

$photoUrl = null;
if (!empty($user['photo'])) {
    $baseUrl = get_base_url();
    $photoUrl = str_starts_with($user['photo'], 'http')
        ? $user['photo']
        : rtrim(dirname($baseUrl), '/\\') . '/' . ltrim($user['photo'], '/');
}

json_response([
    "message" => "Login berhasil.",
    "token" => $token,
    "user" => [
        "id" => (int) $user['id'],
        "username" => $user['username'],
        "role" => $user['role'],
        "photo_url" => $photoUrl,
    ],
]);
