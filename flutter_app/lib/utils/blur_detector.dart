import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// Deteksi foto buram dengan variansi Laplacian.
///
/// Cara kerja: foto dikecilkan (lebar 480 px, di-decode native sehingga cepat
/// dan tidak menahan UI), diubah ke abu-abu, lalu tiap piksel dihitung selisih
/// tajamnya dengan tetangga (kernel Laplacian). Foto tajam punya tepi tegas
/// sehingga hasilnya bervariasi besar; foto buram hasilnya datar.
///
/// Foto dibagi 4x4 petak dan yang dinilai adalah rata-rata 25% petak tertajam
/// serta jumlah petak yang benar-benar tajam. Struk didominasi kertas putih
/// polos; kalau seluruh gambar dirata-rata, struk yang tajam pun bisa terkesan
/// "datar".
class BlurDetector {
  const BlurDetector._();

  /// Skor di bawah batas ini dianggap buram.
  ///
  /// PENTING: ini nilai awal, bukan angka pasti. Kalibrasi dengan foto asli
  /// dari HP driver: ambil ~10 foto struk yang jelas dan ~10 yang buram, lihat
  /// skornya di log debug ("Skor ketajaman: ..."), lalu pilih batas di antara
  /// keduanya. Naikkan batas kalau foto buram masih lolos, turunkan kalau foto
  /// yang jelas ikut ditolak.
  static const double batasKetajaman = 60;

  static const int minimumPetakTajam = 4;

  static const int _lebarAnalisis = 480;
  static const int _grid = 4;

  /// Skor ketajaman (makin besar makin tajam).
  static Future<double> skorKetajaman(Uint8List bytes) async {
    return (await analisisKetajaman(bytes)).skor;
  }

  /// true = buram. Gambar yang tidak bisa dinilai juga dianggap buram.
  static Future<bool> apakahBuram(Uint8List bytes) async {
    return (await analisisKetajaman(bytes)).buram;
  }

  static Future<HasilKetajaman> analisisKetajaman(Uint8List bytes) async {
    ui.Codec? codec;
    ui.Image? image;

    try {
      codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: _lebarAnalisis,
      );
      final frame = await codec.getNextFrame();
      final currentImage = frame.image;
      image = currentImage;
      final w = currentImage.width;
      final h = currentImage.height;
      final data = await currentImage.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      if (data == null || w < 8 || h < 8) {
        return const HasilKetajaman(
          skor: 0,
          petakTajam: 0,
          dapatDinilai: false,
        );
      }

      final rgba = Uint8List.fromList(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      final hasil = await compute(
        _hitungKetajaman,
        _GambarUntukAnalisis(w, h, rgba),
      );

      if (kDebugMode) {
        debugPrint(
          'Skor ketajaman: ${hasil.skor.toStringAsFixed(1)} '
          '(batas ${batasKetajaman.toStringAsFixed(0)}, '
          'petak tajam ${hasil.petakTajam}/${_grid * _grid})',
        );
      }

      return hasil;
    } catch (_) {
      return const HasilKetajaman(skor: 0, petakTajam: 0, dapatDinilai: false);
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }
}

class HasilKetajaman {
  const HasilKetajaman({
    required this.skor,
    required this.petakTajam,
    required this.dapatDinilai,
  });

  final double skor;
  final int petakTajam;
  final bool dapatDinilai;

  bool get buram =>
      !dapatDinilai ||
      skor < BlurDetector.batasKetajaman ||
      petakTajam < BlurDetector.minimumPetakTajam;
}

class _GambarUntukAnalisis {
  const _GambarUntukAnalisis(this.width, this.height, this.rgba);

  final int width;
  final int height;
  final Uint8List rgba;
}

HasilKetajaman _hitungKetajaman(_GambarUntukAnalisis input) {
  final w = input.width;
  final h = input.height;
  final rgba = input.rgba;

  final gray = Float32List(w * h);
  for (var i = 0, p = 0; i < gray.length; i++, p += 4) {
    gray[i] = 0.299 * rgba[p] + 0.587 * rgba[p + 1] + 0.114 * rgba[p + 2];
  }

  final variansi = <double>[];
  for (var gy = 0; gy < BlurDetector._grid; gy++) {
    for (var gx = 0; gx < BlurDetector._grid; gx++) {
      final x0 = (gx * w ~/ BlurDetector._grid).clamp(1, w - 1).toInt();
      final x1 = ((gx + 1) * w ~/ BlurDetector._grid).clamp(1, w - 1).toInt();
      final y0 = (gy * h ~/ BlurDetector._grid).clamp(1, h - 1).toInt();
      final y1 = ((gy + 1) * h ~/ BlurDetector._grid).clamp(1, h - 1).toInt();

      var sum = 0.0;
      var sumSq = 0.0;
      var n = 0;
      for (var y = y0; y < y1; y++) {
        final row = y * w;
        for (var x = x0; x < x1; x++) {
          final i = row + x;
          final lap =
              gray[i - w] +
              gray[i + w] +
              gray[i - 1] +
              gray[i + 1] -
              4 * gray[i];
          sum += lap;
          sumSq += lap * lap;
          n++;
        }
      }
      if (n == 0) continue;
      final mean = sum / n;
      variansi.add(sumSq / n - mean * mean);
    }
  }

  if (variansi.isEmpty) {
    return const HasilKetajaman(skor: 0, petakTajam: 0, dapatDinilai: false);
  }

  final petakTajam = variansi
      .where((value) => value >= BlurDetector.batasKetajaman)
      .length;
  variansi.sort((a, b) => b.compareTo(a));
  final ambil = (variansi.length / 4).ceil().clamp(1, variansi.length).toInt();
  final skor = variansi.take(ambil).reduce((a, b) => a + b) / ambil;

  return HasilKetajaman(skor: skor, petakTajam: petakTajam, dapatDinilai: true);
}
