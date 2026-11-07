import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';
import 'package:hindatech_kyc/src/features/selfie_capture/domain/models/active_guidance.dart';
import 'package:hindatech_kyc/src/features/selfie_capture/domain/models/face_alignment.dart';
import 'package:hindatech_kyc/src/features/selfie_capture/domain/services/active_guidance_service.dart';

void main() {
  group('ActiveGuidanceService', () {
    test('uses the policy sequence and requires return to neutral', () {
      var now = DateTime.utc(2026, 1, 1);
      final service = ActiveGuidanceService(
        config: ActiveGuidanceConfig(policy: _policy()),
        clock: () => now,
      );

      var state = service.evaluate(_frame(eyes: 0.9));
      expect(state.activeChallenge, VerificationLivenessChallenge.blink);
      expect(state.challengeDeadline, now.add(const Duration(seconds: 15)));

      state = service.evaluate(_frame(eyes: 0.9));
      expect(state.signal, ActiveGuidanceSignal.blink);

      state = service.evaluate(_frame(eyes: 0.1));
      expect(state.phase, ActiveGuidancePhase.returningToNeutral);
      expect(state.completedChallengeCount, 0);

      state = service.evaluate(_frame(eyes: 0.9));
      expect(state.activeChallenge, VerificationLivenessChallenge.turnLeft);
      expect(state.completedChallengeCount, 1);

      state = service.evaluate(
        _frame(yaw: -22, alignmentSignal: FaceAlignmentSignal.lookStraight),
      );
      expect(state.phase, ActiveGuidancePhase.returningToNeutral);

      state = service.evaluate(_frame(yaw: 0, stable: false));
      expect(state.phase, ActiveGuidancePhase.returningToNeutral);
      expect(state.completedChallengeCount, 1);

      state = service.evaluate(_frame(yaw: 0));
      expect(state.phase, ActiveGuidancePhase.awaitingCaptureAlignment);
      expect(state.completedChallengeCount, 2);
      expect(state.suggestsCapture, isFalse);

      state = service.evaluate(_frame(yaw: 0));
      expect(state.phase, ActiveGuidancePhase.captureSuggested);
      expect(state.suggestsCapture, isTrue);
      expect(state.progress, 1);
    });

    test('does not start the challenge timeout before stable alignment', () {
      var now = DateTime.utc(2026, 1, 1);
      final service = ActiveGuidanceService(
        config: ActiveGuidanceConfig(policy: _policy()),
        clock: () => now,
      );

      var state = service.evaluate(
        _frame(
          eyes: 0.9,
          stable: false,
          alignmentSignal: FaceAlignmentSignal.moveCloser,
        ),
      );
      expect(state.phase, ActiveGuidancePhase.awaitingAlignment);
      expect(state.challengeDeadline, isNull);

      now = now.add(const Duration(minutes: 1));
      state = service.checkTimeout();
      expect(state.hasTimedOut, isFalse);
    });

    test('times out the active challenge at the backend deadline', () {
      var now = DateTime.utc(2026, 1, 1);
      final service = ActiveGuidanceService(
        config: ActiveGuidanceConfig(policy: _policy()),
        clock: () => now,
      );
      service.evaluate(_frame(eyes: 0.9));

      now = now.add(const Duration(seconds: 15));
      final state = service.checkTimeout();

      expect(state.phase, ActiveGuidancePhase.timedOut);
      expect(state.signal, ActiveGuidanceSignal.timedOut);
      expect(state.hasTimedOut, isTrue);
      expect(state.suggestsCapture, isFalse);
    });

    test('keeps the challenge deadline while returning to neutral', () {
      var now = DateTime.utc(2026, 1, 1);
      final service = ActiveGuidanceService(
        config: ActiveGuidanceConfig(
          policy: _policy(challenges: const ['blink'], challengeCount: 1),
        ),
        clock: () => now,
      );
      service.evaluate(_frame(eyes: 0.9));
      service.evaluate(_frame(eyes: 0.9));
      service.evaluate(_frame(eyes: 0.1));

      now = now.add(const Duration(seconds: 15));
      final state = service.checkTimeout();

      expect(state.phase, ActiveGuidancePhase.timedOut);
      expect(state.completedChallengeCount, 0);
    });

    test('enforces the backend single-face requirement during guidance', () {
      final service = ActiveGuidanceService(
        config: ActiveGuidanceConfig(policy: _policy()),
      );

      final state = service.evaluate(
        _frame(
          eyes: 0.9,
          faceCount: 2,
          alignmentSignal: FaceAlignmentSignal.multipleFaces,
        ),
      );

      expect(state.phase, ActiveGuidancePhase.awaitingAlignment);
      expect(state.signal, ActiveGuidanceSignal.alignFace);
      expect(state.alignmentSignal, FaceAlignmentSignal.multipleFaces);
    });

    test('requires an observed head angle to complete a turn', () {
      final service = ActiveGuidanceService(
        config: ActiveGuidanceConfig(
          policy: _policy(
            challenges: const ['turn_right'],
            challengeCount: 1,
            requireReturnToNeutral: false,
          ),
        ),
      );
      service.evaluate(_frame());

      final state = service.evaluate(
        _frame(alignmentSignal: FaceAlignmentSignal.holdStill),
      );

      expect(state.signal, ActiveGuidanceSignal.faceNotClear);
      expect(state.completedChallengeCount, 0);
    });

    test('can advance immediately when neutral return is not required', () {
      final service = ActiveGuidanceService(
        config: ActiveGuidanceConfig(
          policy: _policy(
            challenges: const ['turn_right'],
            challengeCount: 1,
            requireReturnToNeutral: false,
          ),
        ),
      );
      service.evaluate(_frame(yaw: 0));

      final state = service.evaluate(
        _frame(yaw: 22, alignmentSignal: FaceAlignmentSignal.lookStraight),
      );

      expect(state.phase, ActiveGuidancePhase.awaitingCaptureAlignment);
      expect(state.completedChallengeCount, 1);
      expect(state.suggestsCapture, isFalse);
    });

    test('resets blink priming when the tracked face changes', () {
      final service = ActiveGuidanceService(
        config: ActiveGuidanceConfig(policy: _policy()),
      );
      service.evaluate(_frame(eyes: 0.9, trackingId: 1));
      service.evaluate(_frame(eyes: 0.9, trackingId: 1));

      final state = service.evaluate(_frame(eyes: 0.1, trackingId: 2));

      expect(state.phase, ActiveGuidancePhase.performingChallenge);
      expect(state.completedChallengeCount, 0);
    });

    test('rejects policies that could imply a local decision', () {
      expect(
        () => ActiveGuidanceService(
          config: ActiveGuidanceConfig(
            policy: _policy(activeGuidanceRole: 'authoritative'),
          ),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => ActiveGuidanceService(
          config: ActiveGuidanceConfig(
            policy: _policy(decisionAuthority: 'sdk'),
          ),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => ActiveGuidanceService(
          config: ActiveGuidanceConfig(
            policy: _policy(mode: 'future_mode'),
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });
}

VerificationLivenessPolicy _policy({
  List<String> challenges = const ['blink', 'turn_left'],
  int challengeCount = 2,
  bool requireReturnToNeutral = true,
  String activeGuidanceRole = 'guidance_only',
  String decisionAuthority = 'backend',
  String mode = 'passive_with_active_guidance',
}) {
  return VerificationLivenessPolicy.fromJson({
    'version': '1',
    'mode': mode,
    'decisionAuthority': decisionAuthority,
    'activeGuidanceRole': activeGuidanceRole,
    'challengeCount': challengeCount,
    'allowedChallenges': challenges,
    'randomize': false,
    'challengeTimeoutMs': 15000,
    'alignmentStabilityFrames': 5,
    'requireSingleFace': true,
    'requireNeutralPose': true,
    'requireReturnToNeutral': requireReturnToNeutral,
    'temporalEvidenceSupported': false,
  });
}

ActiveGuidanceFrame _frame({
  double? yaw,
  double? eyes,
  int trackingId = 1,
  int faceCount = 1,
  bool stable = true,
  FaceAlignmentSignal alignmentSignal = FaceAlignmentSignal.aligned,
}) {
  const bounds = Rect.fromLTRB(100, 100, 300, 500);
  return ActiveGuidanceFrame(
    faceCount: faceCount,
    primaryFace: ActiveGuidanceFace(
      yawDegrees: yaw,
      leftEyeOpenProbability: eyes,
      rightEyeOpenProbability: eyes,
      trackingId: trackingId,
    ),
    alignment: StableFaceAlignment(
      assessment: FaceAlignmentAssessment(
        signal: alignmentSignal,
        faceBounds: bounds,
      ),
      consecutiveAlignedFrames: stable ? 5 : 1,
      isStable: stable,
    ),
  );
}
