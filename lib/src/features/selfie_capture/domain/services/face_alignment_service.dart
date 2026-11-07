import 'dart:ui';

import '../models/face_alignment.dart';

class FaceAlignmentService {
  const FaceAlignmentService({
    this.config = const FaceAlignmentConfig(),
  });

  final FaceAlignmentConfig config;

  FaceAlignmentAssessment evaluate(FaceAlignmentRequest request) {
    if (request.faces.isEmpty) {
      return const FaceAlignmentAssessment(
        signal: FaceAlignmentSignal.noFace,
        faceBounds: null,
      );
    }
    if (request.requireSingleFace && request.faces.length != 1) {
      return const FaceAlignmentAssessment(
        signal: FaceAlignmentSignal.multipleFaces,
        faceBounds: null,
      );
    }

    final face = _primaryFace(request.faces, request.guideRect);
    final bounds = face.bounds;
    final guide = request.guideRect;
    final horizontalOffset = (bounds.center.dx - guide.center.dx) / guide.width;
    final verticalOffset = (bounds.center.dy - guide.center.dy) / guide.height;

    if (horizontalOffset < -config.horizontalCenterTolerance) {
      return _assessment(FaceAlignmentSignal.moveRight, bounds);
    }
    if (horizontalOffset > config.horizontalCenterTolerance) {
      return _assessment(FaceAlignmentSignal.moveLeft, bounds);
    }
    if (verticalOffset < -config.verticalCenterTolerance) {
      return _assessment(FaceAlignmentSignal.moveDown, bounds);
    }
    if (verticalOffset > config.verticalCenterTolerance) {
      return _assessment(FaceAlignmentSignal.moveUp, bounds);
    }

    final heightFactor = bounds.height / guide.height;
    final widthFactor = bounds.width / guide.width;
    if (heightFactor < config.minimumFaceHeightFactor ||
        widthFactor < config.minimumFaceWidthFactor) {
      return _assessment(FaceAlignmentSignal.moveCloser, bounds);
    }
    if (heightFactor > config.maximumFaceHeightFactor ||
        widthFactor > config.maximumFaceWidthFactor ||
        !_fitsOval(bounds, guide)) {
      return _assessment(FaceAlignmentSignal.moveBack, bounds);
    }

    if (request.requireNeutralPose) {
      if (face.yawDegrees == null ||
          face.pitchDegrees == null ||
          face.rollDegrees == null) {
        return _assessment(FaceAlignmentSignal.holdStill, bounds);
      }
      if (face.yawDegrees!.abs() > config.neutralYawDegrees ||
          face.pitchDegrees!.abs() > config.neutralPitchDegrees ||
          face.rollDegrees!.abs() > config.neutralRollDegrees) {
        return _assessment(FaceAlignmentSignal.lookStraight, bounds);
      }
    }

    return _assessment(FaceAlignmentSignal.aligned, bounds);
  }

  DetectedFaceGeometry _primaryFace(
    List<DetectedFaceGeometry> faces,
    Rect guideRect,
  ) {
    return faces.reduce((current, candidate) {
      final currentOverlap = current.bounds.intersect(guideRect);
      final candidateOverlap = candidate.bounds.intersect(guideRect);
      final currentArea = _area(currentOverlap);
      final candidateArea = _area(candidateOverlap);
      if (candidateArea != currentArea) {
        return candidateArea > currentArea ? candidate : current;
      }
      return _area(candidate.bounds) > _area(current.bounds)
          ? candidate
          : current;
    });
  }

  double _area(Rect rect) {
    if (rect.width <= 0 || rect.height <= 0) return 0;
    return rect.width * rect.height;
  }

  bool _fitsOval(Rect face, Rect guide) {
    final horizontalRadius = guide.width / 2;
    final verticalRadius = guide.height / 2;
    final points = [
      Offset(face.left, face.center.dy),
      Offset(face.right, face.center.dy),
      Offset(face.center.dx, face.top),
      Offset(face.center.dx, face.bottom),
    ];
    return points.every((point) {
      final normalizedX = (point.dx - guide.center.dx) / horizontalRadius;
      final normalizedY = (point.dy - guide.center.dy) / verticalRadius;
      return normalizedX * normalizedX + normalizedY * normalizedY <= 1;
    });
  }

  FaceAlignmentAssessment _assessment(
    FaceAlignmentSignal signal,
    Rect bounds,
  ) =>
      FaceAlignmentAssessment(signal: signal, faceBounds: bounds);
}

/// Applies the active session policy to face alignment and stability gating.
class PolicyFaceAlignmentService {
  PolicyFaceAlignmentService({
    FaceAlignmentService alignmentService = const FaceAlignmentService(),
    FaceAlignmentStabilityService? stabilityService,
  })  : _alignmentService = alignmentService,
        _stabilityService = stabilityService ?? FaceAlignmentStabilityService();

  final FaceAlignmentService _alignmentService;
  final FaceAlignmentStabilityService _stabilityService;

  StableFaceAlignment evaluate(PolicyFaceAlignmentRequest request) {
    final assessment = _alignmentService.evaluate(
      FaceAlignmentRequest(
        faces: request.faces,
        guideRect: request.guideRect,
        requireSingleFace: request.policy.requireSingleFace,
        requireNeutralPose: request.policy.requireNeutralPose,
      ),
    );
    return _stabilityService.evaluate(
      assessment: assessment,
      stabilityFrames: request.policy.alignmentStabilityFrames,
    );
  }

  void reset() => _stabilityService.reset();
}

/// Requires consecutive aligned frames before suggesting capture readiness.
class FaceAlignmentStabilityService {
  int _consecutiveAlignedFrames = 0;

  void reset() => _consecutiveAlignedFrames = 0;

  StableFaceAlignment evaluate({
    required FaceAlignmentAssessment assessment,
    required int stabilityFrames,
  }) {
    if (stabilityFrames <= 0) {
      throw ArgumentError.value(
        stabilityFrames,
        'stabilityFrames',
        'Must be greater than zero.',
      );
    }

    if (assessment.isAligned) {
      if (_consecutiveAlignedFrames < stabilityFrames) {
        _consecutiveAlignedFrames++;
      }
    } else {
      _consecutiveAlignedFrames = 0;
    }

    return StableFaceAlignment(
      assessment: assessment,
      consecutiveAlignedFrames: _consecutiveAlignedFrames,
      isStable: _consecutiveAlignedFrames >= stabilityFrames,
    );
  }
}
