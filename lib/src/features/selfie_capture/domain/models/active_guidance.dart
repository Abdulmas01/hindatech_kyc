import '../../../../session/verification_liveness_policy.dart';
import 'face_alignment.dart';

enum ActiveGuidancePhase {
  awaitingAlignment,
  performingChallenge,
  returningToNeutral,
  awaitingCaptureAlignment,
  captureSuggested,
  timedOut,
}

enum ActiveGuidanceSignal {
  alignFace,
  blink,
  turnLeft,
  turnRight,
  returnToNeutral,
  faceNotClear,
  captureSuggested,
  timedOut,
}

class ActiveGuidanceDetectionConfig {
  const ActiveGuidanceDetectionConfig({
    this.blinkClosedThreshold = 0.25,
    this.blinkOpenThreshold = 0.70,
    this.headTurnThresholdDegrees = 18,
    this.neutralYawThresholdDegrees = 8,
  })  : assert(blinkClosedThreshold >= 0 && blinkClosedThreshold <= 1),
        assert(blinkOpenThreshold >= 0 && blinkOpenThreshold <= 1),
        assert(blinkOpenThreshold > blinkClosedThreshold),
        assert(headTurnThresholdDegrees > neutralYawThresholdDegrees),
        assert(neutralYawThresholdDegrees >= 0);

  final double blinkClosedThreshold;
  final double blinkOpenThreshold;
  final double headTurnThresholdDegrees;
  final double neutralYawThresholdDegrees;
}

class ActiveGuidanceConfig {
  const ActiveGuidanceConfig({
    required this.policy,
    this.detection = const ActiveGuidanceDetectionConfig(),
  });

  final VerificationLivenessPolicy policy;
  final ActiveGuidanceDetectionConfig detection;
}

class ActiveGuidanceFace {
  const ActiveGuidanceFace({
    this.yawDegrees,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
    this.trackingId,
  });

  final double? yawDegrees;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;
  final int? trackingId;
}

class ActiveGuidanceFrame {
  const ActiveGuidanceFrame({
    required this.faceCount,
    required this.primaryFace,
    required this.alignment,
  }) : assert(faceCount >= 0);

  final int faceCount;
  final ActiveGuidanceFace? primaryFace;
  final StableFaceAlignment alignment;
}

/// Capture guidance state only. Backend processing owns the liveness decision.
class ActiveGuidanceState {
  const ActiveGuidanceState({
    required this.phase,
    required this.signal,
    required this.activeChallenge,
    required this.completedChallengeCount,
    required this.totalChallengeCount,
    required this.challengeDeadline,
    required this.alignmentSignal,
  });

  final ActiveGuidancePhase phase;
  final ActiveGuidanceSignal signal;
  final VerificationLivenessChallenge? activeChallenge;

  /// Progress for presentation only; this is not ordered temporal evidence.
  final int completedChallengeCount;
  final int totalChallengeCount;
  final DateTime? challengeDeadline;
  final FaceAlignmentSignal? alignmentSignal;

  double get progress => totalChallengeCount == 0
      ? 0
      : completedChallengeCount / totalChallengeCount;

  /// Indicates that capture may proceed, never that liveness passed.
  bool get suggestsCapture => phase == ActiveGuidancePhase.captureSuggested;

  bool get hasTimedOut => phase == ActiveGuidancePhase.timedOut;
}
