import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';

void main() {
  testWidgets('renders the document frame', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 400,
          height: 600,
          child: DocumentCaptureOverlay(),
        ),
      ),
    );

    final overlayPaint = find.descendant(
      of: find.byType(DocumentCaptureOverlay),
      matching: find.byType(CustomPaint),
    );
    expect(overlayPaint, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides the painter when requested', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DocumentCaptureOverlay(visible: false)),
    );

    final overlayPaint = find.descendant(
      of: find.byType(DocumentCaptureOverlay),
      matching: find.byType(CustomPaint),
    );
    expect(overlayPaint, findsNothing);
    expect(find.byType(SizedBox), findsWidgets);
  });

  testWidgets('accepts customer styling', (tester) async {
    const style = DocumentCaptureOverlayStyle(
      overlayColor: Color(0xAA101010),
      borderColor: Colors.blue,
      borderRadius: 20,
    );

    await tester.pumpWidget(
      const MaterialApp(home: DocumentCaptureOverlay(style: style)),
    );

    final overlay = tester.widget<DocumentCaptureOverlay>(
      find.byType(DocumentCaptureOverlay),
    );
    expect(overlay.style.borderColor, Colors.blue);
    expect(overlay.style.borderRadius, 20);
  });
}
