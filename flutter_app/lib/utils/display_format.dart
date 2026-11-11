// Pelengkap untuk util format yang sudah ada di proyek (formatRupiah,
// formatAngka, formatLiter). Hanya berisi yang belum tersedia di sana.
// Letakkan di lib/utils/display_format.dart.
//
// Tanggal sengaja tidak memakai DateFormat('id_ID') supaya tidak bergantung
// pada initializeDateFormatting dan tidak bisa crash kalau locale belum siap.

const _bulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// Ubah nilai dari API (num atau String) jadi double. Tidak pernah melempar
/// error: nilai kosong atau tidak valid menjadi 0.
double asDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse((v ?? '').toString()) ?? 0;
}

/// '2026-09-14' -> '14 Sep 2026'. Nilai kosong (null) tampil '-'.
String fmtTgl(dynamic value) {
  final raw = (value ?? '').toString();
  if (raw.isEmpty) return '-';
  final iso = raw.length >= 10 ? raw.substring(0, 10) : raw;
  final p = iso.split('-');
  if (p.length != 3) return raw;
  final m = int.tryParse(p[1]) ?? 0;
  if (m < 1 || m > 12) return raw;
  return '${int.tryParse(p[2]) ?? p[2]} ${_bulan[m - 1]} ${p[0]}';
}

/// 'luar_paiton' -> 'Luar Paiton'. Nilai kosong (null) tampil '-'.
String fmtTitle(dynamic value) {
  final s = (value ?? '').toString();
  if (s.isEmpty) return '-';
  return s
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// 1.250.000 -> 'Rp 1,25 jt', 300.000 -> 'Rp 300 rb', 500 -> 'Rp 500'
String fmtRpRingkas(num v) {
  if (v >= 1000000) {
    final x = (v / 1000000).toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    return 'Rp ${x.replaceAll('.', ',')} jt';
  }
  if (v >= 1000) {
    final x = (v / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), '');
    return 'Rp ${x.replaceAll('.', ',')} rb';
  }
  return 'Rp ${v.round()}';
}