<?php
require_once __DIR__ . '/config.php';

$user = require_auth($pdo);

$method = $_SERVER['REQUEST_METHOD'];
$input = get_request_input();
$action = $_GET['action'] ?? ($input['action'] ?? '');
$id = $_GET['id'] ?? ($input['id'] ?? null);

function harga_field_labels()
{
    return [
        'harga_pertamax' => 'Harga Pertamax',
        'harga_pertadex' => 'Harga Pertadex',
        'harga_dexlite' => 'Harga Dexlite',
        'harga_pertamax_turbo' => 'Harga Pertamax Turbo',
        'harga_solar' => 'Harga Solar',
    ];
}

function validate_harga_input($pdo, $input, $id = null)
{
    $tanggal = trim((string) ($input['tanggal_berlaku'] ?? ''));

    if ($tanggal === '') {
        json_response([
            'message' => 'Tanggal berlaku wajib diisi.',
            'errors' => ['tanggal_berlaku' => ['Tanggal berlaku wajib diisi.']],
        ], 422);
    }

    if (!is_valid_date($tanggal)) {
        json_response([
            'message' => 'Format tanggal tidak valid.',
            'errors' => ['tanggal_berlaku' => ['Format tanggal tidak valid.']],
        ], 422);
    }

    $sql = "SELECT id FROM harga_bbm WHERE tanggal_berlaku = ?";
    $params = [$tanggal];

    if ($id !== null) {
        $sql .= " AND id != ?";
        $params[] = $id;
    }

    $stmt = $pdo->prepare($sql . " LIMIT 1");
    $stmt->execute($params);

    if ($stmt->fetch()) {
        json_response([
            'message' => 'Sudah ada data harga BBM untuk tanggal ini.',
            'errors' => ['tanggal_berlaku' => ['Sudah ada data harga BBM untuk tanggal ini.']],
        ], 422);
    }

    $data = ['tanggal_berlaku' => $tanggal];

    foreach (harga_field_labels() as $field => $label) {
        $raw = $input[$field] ?? null;

        if ($raw === null || $raw === '' || !is_numeric($raw)) {
            json_response([
                'message' => $label . ' wajib diisi dengan angka.',
                'errors' => [$field => [$label . ' wajib diisi dengan angka.']],
            ], 422);
        }

        $value = (float) $raw;

        if ($value < 1) {
            json_response([
                'message' => $label . ' tidak boleh 0.',
                'errors' => [$field => [$label . ' tidak boleh 0.']],
            ], 422);
        }

        $data[$field] = $value;
    }

    if ($id === null) {
        $stmt = $pdo->query("SELECT tanggal_berlaku FROM harga_bbm ORDER BY tanggal_berlaku DESC LIMIT 1");
        $terakhir = $stmt->fetch();

        if ($terakhir && $tanggal <= $terakhir['tanggal_berlaku']) {
            $label = date('d-m-Y', strtotime($terakhir['tanggal_berlaku']));
            json_response([
                'message' => 'Tanggal berlaku tidak boleh sama dengan atau sebelum data terakhir (' . $label . ').',
                'errors' => [
                    'tanggal_berlaku' => [
                        'Tanggal berlaku tidak boleh sama dengan atau sebelum data terakhir (' . $label . ').',
                    ],
                ],
            ], 422);
        }
    }

    return $data;
}

function get_harga_row($pdo, $id)
{
    $stmt = $pdo->prepare("
        SELECT h.*,
               EXISTS(SELECT 1 FROM pemakaian_bbm p WHERE p.harga_bbm_id = h.id) AS is_dipakai
        FROM harga_bbm h
        WHERE h.id = ?
        LIMIT 1
    ");
    $stmt->execute([$id]);

    return $stmt->fetch();
}

if ($method === 'GET') {
    if ($action === 'berlaku') {
        $tanggal = $_GET['tanggal'] ?? '';
        $jenis = $_GET['jenis'] ?? '';

        if (!is_valid_date($tanggal)) {
            json_response(['message' => 'Tanggal tidak valid.'], 422);
        }

        if (!array_key_exists('harga_' . $jenis, harga_field_labels())) {
            json_response(['message' => 'Jenis BBM tidak valid.'], 422);
        }

        $harga = find_harga_berlaku($pdo, $tanggal);

        if (!$harga) {
            json_response([
                'message' => 'Belum ada data harga BBM yang berlaku untuk tanggal ini.',
                'data' => null,
            ], 404);
        }

        json_response([
            'data' => [
                'harga_bbm_id' => (int) $harga['id'],
                'tanggal_berlaku' => $harga['tanggal_berlaku'],
                'jenis_bbm' => $jenis,
                'harga_per_liter' => harga_per_liter($harga, $jenis),
            ],
        ]);
    }

    $stmt = $pdo->query("
        SELECT h.*,
               EXISTS(SELECT 1 FROM pemakaian_bbm p WHERE p.harga_bbm_id = h.id) AS is_dipakai
        FROM harga_bbm h
        ORDER BY h.tanggal_berlaku DESC
    ");
    $rows = $stmt->fetchAll();

    $data = array_map(function ($row) {
        return format_harga_bbm($row, $row['is_dipakai']);
    }, $rows);

    $terakhir = !empty($data) ? $data[0] : null;

    json_response([
        'data' => $data,
        'terakhir' => $terakhir,
        'meta' => ['total' => count($data)],
    ]);
}

if ($method === 'POST') {
    if (!in_array($user['role'] ?? '', ['admin', 'petugas'], true)) {
        json_response(['message' => 'Hanya admin dan petugas yang bisa mengubah harga BBM.'], 403);
    }

    $validated = validate_harga_input($pdo, $input, $id);
    $now = date('Y-m-d H:i:s');

    if ($id !== null && $id !== '') {
        $existing = get_harga_row($pdo, $id);

        if (!$existing) {
            json_response(['message' => 'Data harga BBM tidak ditemukan.'], 404);
        }

        $set = implode(', ', array_map(fn ($field) => "{$field} = ?", array_keys($validated)));

        $params = array_values($validated);
        $params[] = $now;
        $params[] = $id;

        $stmt = $pdo->prepare("UPDATE harga_bbm SET {$set}, updated_at = ? WHERE id = ?");
        $stmt->execute($params);

        $saved = get_harga_row($pdo, $id);

        json_response([
            'message' => 'Data harga BBM berhasil diperbarui.',
            'data' => format_harga_bbm($saved, $saved['is_dipakai']),
        ]);
    }

    $columns = array_keys($validated);
    $placeholders = implode(', ', array_fill(0, count($columns), '?'));

    $params = array_values($validated);
    $params[] = $now;
    $params[] = $now;

    $stmt = $pdo->prepare(
        "INSERT INTO harga_bbm (" . implode(', ', $columns) . ", created_at, updated_at)
         VALUES ({$placeholders}, ?, ?)"
    );
    $stmt->execute($params);

    $newId = (int) $pdo->lastInsertId();
    $saved = get_harga_row($pdo, $newId);

    json_response([
        'message' => 'Data harga BBM tanggal ' . date('d-m-Y', strtotime($validated['tanggal_berlaku'])) . ' berhasil ditambahkan.',
        'data' => format_harga_bbm($saved, $saved['is_dipakai']),
    ], 201);
}

if ($method === 'DELETE') {
    if ($id === null || $id === '') {
        json_response(['message' => 'ID harga BBM wajib diisi.'], 422);
    }

    if (!is_admin($user)) {
        json_response(['message' => 'Hanya admin yang bisa menghapus data harga BBM.'], 403);
    }

    $existing = get_harga_row($pdo, $id);

    if (!$existing) {
        json_response(['message' => 'Data harga BBM tidak ditemukan.'], 404);
    }

    if ((int) $existing['is_dipakai'] === 1) {
        json_response([
            'message' => 'Data harga BBM tanggal ' . date('d-m-Y', strtotime($existing['tanggal_berlaku'])) . ' tidak bisa dihapus karena sudah dipakai.',
        ], 422);
    }

    $stmt = $pdo->prepare("DELETE FROM harga_bbm WHERE id = ?");
    $stmt->execute([$id]);

    json_response(['message' => 'Data harga BBM berhasil dihapus.']);
}

json_response(['message' => 'Method not allowed'], 405);
