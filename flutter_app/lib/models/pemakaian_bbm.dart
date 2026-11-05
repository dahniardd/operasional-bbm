class PemakaianBbm {
  final int id;
  final int kendaraanId;
  final String platNomor;
  final String? namaJenis;
  final String? unit;
  final int hargaBbmId;
  final DateTime tanggal;
  final String jenisBbm;
  final String lokasiPembelian;
  final double liter;
  final double rp;
  final double serviceOli;
  final double jasa;
  final double jumlah;
  final int dicatatOleh;
  final String? pencatat;
  final String tanggalString;

  PemakaianBbm({
    required this.id,
    required this.kendaraanId,
    required this.platNomor,
    this.namaJenis,
    this.unit,
    required this.hargaBbmId,
    required this.tanggal,
    required this.jenisBbm,
    required this.lokasiPembelian,
    required this.liter,
    required this.rp,
    required this.serviceOli,
    required this.jasa,
    required this.jumlah,
    required this.dicatatOleh,
    this.pencatat,
  }) : tanggalString = HargaBbmDate.formatIso(tanggal);

  factory PemakaianBbm.fromJson(Map<String, dynamic> json) {
    return PemakaianBbm(
      id: (json['id'] as num).toInt(),
      kendaraanId: (json['kendaraan_id'] as num).toInt(),
      platNomor: json['plat_nomor'] as String? ?? '-',
      namaJenis: json['nama_jenis'] as String?,
      unit: json['unit'] as String?,
      hargaBbmId: (json['harga_bbm_id'] as num?)?.toInt() ?? 0,
      tanggal: DateTime.parse(json['tanggal'] as String),
      jenisBbm: json['jenis_bbm'] as String? ?? '',
      lokasiPembelian: json['lokasi_pembelian'] as String? ?? 'paiton',
      liter: (json['liter'] as num?)?.toDouble() ?? 0,
      rp: (json['rp'] as num?)?.toDouble() ?? 0,
      serviceOli: (json['service_oli'] as num?)?.toDouble() ?? 0,
      jasa: (json['jasa'] as num?)?.toDouble() ?? 0,
      jumlah: (json['jumlah'] as num?)?.toDouble() ?? 0,
      dicatatOleh: (json['dicatat_oleh'] as num?)?.toInt() ?? 0,
      pencatat: json['pencatat'] as String?,
    );
  }

  static const Map<String, String> jenisBbmLabels = {
    'pertamax': 'Pertamax',
    'pertadex': 'Pertadex',
    'dexlite': 'Dexlite',
    'pertamax_turbo': 'Pertamax Turbo',
    'solar': 'Solar',
  };

  static const Map<String, String> lokasiLabels = {
    'paiton': 'Paiton',
    'luar_paiton': 'Luar Paiton',
  };

  String get jenisBbmLabel => jenisBbmLabels[jenisBbm] ?? '-';
  String get lokasiLabel => lokasiLabels[lokasiPembelian] ?? '-';

  Map<String, dynamic> toPayload() {
    return {
      'tanggal': HargaBbmDate.formatIso(tanggal),
      'kendaraan_id': kendaraanId,
      'jenis_bbm': jenisBbm,
      'lokasi_pembelian': lokasiPembelian,
      'liter': liter,
      'total_harga': rp,
      'service_oli': serviceOli,
      'jasa': jasa,
    };
  }
}

class HargaBbmDate {
  static String formatIso(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
