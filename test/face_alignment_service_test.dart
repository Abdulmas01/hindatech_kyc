import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';
import 'package:hindatech_kyc/src/features/selfie_capture/domain/models/face_alignment.dart';
import 'package:hindatech_kyc/src/features/selfie_capture/domain/services/face_alignment_service.dart';

import 'fixtures/sdk_bootstrap_payload.dart';

void main() {
  const guide = Rect.fromLTRB(50, 100, 350, 600);
  const alignedFace = DetectedFaceGeometry(
    bounds: Rect.fromLTRB(120, 200, 280, 500),
    yawDegrees: 0,
    pitchDegrees: 0,
    rollDegrees: 0,
  );
  const service = FaceAlignmentService();

  test('reports a centered, correctly sized neutral face as aligned', () {
    final result = service.evaluate(
      FaceAlignmentRequest(
        faces: const [alignedFace],
        guideRect: guide,
        requireSingleFace: true,
        requireNeutralPose: true,
      ),
    );

    expect(result.signal, FaceAlignmentSignal.aligned);
    expect(result.isAligned, isTrue);
  });

  test('enforces the backend single-face requirement', () {
    final result = service.evaluate(
      FaceAlignmentRequest(
        faces: const [alignedFace, alignedFace],
        guideRect: guide,
        requireSingleFace: true,
        requireNeutralPose: false,
      ),
    );

    expect(result.signal, FaceAlignmentSignal.multipleFaces);
  });

  test('provides directional and distance guidance against the oval', () {
    FaceAlignmentSignal evaluate(Rect bounds) => service
        .evaluate(
          FaceAlignmentRequest(
            faces: [DetectedFaceGeometry(bounds: bounds)],
            guideRect: guide,
            requireSingleFace: true,
            requireNeutralPose: false,
          ),
        )
        .signal;

    expect(
      evaluate(const Rect.fromLTRB(20, 200, 140, 500)),
      FaceAlignmentSignal.moveRight,
    );
    expect(
      evaluate(const Rect.fromLTRB(260, 200, 380, 500)),
      FaceAlignmentSignal.moveLeft,
    );
    expect(
      evaluate(const Rect.fromLTRB(160, 285, 240, 415)),
      FaceAlignmentSignal.moveCloser,
    );
    expect(
      evaluate(const Rect.fromLTRB(80, 120, 320, 580)),
      FaceAlignmentSignal.moveBack,
    );
  });

  test('requires neutral pose only when declared by the policy', () {
    final result = service.evaluate(
      FaceAlignmentRequest(
        faces: const [
          DetectedFaceGeometry(
            bounds: Rect.fromLTRB(120, 200, 280, 500),
            yawDegrees: 18,
            pitchDegrees: 0,
            rollDegrees: 0,
          ),
        ],
        guideRect: guide,
        requireSingleFace: true,
        requireNeutralPose: true,
      ),
    );

    expect(result.signal, FaceAlignmentSignal.lookStraight);
  });

  test('does not call an oversized face inside the oval aligned', () {
    final result = service.evaluate(
      FaceAlignmentRequest(
        faces: const [
          DetectedFaceGeometry(
            bounds: Rect.fromLTRB(70, 200, 330, 500),
          ),
        ],
        guideRect: guide,
        requireSingleFace: true,
        requireNeutralPose: false,
      ),
    );

    expect(result.signal, FaceAlignmentSignal.moveBack);
  });

  test('uses backend alignment stability frames before capture readiness', () {
    final policy = VerificationLivenessPolicy.fromJson(
      sdkLivenessPolicyPayload(),
    );
    final stability = FaceAlignmentStabilityService();
    const assessment = FaceAlignmentAssessment(
      signal: FaceAlignmentSignal.aligned,
      faceBounds: Rect.fromLTRB(120, 200, 280, 500),
    );

    for (var frame = 1; frame < policy.alignmentStabilityFrames; frame++) {
      final guidance = stability.evaluate(
        assessment: assessment,
        stabilityFrames: policy.alignmentStabilityFrames,
      );
      expect(guidance.suggestsCaptureReady, isFalse);
    }
    final stable = stability.evaluate(
      assessment: assessment,
      stabilityFrames: policy.alignmentStabilityFrames,
    );

    expect(stable.consecutiveAlignedFrames, 5);
    expect(stable.suggestsCaptureReady, isTrue);
  });

  test('resets alignment stability when guidance is lost', () {
    final stability = FaceAlignmentStabilityService();
    const aligned = FaceAlignmentAssessment(
      signal: FaceAlignmentSignal.aligned,
      faceBounds: Rect.fromLTRB(120, 200, 280, 500),
    );
    const missing = FaceAlignmentAssessment(
      signal: FaceAlignmentSignal.noFace,
      faceBounds: null,
    );

    stability.evaluate(assessment: aligned, stabilityFrames: 2);
    final reset = stability.evaluate(assessment: missing, stabilityFrames: 2);

    expect(reset.consecutiveAlignedFrames, 0);
    expect(reset.suggestsCaptureReady, isFalse);
  });

  test('policy coordinator consumes face and stability requirements', () {
    final policy = VerificationLivenessPolicy.fromJson(
      sdkLivenessPolicyPayload(),
    );
    final coordinator = PolicyFaceAlignmentService();
    late StableFaceAlignment result;

    for (var frame = 0; frame < policy.alignmentStabilityFrames; frame++) {
      result = coordinator.evaluate(
        PolicyFaceAlignmentRequest(
          faces: const [alignedFace],
          guideRect: guide,
          policy: policy,
        ),
      );
    }

    expect(result.suggestsCaptureReady, isTrue);
  });
}
