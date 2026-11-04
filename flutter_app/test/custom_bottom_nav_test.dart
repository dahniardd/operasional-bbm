import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:operasional_bbm/widgets/custom_bottom_nav.dart';

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

      await tester.tap(find.text('Input'));
      expect(tapped, 1);

      await tester.tap(find.text('Riwayat'));
      expect(tapped, 2);

      await tester.tap(find.text('Dashboard'));
      expect(tapped, 0);
    });
  }
}
