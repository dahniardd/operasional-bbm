import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:operasional_bbm/models/pemakaian_bbm.dart';
import 'package:operasional_bbm/widgets/advanced_chart_widget.dart';

PemakaianBbm _pemakaianHariIni() {
  final now = DateTime.now();
  return PemakaianBbm(
    id: 1,
    kendaraanId: 1,
    platNomor: 'W 1234 AB',
    hargaBbmId: 1,
    tanggal: DateTime(now.year, now.month, now.day, 10),
    jenisBbm: 'pertamax',
    lokasiPembelian: 'paiton',
    liter: 10,
    rp: 100000,
    serviceOli: 0,
    jasa: 0,
    jumlah: 100000,
    dicatatOleh: 1,
  );
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('id_ID');
  });

  testWidgets('filter disembunyikan saat daftar pemakaian kosong', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: AdvancedChartWidget(pemakaianList: []),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum ada data pemakaian BBM'), findsOneWidget);
    expect(find.text('7 Hari'), findsNothing);
    expect(find.text('Tampilkan'), findsNothing);
  });

  testWidgets('filter periode dan metrik berfungsi saat ada data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: AdvancedChartWidget(pemakaianList: [_pemakaianHariIni()]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Grafik Pemakaian BBM'), findsOneWidget);
    expect(find.text('7 Hari'), findsOneWidget);
    expect(find.textContaining('Terakhir 7 Hari'), findsOneWidget);

    await tester.tap(find.text('30 Hari'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Terakhir 30 Hari'), findsOneWidget);

    await tester.tap(find.text('Rupiah'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Terakhir 30 Hari • Rupiah'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('grafik tidak overflow pada text scale 2', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AdvancedChartWidget(pemakaianList: [_pemakaianHariIni()]),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
