import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icteach/register.dart';

void main() {
  for (final width in [360.0, 1280.0]) {
    testWidgets('LRN validation is available at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));
      expect(find.text('Learning Reference Number (LRN)'), findsOneWidget);
      expect(find.text('Verify LRN'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
