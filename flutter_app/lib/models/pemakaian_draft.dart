class PemakaianDraft {
  final DateTime tanggal;
  final int kendaraanId;
  final String kendaraanLabel;
  final String jenisBbm;
  final String lokasiPembelian;
  final double hargaPerLiter;
  final double liter;
  final double totalHarga;
  final double serviceOli;
  final double jasa;

  const PemakaianDraft({
    required this.tanggal,
    required this.kendaraanId,
    required this.kendaraanLabel,
    required this.jenisBbm,
    required this.lokasiPembelian,
    required this.hargaPerLiter,
    this.liter = 0,
    this.totalHarga = 0,
    this.serviceOli = 0,
    this.jasa = 0,
  });

  double get hargaBbm => liter * hargaPerLiter;

  double get totalPembelian => totalHarga > 0 ? totalHarga : hargaBbm;

  double get jumlah => totalPembelian + serviceOli + jasa;

  PemakaianDraft copyWith({
    DateTime? tanggal,
    int? kendaraanId,
    String? kendaraanLabel,
    String? jenisBbm,
    String? lokasiPembelian,
    double? hargaPerLiter,
    double? liter,
    double? totalHarga,
    double? serviceOli,
    double? jasa,
  }) {
    return PemakaianDraft(
      tanggal: tanggal ?? this.tanggal,
      kendaraanId: kendaraanId ?? this.kendaraanId,
      kendaraanLabel: kendaraanLabel ?? this.kendaraanLabel,
      jenisBbm: jenisBbm ?? this.jenisBbm,
      lokasiPembelian: lokasiPembelian ?? this.lokasiPembelian,
      hargaPerLiter: hargaPerLiter ?? this.hargaPerLiter,
      liter: liter ?? this.liter,
      totalHarga: totalHarga ?? this.totalHarga,
      serviceOli: serviceOli ?? this.serviceOli,
      jasa: jasa ?? this.jasa,
    );
  }
}
