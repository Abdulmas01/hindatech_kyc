import 'dart:ui';

import '../../../../session/verification_liveness_policy.dart';

enum FaceAlignmentSignal {
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

class DetectedFaceGeometry {
  const DetectedFaceGeometry({
    required this.bounds,
    this.yawDegrees,
    this.pitchDegrees,
    this.rollDegrees,
  });

  final Rect bounds;
  final double? yawDegrees;
  final double? pitchDegrees;
  final double? rollDegrees;
}

class FaceAlignmentConfig {
  const FaceAlignmentConfig({
    this.minimumFaceHeightFactor = 0.48,
    this.maximumFaceHeightFactor = 0.88,
    this.minimumFaceWidthFactor = 0.36,
    this.maximumFaceWidthFactor = 0.78,
    this.horizontalCenterTolerance = 0.14,
    this.verticalCenterTolerance = 0.12,
    this.neutralYawDegrees = 10,
    this.neutralPitchDegrees = 10,
    this.neutralRollDegrees = 12,
  })  : assert(minimumFaceHeightFactor > 0),
        assert(maximumFaceHeightFactor > minimumFaceHeightFactor),
        assert(minimumFaceWidthFactor > 0),
        assert(maximumFaceWidthFactor > minimumFaceWidthFactor),
        assert(horizontalCenterTolerance > 0),
        assert(verticalCenterTolerance > 0),
        assert(neutralYawDegrees >= 0),
        assert(neutralPitchDegrees >= 0),
        assert(neutralRollDegrees >= 0);

  final double minimumFaceHeightFactor;
  final double maximumFaceHeightFactor;
  final double minimumFaceWidthFactor;
  final double maximumFaceWidthFactor;
  final double horizontalCenterTolerance;
  final double verticalCenterTolerance;
  final double neutralYawDegrees;
  final double neutralPitchDegrees;
  final double neutralRollDegrees;
}

class PolicyFaceAlignmentRequest {
  PolicyFaceAlignmentRequest({
    required List<DetectedFaceGeometry> faces,
    required this.guideRect,
    required this.policy,
  }) : faces = List.unmodifiable(faces);

  final List<DetectedFaceGeometry> faces;
  final Rect guideRect;
  final VerificationLivenessPolicy policy;
}

class FaceAlignmentRequest {
  FaceAlignmentRequest({
    required List<DetectedFaceGeometry> faces,
    required this.guideRect,
    required this.requireSingleFace,
    required this.requireNeutralPose,
  }) : faces = List.unmodifiable(faces);

  final List<DetectedFaceGeometry> faces;
  final Rect guideRect;
  final bool requireSingleFace;
  final bool requireNeutralPose;
}

/// Device-local framing guidance. This is never a liveness result.
class FaceAlignmentAssessment {
  const FaceAlignmentAssessment({
    required this.signal,
    required this.faceBounds,
  });

  final FaceAlignmentSignal signal;
  final Rect? faceBounds;

  bool get isAligned => signal == FaceAlignmentSignal.aligned;
}

class StableFaceAlignment {
  const StableFaceAlignment({
    required this.assessment,
    required this.consecutiveAlignedFrames,
    required this.isStable,
  });

  final FaceAlignmentAssessment assessment;
  final int consecutiveAlignedFrames;
  final bool isStable;

  /// Capture readiness only. Backend processing owns the liveness decision.
  bool get suggestsCaptureReady => assessment.isAligned && isStable;
}
