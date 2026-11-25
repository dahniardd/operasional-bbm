import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:operasional_bbm/utils/blur_detector.dart';

Future<Uint8List> _gambar({required bool tajam}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, 480, 320),
    ui.Paint()..color = const ui.Color(0xFFFFFFFF),
  );

  if (tajam) {
    final hitam = ui.Paint()..color = const ui.Color(0xFF000000);
    for (var x = 0.0; x < 480; x += 8) {
      canvas.drawRect(ui.Rect.fromLTWH(x, 0, 4, 320), hitam);
    }
  } else {
    for (var x = 0; x < 480; x += 2) {
      final value = (x * 255 / 480).round();
      canvas.drawRect(
        ui.Rect.fromLTWH(x.toDouble(), 0, 2, 320),
        ui.Paint()..color = ui.Color.fromARGB(255, value, value, value),
      );
    }
  }

  final image = await recorder.endRecording().toImage(480, 320);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();

  return data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

void main() {
  test('gambar dengan tepi tajam diterima', () async {
    final hasil = await BlurDetector.analisisKetajaman(
      await _gambar(tajam: true),
    );

    expect(hasil.dapatDinilai, isTrue);
    expect(
      hasil.petakTajam,
      greaterThanOrEqualTo(BlurDetector.minimumPetakTajam),
    );
    expect(hasil.buram, isFalse);
  });

  test('gambar blur ditolak', () async {
    final hasil = await BlurDetector.analisisKetajaman(
      await _gambar(tajam: false),
    );

    expect(hasil.dapatDinilai, isTrue);
    expect(hasil.buram, isTrue);
  });

  test('gambar yang tidak bisa dibaca ditolak', () async {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);

    final hasil = await BlurDetector.analisisKetajaman(bytes);
    expect(hasil.dapatDinilai, isFalse);
    expect(hasil.buram, isTrue);
    expect(await BlurDetector.apakahBuram(bytes), isTrue);
  });

  test('jumlah petak tajam kurang dari minimum ditolak', () {
    const hasil = HasilKetajaman(
      skor: 200,
      petakTajam: BlurDetector.minimumPetakTajam - 1,
      dapatDinilai: true,
    );

    expect(hasil.buram, isTrue);
  });
}
