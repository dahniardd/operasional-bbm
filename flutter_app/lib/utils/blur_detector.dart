import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// Deteksi foto buram dengan variansi Laplacian.
///
/// Cara kerja: foto dikecilkan (lebar 480 px, di-decode native sehingga cepat
/// dan tidak menahan UI), diubah ke abu-abu, lalu tiap piksel dihitung selisih
/// tajamnya dengan tetangga (kernel Laplacian). Foto tajam punya tepi tegas
/// sehingga hasilnya bervariasi besar; foto buram hasilnya datar.
///
/// Foto dibagi 4x4 petak dan yang dinilai adalah RATA-RATA 25% PETAK TERTAJAM,
/// bukan seluruh gambar. Struk didominasi kertas putih polos; kalau seluruh
/// gambar dirata-rata, struk yang tajam pun bisa terkesan "datar".
///
/// Letakkan di lib/utils/blur_detector.dart.
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

  static const int _lebarAnalisis = 480;
  static const int _grid = 4;

  /// Skor ketajaman (makin besar makin tajam). Melempar error kalau gambar
  /// tidak bisa dibaca; pemanggil sebaiknya menganggapnya "tidak diketahui".
  static Future<double> skorKetajaman(Uint8List bytes) async {
    final codec =
        await ui.instantiateImageCodec(bytes, targetWidth: _lebarAnalisis);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final w = image.width;
    final h = image.height;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    codec.dispose();

    if (data == null || w < 8 || h < 8) return 0;
    final rgba = data.buffer.asUint8List();

    // Abu-abu (luminans).
    final gray = Float32List(w * h);
    for (var i = 0, p = 0; i < gray.length; i++, p += 4) {
      gray[i] = 0.299 * rgba[p] + 0.587 * rgba[p + 1] + 0.114 * rgba[p + 2];
    }

    // Variansi Laplacian per petak.
    final variansi = <double>[];
    for (var gy = 0; gy < _grid; gy++) {
      for (var gx = 0; gx < _grid; gx++) {
        final x0 = (gx * w ~/ _grid).clamp(1, w - 1).toInt();
        final x1 = ((gx + 1) * w ~/ _grid).clamp(1, w - 1).toInt();
        final y0 = (gy * h ~/ _grid).clamp(1, h - 1).toInt();
        final y1 = ((gy + 1) * h ~/ _grid).clamp(1, h - 1).toInt();

        var sum = 0.0;
        var sumSq = 0.0;
        var n = 0;
        for (var y = y0; y < y1; y++) {
          final row = y * w;
          for (var x = x0; x < x1; x++) {
            final i = row + x;
            final lap = gray[i - w] + gray[i + w] + gray[i - 1] + gray[i + 1] -
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

    if (variansi.isEmpty) return 0;
    variansi.sort((a, b) => b.compareTo(a));
    final ambil = (variansi.length / 4).ceil().clamp(1, variansi.length).toInt();
    final skor = variansi.take(ambil).reduce((a, b) => a + b) / ambil;

    if (kDebugMode) debugPrint('Skor ketajaman: ${skor.toStringAsFixed(1)} '
        '(batas ${batasKetajaman.toStringAsFixed(0)})');
    return skor;
  }

  /// true = buram. null = tidak bisa dinilai (mis. format tidak didukung);
  /// dalam kasus itu jangan memblokir pengguna.
  static Future<bool?> apakahBuram(Uint8List bytes) async {
    try {
      return await skorKetajaman(bytes) < batasKetajaman;
    } catch (_) {
      return null;
    }
  }
}