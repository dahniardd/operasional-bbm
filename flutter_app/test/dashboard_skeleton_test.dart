import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operasional_bbm/widgets/dashboard_skeleton.dart';

void main() {
  for (final width in <double>[320, 430, 1024]) {
    testWidgets('skeleton tidak overflow pada lebar $width', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DashboardSkeleton())),
      );

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('skeleton tidak overflow pada text scale 2', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: Scaffold(body: DashboardSkeleton()),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
