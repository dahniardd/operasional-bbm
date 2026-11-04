class Kendaraan {
  final int id;
  final int jenisKendaraanId;
  final String platNomor;
  final String? namaJenis;
  final String? unit;
  final String? merek;
  final String label;

  Kendaraan({
    required this.id,
    required this.jenisKendaraanId,
    required this.platNomor,
    this.namaJenis,
    this.unit,
    this.merek,
    required this.label,
  });

  factory Kendaraan.fromJson(Map<String, dynamic> json) {
    return Kendaraan(
      id: (json['id'] as num).toInt(),
      jenisKendaraanId: (json['jenis_kendaraan_id'] as num?)?.toInt() ?? 0,
      platNomor: json['plat_nomor'] as String? ?? '-',
      namaJenis: json['nama_jenis'] as String?,
      unit: json['unit'] as String?,
      merek: json['merek'] as String?,
      label: json['label'] as String? ?? json['plat_nomor'] as String? ?? '-',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Kendaraan && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
