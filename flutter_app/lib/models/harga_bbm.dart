class HargaBbm {
  final int id;
  final DateTime tanggalBerlaku;
  final double hargaPertamax;
  final double hargaPertadex;
  final double hargaDexlite;
  final double hargaPertamaxTurbo;
  final double hargaSolar;
  final bool isDipakai;

  HargaBbm({
    required this.id,
    required this.tanggalBerlaku,
    required this.hargaPertamax,
    required this.hargaPertadex,
    required this.hargaDexlite,
    required this.hargaPertamaxTurbo,
    required this.hargaSolar,
    this.isDipakai = false,
  });

  factory HargaBbm.fromJson(Map<String, dynamic> json) {
    return HargaBbm(
      id: (json['id'] as num).toInt(),
      tanggalBerlaku: DateTime.parse(json['tanggal_berlaku'] as String),
      hargaPertamax: (json['harga_pertamax'] as num?)?.toDouble() ?? 0,
      hargaPertadex: (json['harga_pertadex'] as num?)?.toDouble() ?? 0,
      hargaDexlite: (json['harga_dexlite'] as num?)?.toDouble() ?? 0,
      hargaPertamaxTurbo:
          (json['harga_pertamax_turbo'] as num?)?.toDouble() ?? 0,
      hargaSolar: (json['harga_solar'] as num?)?.toDouble() ?? 0,
      isDipakai: json['is_dipakai'] as bool? ?? false,
    );
  }

  double hargaUntuk(String jenis) {
    switch (jenis) {
      case 'pertamax':
        return hargaPertamax;
      case 'pertadex':
        return hargaPertadex;
      case 'dexlite':
        return hargaDexlite;
      case 'pertamax_turbo':
        return hargaPertamaxTurbo;
      case 'solar':
        return hargaSolar;
      default:
        return 0;
    }
  }

  Map<String, dynamic> toPayload() {
    return {
      'tanggal_berlaku': formatTanggalIso(tanggalBerlaku),
      'harga_pertamax': hargaPertamax,
      'harga_pertadex': hargaPertadex,
      'harga_dexlite': hargaDexlite,
      'harga_pertamax_turbo': hargaPertamaxTurbo,
      'harga_solar': hargaSolar,
    };
  }

  static String formatTanggalIso(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
