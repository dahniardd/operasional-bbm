import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:operasional_bbm/config/design_tokens.dart';
import 'package:operasional_bbm/widgets/advanced_stat_card.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('kartu biaya memakai warna tren dan nilai yang benar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 160,
            height: 136,
            child: AdvancedStatCard(
              label: 'Pengeluaran Bulan Ini',
              value: 'Rp 1.000',
              subtitle: '2 transaksi',
              icon: Icons.receipt_long,
              primaryColor: AppTokens.accent,
              valueColor: AppTokens.warningText,
              backgroundColor: const Color(0xFFFEF3E2),
              change: 5,
              isPositive: true,
              positiveIsGood: false,
              badTrendColor: AppTokens.warning,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    final valueText = tester.widget<Text>(find.text('Rp 1.000'));
    expect(valueText.style?.color, AppTokens.warningText);

    final changeText = tester.widget<Text>(find.text('5.0%'));
    expect(changeText.style?.color, AppTokens.warning);
  });

  testWidgets('kartu tidak overflow pada text scale 2', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: Scaffold(
            body: SizedBox(
              width: 150,
              height: 224,
              child: AdvancedStatCard(
                label: 'Pengeluaran Hari Ini',
                value: 'Rp 1.234.567',
                icon: Icons.attach_money,
                primaryColor: AppTokens.brand,
                backgroundColor: const Color(0xFFE8F4FF),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
