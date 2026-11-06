<?php
require_once __DIR__ . '/config.php';

$user = require_auth($pdo);

$method = $_SERVER['REQUEST_METHOD'];
$input = get_request_input();
$action = $_GET['action'] ?? ($input['action'] ?? '');
$id = $_GET['id'] ?? ($input['id'] ?? null);

const JENIS_BBM = ['pertamax', 'pertadex', 'dexlite', 'pertamax_turbo', 'solar'];
const LOKASI_PEMBELIAN = ['paiton', 'luar_paiton'];

function bukti_bbm_url($path)
{
    if ($path === null || $path === '') {
        return null;
    }

    if (str_starts_with($path, 'http')) {
        return $path;
    }

    return rtrim(get_base_url(), '/') . '/' . ltrim($path, '/');
}

function simpan_bukti_bbm($file)
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

    $dir = __DIR__ . '/uploads/bukti';
    if (!is_dir($dir) && !mkdir($dir, 0755, true) && !is_dir($dir)) {
        json_response(['message' => 'Folder penyimpanan foto tidak tersedia.'], 500);
    }

    $filename = 'bukti_' . date('Ymd_His') . '_' . bin2hex(random_bytes(4)) . '.' . $mimeToExt[$mime];
    $target = $dir . '/' . $filename;

    if (!move_uploaded_file($file['tmp_name'], $target)) {
        json_response(['message' => 'Gagal menyimpan foto bukti BBM.'], 500);
    }

    @chmod($target, 0644);

    return 'uploads/bukti/' . $filename;
}

function hapus_bukti_bbm($path)
{
    if ($path === null || $path === '' || str_starts_with($path, 'http')) {
        return;
    }

    $file = __DIR__ . '/' . ltrim($path, '/');
    if (is_file($file)) {
        @unlink($file);
    }
}

function format_pemakaian($row)
{
    return [
        'id' => (int) $row['id'],
        'kendaraan_id' => (int) $row['kendaraan_id'],
        'plat_nomor' => $row['plat_nomor'] ?? '-',
        'nama_jenis' => $row['nama_jenis'] ?? null,
        'unit' => $row['unit'] ?? null,
        'harga_bbm_id' => (int) $row['harga_bbm_id'],
        'tanggal' => $row['tanggal'],
        'jenis_bbm' => $row['jenis_bbm'],
        'lokasi_pembelian' => $row['lokasi_pembelian'],
        'liter' => (float) $row['liter'],
        'rp' => (float) $row['rp'],
        'service_oli' => (float) $row['service_oli'],
        'jasa' => (float) $row['jasa'],
        'jumlah' => (float) $row['jumlah'],
        'dicatat_oleh' => (int) $row['dicatat_oleh'],
        'pencatat' => $row['pencatat'] ?? null,
        'bukti_bbm' => $row['bukti_bbm'] ?? null,
        'bukti_bbm_url' => bukti_bbm_url($row['bukti_bbm'] ?? null),
        'created_at' => $row['created_at'] ?? null,
        'updated_at' => $row['updated_at'] ?? null,
    ];
}

function pemakaian_select_sql()
{
    return "
        SELECT p.*, k.plat_nomor, k.nama_jenis, k.unit, u.username AS pencatat
        FROM pemakaian_bbm p
        LEFT JOIN kendaraan k ON p.kendaraan_id = k.id
        LEFT JOIN users u ON p.dicatat_oleh = u.id
    ";
}

function get_pemakaian_row($pdo, $id)
{
    $stmt = $pdo->prepare(pemakaian_select_sql() . " WHERE p.id = ? LIMIT 1");
    $stmt->execute([$id]);

    return $stmt->fetch();
}

function parse_date_search($search)
{
    $candidates = [];

    foreach (['d/m/Y', 'd-m-Y', 'Y-m-d'] as $format) {
        $date = DateTime::createFromFormat('!' . $format, $search);

        if ($date && $date->format($format) === $search) {
            $candidates[] = $date->format('Y-m-d');
        }
    }

    return array_values(array_unique($candidates));
}

function numeric_or_zero($value, $label, &$errors)
{
    if ($value === null || $value === '') {
        return 0.0;
    }

    if (!is_numeric($value)) {
        $errors[$label] = [ucfirst(str_replace('_', ' ', $label)) . ' harus berupa angka.'];

        return 0.0;
    }

    $number = (float) $value;

    if ($number < 0) {
        $errors[$label] = [ucfirst(str_replace('_', ' ', $label)) . ' tidak boleh kurang dari 0.'];

        return 0.0;
    }

    return $number;
}

function validate_pemakaian_input($pdo, $input)
{
    $errors = [];

    $tanggal = trim((string) ($input['tanggal'] ?? ''));
    if (!is_valid_date($tanggal)) {
        $errors['tanggal'] = ['Tanggal wajib diisi dengan format yang valid.'];
    }

    $kendaraanId = $input['kendaraan_id'] ?? null;
    if ($kendaraanId === null || $kendaraanId === '') {
        $errors['kendaraan_id'] = ['Kendaraan wajib dipilih.'];
    } else {
        $stmt = $pdo->prepare("SELECT id FROM kendaraan WHERE id = ? LIMIT 1");
        $stmt->execute([$kendaraanId]);

        if (!$stmt->fetch()) {
            $errors['kendaraan_id'] = ['Kendaraan tidak valid.'];
        }
    }

    $jenisBbm = $input['jenis_bbm'] ?? '';
    if (!in_array($jenisBbm, JENIS_BBM, true)) {
        $errors['jenis_bbm'] = ['Jenis BBM tidak valid.'];
    }

    $lokasi = $input['lokasi_pembelian'] ?? '';
    if (!in_array($lokasi, LOKASI_PEMBELIAN, true)) {
        $errors['lokasi_pembelian'] = ['Lokasi pembelian tidak valid.'];
    }

    $liter = numeric_or_zero($input['liter'] ?? null, 'liter', $errors);
    $serviceOli = numeric_or_zero($input['service_oli'] ?? null, 'service_oli', $errors);
    $jasa = numeric_or_zero($input['jasa'] ?? null, 'jasa', $errors);

    $totalHarga = null;
    if (isset($input['total_harga']) && $input['total_harga'] !== '') {
        if (!is_numeric($input['total_harga']) || (float) $input['total_harga'] < 0) {
            $errors['total_harga'] = ['Total Harga harus berupa angka dan tidak boleh kurang dari 0.'];
        } else {
            $totalHarga = (float) $input['total_harga'];
        }
    }

    if (!empty($errors)) {
        json_response([
            'message' => reset($errors)[0],
            'errors' => $errors,
        ], 422);
    }

    $harga = find_harga_berlaku($pdo, $tanggal);

    if (!$harga) {
        json_response([
            'message' => 'Belum ada data harga BBM yang berlaku untuk tanggal ini. Tambahkan dulu di menu Harga BBM.',
            'errors' => [
                'jenis_bbm' => [
                    'Belum ada data harga BBM yang berlaku untuk tanggal ini. Tambahkan dulu di menu Harga BBM.',
                ],
            ],
        ], 422);
    }

    $hargaPerLiter = harga_per_liter($harga, $jenisBbm);
    $rp = $totalHarga !== null ? $totalHarga : ($liter * $hargaPerLiter);
    $jumlah = $rp + $serviceOli + $jasa;

    return [
        'tanggal' => $tanggal,
        'kendaraan_id' => (int) $kendaraanId,
        'harga_bbm_id' => (int) $harga['id'],
        'jenis_bbm' => $jenisBbm,
        'lokasi_pembelian' => $lokasi,
        'liter' => $liter,
        'rp' => $rp,
        'service_oli' => $serviceOli,
        'jasa' => $jasa,
        'jumlah' => $jumlah,
    ];
}

if ($method === 'GET') {
    if ($id !== null && $id !== '') {
        $row = get_pemakaian_row($pdo, $id);

        if (!$row) {
            json_response(['message' => 'Data pemakaian BBM tidak ditemukan.'], 404);
        }

        json_response(['data' => format_pemakaian($row)]);
    }

    $where = [];
    $params = [];

    $search = trim((string) ($_GET['search'] ?? ''));
    if ($search !== '') {
        $dateCandidates = parse_date_search($search);
        $searchParts = ["k.plat_nomor LIKE ?", "p.tanggal LIKE ?"];
        $searchParams = ["%{$search}%", "%{$search}%"];

        if (!empty($dateCandidates)) {
            $placeholders = implode(', ', array_fill(0, count($dateCandidates), '?'));
            $searchParts[] = "p.tanggal IN ({$placeholders})";
            foreach ($dateCandidates as $candidate) {
                $searchParams[] = $candidate;
            }
        }

        $where[] = '(' . implode(' OR ', $searchParts) . ')';
        $params = array_merge($params, $searchParams);
    }

    $jenisKendaraan = trim((string) ($_GET['jenis_kendaraan'] ?? ''));
    if ($jenisKendaraan !== '') {
        $where[] = "k.nama_jenis = ?";
        $params[] = $jenisKendaraan;
    }

    $kendaraanId = $_GET['kendaraan_id'] ?? null;
    if ($kendaraanId !== null && $kendaraanId !== '') {
        $where[] = "p.kendaraan_id = ?";
        $params[] = $kendaraanId;
    }

    $jenisBbm = $_GET['jenis_bbm'] ?? null;
    if (in_array($jenisBbm, JENIS_BBM, true)) {
        $where[] = "p.jenis_bbm = ?";
        $params[] = $jenisBbm;
    }

    $lokasi = $_GET['lokasi_pembelian'] ?? null;
    if (in_array($lokasi, LOKASI_PEMBELIAN, true)) {
        $where[] = "p.lokasi_pembelian = ?";
        $params[] = $lokasi;
    }

    // scope=mine -> hanya data milik user login; scope=others -> data driver lain.
    // User diambil dari token di server, bukan dari parameter yang dikirim aplikasi.
    $scope = $_GET['scope'] ?? '';
    if ($scope === 'mine') {
        $where[] = "p.dicatat_oleh = ?";
        $params[] = (int) $user['id'];
    } elseif ($scope === 'others') {
        $where[] = "p.dicatat_oleh <> ?";
        $params[] = (int) $user['id'];
    }

    $whereSql = !empty($where) ? ' WHERE ' . implode(' AND ', $where) : '';

    $countStmt = $pdo->prepare(
        "SELECT COUNT(*) FROM pemakaian_bbm p LEFT JOIN kendaraan k ON p.kendaraan_id = k.id{$whereSql}"
    );
    $countStmt->execute($params);
    $total = (int) $countStmt->fetchColumn();

    // Ringkasan total (semua halaman) untuk filter yang sedang aktif.
    $sumStmt = $pdo->prepare(
        "SELECT COALESCE(SUM(p.jumlah), 0) AS total_jumlah, COALESCE(SUM(p.liter), 0) AS total_liter
         FROM pemakaian_bbm p LEFT JOIN kendaraan k ON p.kendaraan_id = k.id{$whereSql}"
    );
    $sumStmt->execute($params);
    $sum = $sumStmt->fetch();

    $page = max(1, (int) ($_GET['page'] ?? 1));
    $perPage = (int) ($_GET['per_page'] ?? 20);
    $perPage = max(1, min(100, $perPage));
    $lastPage = max(1, (int) ceil($total / $perPage));
    $offset = ($page - 1) * $perPage;

    $sql = pemakaian_select_sql() . $whereSql . " ORDER BY p.tanggal DESC, p.id DESC LIMIT ? OFFSET ?";
    $stmt = $pdo->prepare($sql);

    $position = 1;
    foreach ($params as $value) {
        $stmt->bindValue($position++, $value);
    }

    $stmt->bindValue($position++, $perPage, PDO::PARAM_INT);
    $stmt->bindValue($position, $offset, PDO::PARAM_INT);
    $stmt->execute();

    $rows = $stmt->fetchAll();

    json_response([
        'data' => array_map('format_pemakaian', $rows),
        'meta' => [
            'current_page' => $page,
            'per_page' => $perPage,
            'last_page' => $lastPage,
            'total' => $total,
            'total_jumlah' => (float) $sum['total_jumlah'],
            'total_liter' => (float) $sum['total_liter'],
        ],
    ]);
}

if ($method === 'POST') {
    if ($action === 'refresh_harga') {
        if (!in_array($user['role'] ?? '', ['admin', 'petugas'], true)) {
            json_response(['message' => 'Hanya admin dan petugas yang bisa refresh harga pemakaian BBM.'], 403);
        }

        $updated = 0;
        $dilewati = 0;

        $hargaRows = $pdo->query(
            "SELECT * FROM harga_bbm ORDER BY tanggal_berlaku DESC"
        )->fetchAll();

        $items = $pdo->query("SELECT * FROM pemakaian_bbm ORDER BY id ASC")->fetchAll();

        foreach ($items as $item) {
            if (!in_array($item['jenis_bbm'], JENIS_BBM, true)) {
                $dilewati++;
                continue;
            }

            $harga = null;

            foreach ($hargaRows as $row) {
                if ($row['tanggal_berlaku'] <= $item['tanggal']) {
                    $harga = $row;
                    break;
                }
            }

            if (!$harga) {
                $dilewati++;
                continue;
            }

            $hargaPerLiter = harga_per_liter($harga, $item['jenis_bbm']);
            $rpBaru = (float) $item['liter'] * $hargaPerLiter;
            $jumlahBaru = $rpBaru + (float) $item['service_oli'] + (float) $item['jasa'];

            $berubah = (int) $item['harga_bbm_id'] !== (int) $harga['id']
                || round((float) $item['rp'], 2) !== round($rpBaru, 2)
                || round((float) $item['jumlah'], 2) !== round($jumlahBaru, 2);

            if (!$berubah) {
                $dilewati++;
                continue;
            }

            $stmt = $pdo->prepare(
                "UPDATE pemakaian_bbm SET harga_bbm_id = ?, rp = ?, jumlah = ?, updated_at = ? WHERE id = ?"
            );
            $stmt->execute([$harga['id'], $rpBaru, $jumlahBaru, date('Y-m-d H:i:s'), $item['id']]);
            $updated++;
        }

        $message = $updated > 0
            ? "Berhasil refresh {$updated} data yang terdampak perubahan harga BBM ({$dilewati} data lain sudah sesuai)."
            : 'Semua data sudah sesuai dengan harga BBM terbaru, tidak ada yang perlu diperbarui.';

        json_response([
            'message' => $message,
            'updated' => $updated,
            'skipped' => $dilewati,
        ]);
    }

    $validated = validate_pemakaian_input($pdo, $input);

    $buktiBaru = simpan_bukti_bbm($_FILES['bukti_bbm'] ?? null);
    if ($buktiBaru !== null) {
        $validated['bukti_bbm'] = $buktiBaru;
    }

    $validated['dicatat_oleh'] = (int) $user['id'];
    $now = date('Y-m-d H:i:s');

    if ($id !== null && $id !== '') {
        $existing = get_pemakaian_row($pdo, $id);

        if (!$existing) {
            json_response(['message' => 'Data pemakaian BBM tidak ditemukan.'], 404);
        }

        $bolehUbah = in_array($user['role'] ?? '', ['admin', 'petugas'], true)
            || (int) $existing['dicatat_oleh'] === (int) $user['id'];

        if (!$bolehUbah) {
            json_response(['message' => 'Anda hanya bisa mengubah data pemakaian milik sendiri.'], 403);
        }

        if ($buktiBaru !== null) {
            hapus_bukti_bbm($existing['bukti_bbm'] ?? null);
        }

        // Pencatat asli tidak diganti saat data diubah.
        $validated['dicatat_oleh'] = (int) $existing['dicatat_oleh'];

        $set = implode(', ', array_map(fn ($field) => "{$field} = ?", array_keys($validated)));
        $params = array_values($validated);
        $params[] = $now;
        $params[] = $id;

        $stmt = $pdo->prepare("UPDATE pemakaian_bbm SET {$set}, updated_at = ? WHERE id = ?");
        $stmt->execute($params);

        $saved = get_pemakaian_row($pdo, $id);

        json_response([
            'message' => 'Data pemakaian BBM berhasil diperbarui.',
            'data' => format_pemakaian($saved),
        ]);
    }

    $columns = array_keys($validated);
    $placeholders = implode(', ', array_fill(0, count($columns), '?'));
    $params = array_values($validated);
    $params[] = $now;
    $params[] = $now;

    $stmt = $pdo->prepare(
        "INSERT INTO pemakaian_bbm (" . implode(', ', $columns) . ", created_at, updated_at)
         VALUES ({$placeholders}, ?, ?)"
    );
    $stmt->execute($params);

    $newId = (int) $pdo->lastInsertId();
    $saved = get_pemakaian_row($pdo, $newId);

    json_response([
        'message' => 'Data pemakaian BBM berhasil disimpan.',
        'data' => format_pemakaian($saved),
    ], 201);
}

if ($method === 'DELETE') {
    if ($id === null || $id === '') {
        json_response(['message' => 'ID pemakaian BBM wajib diisi.'], 422);
    }

    if (!is_admin($user)) {
        json_response(['message' => 'Hanya admin yang bisa menghapus data pemakaian BBM.'], 403);
    }

    $existing = get_pemakaian_row($pdo, $id);

    if (!$existing) {
        json_response(['message' => 'Data pemakaian BBM tidak ditemukan.'], 404);
    }

    $stmt = $pdo->prepare("DELETE FROM pemakaian_bbm WHERE id = ?");
    $stmt->execute([$id]);

    hapus_bukti_bbm($existing['bukti_bbm'] ?? null);

    json_response(['message' => 'Data pemakaian BBM berhasil dihapus.']);
}

json_response(['message' => 'Method not allowed'], 405);