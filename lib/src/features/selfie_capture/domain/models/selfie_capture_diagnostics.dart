import '../../../../session/verification_liveness_policy.dart';

/// Device-local reason reported by the selfie alignment pipeline.
///
/// Diagnostics describe capture guidance only. They are not a liveness or
/// identity-verification result.
enum SelfieDiagnosticSignal {
  noFace,
  multipleFaces,
  moveCloser,
  moveBack,
  moveLeft,
  moveRight,
  moveUp,
  moveDown,
  lookStraight,
  holdStill,
  aligned,
}

/// Safe operational snapshot for testing and host-side troubleshooting.
class SelfieCaptureDiagnostics {
  const SelfieCaptureDiagnostics({
    required this.detectedFaceCount,
    required this.signal,
    required this.consecutiveAlignedFrames,
    required this.requiredAlignedFrames,
    required this.activeChallenge,
    required this.subjectYawDegrees,
  });

  final int detectedFaceCount;
  final SelfieDiagnosticSignal signal;
  final int consecutiveAlignedFrames;
  final int requiredAlignedFrames;
  final VerificationLivenessChallenge? activeChallenge;

  /// Subject-relative yaw: positive means the subject turned left.
  final double? subjectYawDegrees;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelfieCaptureDiagnostics &&
          detectedFaceCount == other.detectedFaceCount &&
          signal == other.signal &&
          consecutiveAlignedFrames == other.consecutiveAlignedFrames &&
          requiredAlignedFrames == other.requiredAlignedFrames &&
          activeChallenge == other.activeChallenge &&
          subjectYawDegrees == other.subjectYawDegrees;

  @override
  int get hashCode => Object.hash(
        detectedFaceCount,
        signal,
        consecutiveAlignedFrames,
        requiredAlignedFrames,
        activeChallenge,
        subjectYawDegrees,
      );
}
