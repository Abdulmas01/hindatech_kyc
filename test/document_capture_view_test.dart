import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';

void main() {
  testWidgets('renders customer-provided copy without camera initialization',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DocumentCaptureView(
          autoInitialize: false,
          strings: const DocumentCaptureStrings(
            documentTitle: 'Scan identity card',
            documentInstruction: 'Place the card in the guide.',
          ),
          onCompleted: (_) {},
        ),
      ),
    );

    expect(find.text('Scan identity card'), findsOneWidget);
    expect(find.text('Place the card in the guide.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('invokes the optional cancel callback', (tester) async {
    var cancelled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: DocumentCaptureView(
          autoInitialize: false,
          onCancel: () => cancelled = true,
          onCompleted: (_) {},
        ),
      ),
    );

    await tester.tap(find.text('Cancel'));
    expect(cancelled, isTrue);
  });
}
