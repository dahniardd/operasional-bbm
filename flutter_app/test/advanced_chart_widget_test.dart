import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:operasional_bbm/models/jenis_bbm_usage.dart';
import 'package:operasional_bbm/widgets/advanced_chart_widget.dart';

JenisBbmUsage _usage(
  String jenis,
  String label, {
  required double liter,
  required double jumlah,
  int transaksi = 1,
}) {
  return JenisBbmUsage(
    jenisBbm: jenis,
    label: label,
    liter: liter,
    jumlah: jumlah,
    transaksi: transaksi,
  );
}

Future<List<JenisBbmUsage>> _defaultLoader(
  DateTime dari,
  DateTime sampai,
) async {
  return [
    _usage('pertamax', 'Pertamax', liter: 10, jumlah: 100000),
    _usage('solar', 'Solar', liter: 5, jumlah: 50000),
  ];
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('id_ID');
  });

  testWidgets('menampilkan empty state saat rentang tidak punya data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: AdvancedChartWidget(
              loader: (_, _) async => const <JenisBbmUsage>[],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Grafik Pemakaian BBM'), findsOneWidget);
    expect(find.text('Belum ada data pada rentang ini'), findsOneWidget);
    expect(find.text('Liter'), findsOneWidget);
    expect(find.text('Rupiah'), findsOneWidget);
  });

  testWidgets('menampilkan grafik per jenis BBM dan toggle metrik', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: AdvancedChartWidget(loader: _defaultLoader),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dari'), findsOneWidget);
    expect(find.text('Sampai'), findsOneWidget);
    expect(find.text('Pertamax'), findsOneWidget);
    expect(find.text('Solar'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('5.0'), findsOneWidget);
    expect(find.textContaining('• Liter'), findsOneWidget);

    await tester.tap(find.text('Rupiah'));
    await tester.pumpAndSettle();

    expect(find.textContaining('• Rupiah'), findsOneWidget);
    expect(find.text('100rb'), findsOneWidget);
    expect(find.text('50rb'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('menampilkan semua jenis BBM walau nilainya 0', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: AdvancedChartWidget(
              loader: (_, _) async => [
                _usage('pertamax', 'Pertamax', liter: 10, jumlah: 100000),
                _usage('pertadex', 'Pertadex', liter: 4, jumlah: 40000),
                _usage(
                  'dexlite',
                  'Dexlite',
                  liter: 0,
                  jumlah: 0,
                  transaksi: 0,
                ),
                _usage(
                  'pertamax_turbo',
                  'Pertamax Turbo',
                  liter: 0,
                  jumlah: 0,
                  transaksi: 0,
                ),
                _usage('solar', 'Solar', liter: 0, jumlah: 0, transaksi: 0),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pertamax'), findsOneWidget);
    expect(find.text('Pertadex'), findsOneWidget);
    expect(find.text('Dexlite'), findsOneWidget);
    expect(find.text('P. Turbo'), findsOneWidget);
    expect(find.text('Solar'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(3));
    expect(find.text('Belum ada data pada rentang ini'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tanggal Dari dan Sampai tampil dan membuka kalender', (
    tester,
  ) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: AdvancedChartWidget(loader: _defaultLoader),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final formatter = DateFormat('d MMM yyyy', 'id_ID');
    expect(find.text(formatter.format(start)), findsOneWidget);
    expect(
      find.text(formatter.format(DateUtils.dateOnly(now))),
      findsOneWidget,
    );

    await tester.tap(find.text('Dari'));
    await tester.pumpAndSettle();

    expect(find.byType(CalendarDatePicker), findsOneWidget);
    expect(find.text('Pilih Tanggal'), findsWidgets);
  });

  testWidgets('memuat ulang saat refresh signal berubah', (tester) async {
    var loadCount = 0;

    Future<List<JenisBbmUsage>> loader(DateTime dari, DateTime sampai) async {
      loadCount++;
      return _defaultLoader(dari, sampai);
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: AdvancedChartWidget(loader: loader),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(loadCount, 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: AdvancedChartWidget(loader: loader, refreshSignal: 1),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(loadCount, 2);
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
              child: AdvancedChartWidget(
                loader: (_, _) async => [
                  _usage('pertamax', 'Pertamax', liter: 1250, jumlah: 15000000),
                  _usage('pertadex', 'Pertadex', liter: 980, jumlah: 12000000),
                  _usage('dexlite', 'Dexlite', liter: 640, jumlah: 8000000),
                  _usage(
                    'pertamax_turbo',
                    'Pertamax Turbo',
                    liter: 320,
                    jumlah: 5000000,
                  ),
                  _usage('solar', 'Solar', liter: 125, jumlah: 1500000),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
