import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:operasional_bbm/widgets/custom_bottom_nav.dart';

Finder _navItem(String label) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == label,
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  for (final width in <double>[320, 360, 393, 430]) {
    testWidgets('navbar tidak overflow pada lebar $width', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      int tapped = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: CustomBottomNav(
              currentIndex: 0,
              onTap: (index) => tapped = index,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(Icons.local_gas_station_rounded));
      expect(tapped, 1);

      await tester.tap(find.text('Riwayat'));
      expect(tapped, 2);

      await tester.tap(find.text('Dashboard'));
      expect(tapped, 0);
    });
  }

  testWidgets('tab aktif mengikuti currentIndex, tombol tengah bukan tab', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: CustomBottomNav(currentIndex: 2, onTap: (_) {}),
        ),
      ),
    );

    final dashboard = tester.getSemantics(_navItem('Dashboard'));
    final riwayat = tester.getSemantics(_navItem('Riwayat'));
    final input = tester.getSemantics(_navItem('Input'));

    expect(dashboard.flagsCollection.isSelected, Tristate.isFalse);
    expect(riwayat.flagsCollection.isSelected, Tristate.isTrue);
    expect(input.flagsCollection.isSelected, Tristate.isFalse);

    handle.dispose();
  });

  testWidgets('tombol tengah punya hit target minimal 48dp', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: CustomBottomNav(currentIndex: 0, onTap: (_) {}),
        ),
      ),
    );

    final size = tester.getSize(_navItem('Input'));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));

    handle.dispose();
  });

  testWidgets('navbar tidak overflow saat currentIndex 2 di lebar 320', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: CustomBottomNav(currentIndex: 2, onTap: (_) {}),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
