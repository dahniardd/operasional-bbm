<?php
// Helper penyimpanan foto bukti BBM.
// File disimpan di storage/app/public/bukti-bbm agar kompatibel dengan
// halaman riwayat BBM pada website Laravel (storage-proxy.php).

function bukti_bbm_storage_base()
{
    $override = getenv('BUKTI_BBM_STORAGE_DIR');

    if ($override !== false && $override !== '') {
        return rtrim($override, '/\\');
    }

    $apiDir = __DIR__;

    // Produksi: <laravel>/public/api-bbm -> <laravel>/storage/app/public
    if (strcasecmp(basename(dirname($apiDir)), 'public') === 0) {
        return dirname($apiDir, 2) . '/storage/app/public';
    }

    // Lokal: <www>/operasional-bbm/api -> <www>/operasional/storage/app/public
    return dirname($apiDir, 2) . '/operasional/storage/app/public';
}

function bukti_bbm_simpan($file)
{
    if (!isset($file) || ($file['error'] ?? UPLOAD_ERR_NO_FILE) === UPLOAD_ERR_NO_FILE) {
        return null;
    }

    if ($file['error'] !== UPLOAD_ERR_OK) {
        json_response(['message' => 'Gagal mengunggah foto bukti BBM.'], 422);
    }

    $maxBytes = 5 * 1024 * 1024;
    if (($file['size'] ?? 0) > $maxBytes) {
        json_response(['message' => 'Ukuran foto bukti BBM maksimal 5 MB.'], 422);
    }

    $info = @getimagesize($file['tmp_name']);
    if (!$info || empty($info['mime'])) {
        json_response(['message' => 'File bukti BBM bukan gambar yang valid.'], 422);
    }

    $mimeToExt = [
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        'image/webp' => 'webp',
    ];

    $mime = strtolower($info['mime']);
    if (!isset($mimeToExt[$mime])) {
        json_response(['message' => 'Format foto bukti BBM harus JPG, PNG, atau WEBP.'], 422);
    }

    $base = bukti_bbm_storage_base();
    if (!is_dir($base)) {
        json_response(['message' => 'Folder penyimpanan foto tidak tersedia.'], 500);
    }

    $dir = rtrim($base, '/\\') . DIRECTORY_SEPARATOR . 'bukti-bbm';
    if (!is_dir($dir) && !mkdir($dir, 0775, true) && !is_dir($dir)) {
        json_response(['message' => 'Folder penyimpanan foto tidak tersedia.'], 500);
    }

    $filename = 'bukti_' . date('Ymd_His') . '_' . bin2hex(random_bytes(4)) . '.' . $mimeToExt[$mime];
    $target = $dir . DIRECTORY_SEPARATOR . $filename;

    if (!move_uploaded_file($file['tmp_name'], $target)) {
        json_response(['message' => 'Gagal menyimpan foto bukti BBM.'], 500);
    }

    @chmod($target, 0644);

    return 'bukti-bbm/' . $filename;
}

function bukti_bbm_resolve_file($path)
{
    $path = ltrim((string) $path, '/');

    if ($path === '' || str_contains($path, '..')) {
        return null;
    }

    $candidates = [];

    if (str_starts_with($path, 'bukti-bbm/')) {
        $candidates[] = [bukti_bbm_storage_base(), $path];
    } elseif (str_starts_with($path, 'uploads/bukti/')) {
        // Legacy: file lama tersimpan di folder API.
        $candidates[] = [__DIR__, $path];
        $candidates[] = [bukti_bbm_storage_base(), 'bukti-bbm/' . basename($path)];
    } else {
        return null;
    }

    foreach ($candidates as [$base, $relative]) {
        $realBase = realpath($base);
        if ($realBase === false) {
            continue;
        }

        $candidate = $realBase . DIRECTORY_SEPARATOR . str_replace('/', DIRECTORY_SEPARATOR, $relative);
        $real = realpath($candidate);

        if ($real === false || !is_file($real)) {
            continue;
        }

        $basePrefix = rtrim(str_replace('\\', '/', $realBase), '/') . '/';
        $realFile = str_replace('\\', '/', $real);

        if (str_starts_with(strtolower($realFile), strtolower($basePrefix))) {
            return $real;
        }
    }

    return null;
}

function bukti_bbm_hapus($path)
{
    if ($path === null || $path === '' || str_starts_with((string) $path, 'http')) {
        return;
    }

    $file = bukti_bbm_resolve_file($path);

    if ($file !== null) {
        @unlink($file);
    }
}

function bukti_bbm_mime($file)
{
    $ext = strtolower(pathinfo($file, PATHINFO_EXTENSION));
    $map = [
        'jpg' => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
    ];

    if (isset($map[$ext])) {
        return $map[$ext];
    }

    $mime = function_exists('mime_content_type') ? mime_content_type($file) : false;

    return $mime ?: 'application/octet-stream';
}
