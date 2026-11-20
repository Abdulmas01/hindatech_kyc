import 'dart:async';

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
          qualityPolicy: null,
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
          qualityPolicy: null,
          onCancel: () => cancelled = true,
          onCompleted: (_) {},
        ),
      ),
    );

    await tester.tap(find.text('Cancel'));
    expect(cancelled, isTrue);
  });

  testWidgets('applies backend confidence and stability policy to guidance',
      (tester) async {
    final assessments = StreamController<DocumentQualityAssessment>();
    addTearDown(assessments.close);
    await tester.pumpWidget(
      MaterialApp(
        home: DocumentCaptureView(
          autoInitialize: false,
          qualityPolicy: _qualityPolicy(stabilityFrames: 2),
          qualityAssessments: assessments.stream,
          onCompleted: (_) {},
        ),
      ),
    );

    assessments.add(_goodAssessment(0.69));
    await tester.pump();
    expect(find.text('Hold steady for capture.'), findsNothing);

    assessments.add(_goodAssessment(0.8));
    await tester.pump();
    expect(find.text('Hold steady for capture.'), findsNothing);

    assessments.add(_goodAssessment(0.8));
    await tester.pump();
    expect(find.text('Hold steady for capture.'), findsOneWidget);
  });
}

VerificationDocumentQualityPolicy _qualityPolicy({
  required int stabilityFrames,
}) {
  return VerificationDocumentQualityPolicy(
    version: 'test-v1',
    modeValue: 'guidance_only',
    decisionAuthorityValue: 'backend',
    localInferenceEnabled: true,
    autoCaptureAllowed: false,
    stabilityFrames: stabilityFrames,
    samplingInterval: const Duration(milliseconds: 250),
    supportedSignalValues: const ['good'],
    minimumConfidenceBySignal: const {'good': 0.7},
  );
}

DocumentQualityAssessment _goodAssessment(double confidence) {
  return DocumentQualityAssessment(
    signal: DocumentQualitySignal.good,
    confidence: confidence,
    source: DocumentQualitySource.onDeviceInference,
  );
}
