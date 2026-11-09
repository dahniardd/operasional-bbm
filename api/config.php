<?php
// config.php - Konfigurasi API native PHP untuk aplikasi BBM
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

function env_value($names, $default = null)
{
    foreach ((array) $names as $name) {
        $value = getenv($name);

        if ($value !== false) {
            return $value;
        }
    }

    return $default;
}

function is_local_request()
{
    $host = strtolower(trim($_SERVER['HTTP_HOST'] ?? ''));

    // Host IPv6 dikirim dalam format "[::1]:port".
    if (preg_match('/^\[([^\]]+)\](?::\d+)?$/', $host, $matches)) {
        $host = $matches[1];
    } elseif (!filter_var($host, FILTER_VALIDATE_IP)) {
        $host = preg_replace('/:\d+$/', '', $host);
    }

    if ($host === '' || in_array($host, ['localhost', '127.0.0.1', '::1', '10.0.2.2'], true)) {
        return true;
    }

    if (filter_var($host, FILTER_VALIDATE_IP)) {
        return !filter_var(
            $host,
            FILTER_VALIDATE_IP,
            FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE
        );
    }

    return str_ends_with($host, '.test') || str_ends_with($host, '.local');
}

$is_local = is_local_request();

// Urutan prioritas: environment server > fallback lokal/production.
// Nama env Laravel (DB_DATABASE/DB_USERNAME/DB_PASSWORD) juga didukung.
$db_host = env_value('DB_HOST', 'localhost');
$db_port = env_value('DB_PORT', '3306');
$db_name = env_value(['DB_NAME', 'DB_DATABASE'], 'umumcsrc_operasional');
$db_user = env_value(
    ['DB_USER', 'DB_USERNAME'],
    $is_local ? 'root' : 'umumcsrc_admin'
);
$db_pass = env_value(
    ['DB_PASS', 'DB_PASSWORD'],
    $is_local ? '' : 'umumcsr_123'
);

try {
    $pdo = new PDO(
        "mysql:host={$db_host};port={$db_port};dbname={$db_name};charset=utf8mb4",
        $db_user,
        $db_pass,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]
    );
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        "status" => false,
        "message" => "Database connection failed: " . $e->getMessage(),
    ]);
    exit;
}

function json_response($data, $status_code = 200)
{
    http_response_code($status_code);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function get_json_input()
{
    $raw = file_get_contents('php://input');
    $decoded = json_decode($raw, true);

    return is_array($decoded) ? $decoded : [];
}

function get_request_input()
{
    $input = get_json_input();

    if (!empty($input)) {
        return $input;
    }

    return $_POST;
}

function get_base_url()
{
    $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? "https" : "http";
    $host = $_SERVER['HTTP_HOST'] ?? 'localhost';
    $dir = rtrim(dirname($_SERVER['SCRIPT_NAME']), '/\\');

    return "{$protocol}://{$host}{$dir}";
}

function get_authorization_header()
{
    foreach (['HTTP_AUTHORIZATION', 'REDIRECT_HTTP_AUTHORIZATION'] as $key) {
        if (!empty($_SERVER[$key])) {
            return $_SERVER[$key];
        }
    }

    $headers = [];

    if (function_exists('apache_request_headers')) {
        $headers = apache_request_headers();
    } elseif (function_exists('getallheaders')) {
        $headers = getallheaders();
    }

    foreach ($headers as $name => $value) {
        if (strcasecmp($name, 'Authorization') === 0) {
            return $value;
        }
    }

    return '';
}

/**
 * Ambil user dari token Bearer (base64 JSON) yang dikirim aplikasi.
 */
function get_auth_user($pdo)
{
    $authHeader = get_authorization_header();

    if (!preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
        return null;
    }

    $decoded = json_decode(base64_decode($matches[1]), true);

    if (!is_array($decoded) || empty($decoded['id'])) {
        return null;
    }

    $stmt = $pdo->prepare("SELECT id, username, role, photo FROM users WHERE id = ? LIMIT 1");
    $stmt->execute([$decoded['id']]);
    $user = $stmt->fetch();

    return $user ?: null;
}

const ALLOWED_ROLES = ['driver', 'admin', 'petugas'];

function is_allowed_role($user)
{
    return in_array(strtolower(trim($user['role'] ?? '')), ALLOWED_ROLES, true);
}

function require_auth($pdo)
{
    $user = get_auth_user($pdo);

    if (!$user) {
        json_response(["message" => "Sesi login tidak valid. Silakan login ulang."], 401);
    }

    if (!is_allowed_role($user)) {
        json_response(["message" => "Akun ini tidak memiliki akses ke aplikasi."], 403);
    }

    return $user;
}

function is_admin($user)
{
    return ($user['role'] ?? '') === 'admin';
}

/**
 * Cari baris harga BBM yang berlaku untuk sebuah tanggal:
 * tanggal_berlaku terbaru yang <= tanggal transaksi.
 */
function find_harga_berlaku($pdo, $tanggal)
{
    $stmt = $pdo->prepare(
        "SELECT * FROM harga_bbm WHERE tanggal_berlaku <= ? ORDER BY tanggal_berlaku DESC LIMIT 1"
    );
    $stmt->execute([$tanggal]);
    $row = $stmt->fetch();

    return $row ?: null;
}

function harga_per_liter($harga, $jenis)
{
    $kolom = 'harga_' . $jenis;

    return isset($harga[$kolom]) ? (float) $harga[$kolom] : 0.0;
}

function is_valid_date($value)
{
    if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', (string) $value)) {
        return false;
    }

    [$year, $month, $day] = array_map('intval', explode('-', $value));

    return checkdate($month, $day, $year);
}

function format_harga_bbm($row, $isDipakai = false)
{
    return [
        'id' => (int) $row['id'],
        'tanggal_berlaku' => $row['tanggal_berlaku'],
        'harga_pertamax' => (float) $row['harga_pertamax'],
        'harga_pertadex' => (float) $row['harga_pertadex'],
        'harga_dexlite' => (float) $row['harga_dexlite'],
        'harga_pertamax_turbo' => (float) $row['harga_pertamax_turbo'],
        'harga_solar' => (float) ($row['harga_solar'] ?? 0),
        'is_dipakai' => (bool) $isDipakai,
        'created_at' => $row['created_at'] ?? null,
        'updated_at' => $row['updated_at'] ?? null,
    ];
}
