class JenisBbmUsage {
  final String jenisBbm;
  final String label;
  final double liter;
  final double jumlah;
  final int transaksi;

  const JenisBbmUsage({
    required this.jenisBbm,
    required this.label,
    required this.liter,
    required this.jumlah,
    required this.transaksi,
  });

  factory JenisBbmUsage.fromJson(Map<String, dynamic> json) {
    return JenisBbmUsage(
      jenisBbm: json['jenis_bbm'] as String? ?? '',
      label: json['label'] as String? ?? '-',
      liter: (json['liter'] as num?)?.toDouble() ?? 0,
      jumlah: (json['jumlah'] as num?)?.toDouble() ?? 0,
      transaksi: (json['transaksi'] as num?)?.toInt() ?? 0,
    );
  }
}
