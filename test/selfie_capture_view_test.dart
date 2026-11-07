import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';

void main() {
  testWidgets('renders customer copy without starting the camera',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SelfieCaptureView(
          policy: _policy(),
          autoInitialize: false,
          strings: const SelfieCaptureStrings(
            title: 'Verify your face',
            instruction: 'Follow the secure prompts.',
            startingCameraMessage: 'Preparing preview...',
          ),
          onCompleted: (_) {},
        ),
      ),
    );

    expect(find.text('Verify your face'), findsOneWidget);
    expect(find.text('Follow the secure prompts.'), findsOneWidget);
    expect(find.text('Preparing preview...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('invokes the optional cancel callback', (tester) async {
    var cancelled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SelfieCaptureView(
          policy: _policy(),
          autoInitialize: false,
          onCancel: () => cancelled = true,
          onCompleted: (_) {},
        ),
      ),
    );

    await tester.tap(find.text('Cancel'));
    expect(cancelled, isTrue);
  });

  testWidgets('renders and animates the responsive oval', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 360,
          height: 640,
          child: SelfieCaptureOverlay(
            state: SelfieCaptureOverlayState.guiding,
            progress: 0.5,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  test('accepts detailed customer-facing guidance copy', () {
    const strings = SelfieCaptureStrings(
      moveCloserMessage: 'Custom closer message',
    );

    expect(strings.moveCloserMessage, 'Custom closer message');
  });

  test('selfie result deletes its local file safely', () async {
    final directory = await Directory.systemTemp.createTemp('selfie_result_');
    final file = File('${directory.path}${Platform.pathSeparator}selfie.jpg');
    await file.writeAsBytes([1, 2, 3]);
    final result = SelfieCaptureResult(path: file.path);

    await result.deleteLocalFile();
    await result.deleteLocalFile();

    expect(await file.exists(), isFalse);
    await directory.delete();
  });
}

VerificationLivenessPolicy _policy() {
  return VerificationLivenessPolicy(
    version: '1',
    modeValue: 'passive_with_active_guidance',
    decisionAuthorityValue: 'backend',
    activeGuidanceRoleValue: 'guidance_only',
    challengeCount: 1,
    allowedChallengeValues: const ['blink'],
    randomize: false,
    challengeTimeout: const Duration(seconds: 5),
    alignmentStabilityFrames: 3,
    requireSingleFace: true,
    requireNeutralPose: true,
    requireReturnToNeutral: true,
    temporalEvidenceSupported: false,
  );
}
