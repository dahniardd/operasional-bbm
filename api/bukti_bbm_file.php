<?php
require_once __DIR__ . '/bukti_bbm_helper.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$path = $_GET['path'] ?? '';
$file = bukti_bbm_resolve_file($path);

if ($file === null) {
    http_response_code(404);
    header('Content-Type: text/plain; charset=UTF-8');
    exit('File tidak ditemukan');
}

$mime = bukti_bbm_mime($file);

header('Content-Type: ' . $mime);
header('Content-Length: ' . filesize($file));
header('Content-Disposition: inline; filename="' . basename($file) . '"');
header('Cache-Control: public, max-age=86400');
header('X-Content-Type-Options: nosniff');

readfile($file);
exit;
