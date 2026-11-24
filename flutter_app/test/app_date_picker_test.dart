import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:operasional_bbm/widgets/app_date_picker.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('id_ID');
  });

  Widget buildApp({
    required ValueChanged<DateTime?> onResult,
    required DateTime initialDate,
    DateTime? lastDate,
    double textScale = 1,
  }) {
    return MaterialApp(
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                final result = await showAppDatePicker(
                  context,
                  initialDate: initialDate,
                  firstDate: DateTime(2020),
                  lastDate: lastDate ?? DateTime(2100),
                );
                onResult(result);
              },
              child: const Text('Buka'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openPicker(WidgetTester tester) async {
    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();
  }

  testWidgets('menampilkan kalender dan shortcut tanggal', (tester) async {
    final today = DateUtils.dateOnly(DateTime.now());

    await tester.pumpWidget(
      buildApp(onResult: (_) {}, initialDate: today, lastDate: today),
    );
    await openPicker(tester);

    expect(find.byType(CalendarDatePicker), findsOneWidget);
    expect(find.text('Pilih Tanggal'), findsWidgets);
    expect(find.text('Hari ini'), findsOneWidget);
    expect(find.text('Kemarin'), findsOneWidget);
  });

  testWidgets('shortcut Hari ini mengembalikan tanggal hari ini', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    DateTime? result;

    await tester.pumpWidget(
      buildApp(
        onResult: (value) => result = value,
        initialDate: today,
        lastDate: today,
      ),
    );
    await openPicker(tester);

    await tester.tap(find.text('Hari ini'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(DateUtils.isSameDay(result, today), isTrue);
  });

  testWidgets('tombol Batal mengembalikan null', (tester) async {
    final today = DateUtils.dateOnly(DateTime.now());
    DateTime? result;

    await tester.pumpWidget(
      buildApp(
        onResult: (value) => result = value,
        initialDate: today,
        lastDate: today,
      ),
    );
    await openPicker(tester);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });

  testWidgets('tombol Pilih Tanggal mengembalikan tanggal terpilih', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final initial = today.subtract(const Duration(days: 5));
    DateTime? result;

    await tester.pumpWidget(
      buildApp(
        onResult: (value) => result = value,
        initialDate: initial,
        lastDate: today,
      ),
    );
    await openPicker(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Pilih Tanggal'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(DateUtils.isSameDay(result, initial), isTrue);
  });

  testWidgets('tidak overflow di lebar 320 dengan text scale 2', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final today = DateUtils.dateOnly(DateTime.now());

    await tester.pumpWidget(
      buildApp(
        onResult: (_) {},
        initialDate: today,
        lastDate: today,
        textScale: 2,
      ),
    );
    await openPicker(tester);

    expect(tester.takeException(), isNull);
  });
}
