import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';

void main() {
  testWidgets('shows customer copy for stable glare guidance', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DocumentQualityGuidanceBanner(
            signal: DocumentQualitySignal.glare,
            isStable: true,
            strings: DocumentCaptureStrings(
              qualityGlareMessage: 'Move away from direct light.',
            ),
            captureTheme: DocumentCaptureTheme(),
          ),
        ),
      ),
    );

    expect(find.text('Move away from direct light.'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });

  testWidgets('does not present an unstable signal as capture-ready',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DocumentQualityGuidanceBanner(
            signal: DocumentQualitySignal.good,
            isStable: false,
            strings: DocumentCaptureStrings(
              qualityEvaluatingMessage: 'Checking...',
            ),
            captureTheme: DocumentCaptureTheme(),
          ),
        ),
      ),
    );

    expect(find.text('Checking...'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsNothing);
  });
}
