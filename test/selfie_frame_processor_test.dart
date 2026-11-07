import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';
import 'package:hindatech_kyc/src/features/selfie_capture/data/models/selfie_frame_models.dart';
import 'package:hindatech_kyc/src/features/selfie_capture/domain/models/active_guidance.dart';
import 'package:hindatech_kyc/src/features/selfie_capture/domain/models/face_alignment.dart';
import 'package:hindatech_kyc/src/features/selfie_capture/domain/services/active_guidance_service.dart';
import 'package:hindatech_kyc/src/features/selfie_capture/presentation/controllers/selfie_capture_runtime_controller.dart';
import 'package:hindatech_kyc/src/features/selfie_capture/presentation/controllers/selfie_frame_processor.dart';

void main() {
  test('discards analysis completed after route deactivation', () async {
    final setup = _setup();
    final completer = Completer<SelfieFrameAnalysis?>();
    final processing = setup.processor.process(() => completer.future);

    setup.processor.updateActivity(
      const SelfieRuntimeActivity(routeActive: false, appActive: true),
    );
    completer.complete(_analysis());

    expect(await processing, isNull);
    expect(
      setup.guidance.state.phase,
      ActiveGuidancePhase.awaitingAlignment,
    );
  });

  test('feeds current frame analysis into policy guidance', () async {
    final setup = _setup();

    final result = await setup.processor.process(() async => _analysis());

    expect(result, isNotNull);
    expect(
      result?.guidance.activeChallenge,
      VerificationLivenessChallenge.blink,
    );
    expect(
      result?.guidance.phase,
      ActiveGuidancePhase.performingChallenge,
    );
  });

  test('releases the frame ticket when analysis fails', () async {
    final setup = _setup();

    await expectLater(
      setup.processor.process(() async => throw StateError('analysis failed')),
      throwsStateError,
    );

    expect(setup.runtime.isProcessingFrame, isFalse);
  });
}

({
  SelfieFrameProcessor processor,
  SelfieCaptureRuntimeController runtime,
  ActiveGuidanceService guidance,
}) _setup() {
  final runtime = SelfieCaptureRuntimeController(
    config: SelfieCaptureConfig(
      resolution: SelfieCaptureResolution.medium,
      initialFrameStride: 1,
      minFrameStride: 1,
      maxFrameStride: 2,
      strideAdjustmentWindow: 2,
      increaseStrideInferenceMs: 80,
      decreaseStrideInferenceMs: 30,
      cameraStartupTimeout: const Duration(seconds: 10),
      slowStartupThreshold: const Duration(seconds: 1),
      routeInactivityHandling: SelfieRouteInactivityHandling.pauseStream,
    ),
  );
  final guidance = ActiveGuidanceService(
    config: ActiveGuidanceConfig(policy: _policy()),
  );
  final processor = SelfieFrameProcessor(
    config: SelfieFrameProcessorConfig(
      runtime: runtime,
      guidance: guidance,
    ),
  );
  return (processor: processor, runtime: runtime, guidance: guidance);
}

VerificationLivenessPolicy _policy() {
  return VerificationLivenessPolicy.fromJson({
    'version': '1',
    'mode': 'passive_with_active_guidance',
    'decisionAuthority': 'backend',
    'activeGuidanceRole': 'guidance_only',
    'challengeCount': 1,
    'allowedChallenges': ['blink'],
    'randomize': false,
    'challengeTimeoutMs': 15000,
    'alignmentStabilityFrames': 1,
    'requireSingleFace': true,
    'requireNeutralPose': true,
    'requireReturnToNeutral': true,
    'temporalEvidenceSupported': false,
  });
}

SelfieFrameAnalysis _analysis() {
  const bounds = Rect.fromLTRB(100, 100, 300, 500);
  return SelfieFrameAnalysis(
    faces: const [
      MappedFaceObservation(
        geometry: DetectedFaceGeometry(
          bounds: bounds,
          yawDegrees: 0,
          pitchDegrees: 0,
          rollDegrees: 0,
        ),
        leftEyeOpenProbability: 0.9,
        rightEyeOpenProbability: 0.9,
        trackingId: 1,
      ),
    ],
    alignment: const StableFaceAlignment(
      assessment: FaceAlignmentAssessment(
        signal: FaceAlignmentSignal.aligned,
        faceBounds: bounds,
      ),
      consecutiveAlignedFrames: 1,
      isStable: true,
    ),
  );
}
