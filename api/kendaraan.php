<?php
require_once __DIR__ . '/config.php';

require_auth($pdo);

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    json_response(["message" => "Method not allowed"], 405);
}

$where = [];
$params = [];

$search = trim((string) ($_GET['search'] ?? ''));
if ($search !== '') {
    $where[] = "(k.plat_nomor LIKE ? OR k.nama_jenis LIKE ? OR k.unit LIKE ?)";
    $params[] = "%{$search}%";
    $params[] = "%{$search}%";
    $params[] = "%{$search}%";
}

$jenisKendaraan = trim((string) ($_GET['jenis_kendaraan'] ?? ''));
if ($jenisKendaraan !== '') {
    $where[] = "k.nama_jenis = ?";
    $params[] = $jenisKendaraan;
}

$kendaraanId = $_GET['kendaraan_id'] ?? null;
if ($kendaraanId !== null && $kendaraanId !== '') {
    $where[] = "k.id = ?";
    $params[] = $kendaraanId;
}

$sql = "
    SELECT k.id, k.jenis_kendaraan_id, k.plat_nomor, k.nama_jenis, k.unit,
           jk.nama_merek AS merek
    FROM kendaraan k
    LEFT JOIN jenis_kendaraan jk ON k.jenis_kendaraan_id = jk.id
";

if (!empty($where)) {
    $sql .= " WHERE " . implode(" AND ", $where);
}

$sql .= " ORDER BY k.plat_nomor ASC";

$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$rows = $stmt->fetchAll();

$data = array_map(function ($row) {
    $label = $row['plat_nomor'];

    if (!empty($row['nama_jenis'])) {
        $label .= ' (' . $row['nama_jenis'] . ')';
    }

    return [
        'id' => (int) $row['id'],
        'jenis_kendaraan_id' => (int) $row['jenis_kendaraan_id'],
        'plat_nomor' => $row['plat_nomor'],
        'nama_jenis' => $row['nama_jenis'],
        'unit' => $row['unit'],
        'merek' => $row['merek'],
        'label' => $label,
    ];
}, $rows);

json_response([
    'data' => $data,
    'jenis_kendaraan' => array_values(array_unique(array_filter(array_column($data, 'nama_jenis')))),
]);
