import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../../../core/camera/camera_preview_geometry.dart';
import '../../../../session/verification_liveness_policy.dart';
import '../../domain/models/face_alignment.dart';

enum CameraRuntimePlatform { android, iOS }

class CameraFrameRotationRequest {
  const CameraFrameRotationRequest({
    required this.platform,
    required this.sensorOrientation,
    required this.lensDirection,
    required this.deviceOrientation,
  });

  final CameraRuntimePlatform platform;
  final int sensorOrientation;
  final CameraLensDirection lensDirection;
  final DeviceOrientation deviceOrientation;
}

class ResolvedCameraFrameRotation {
  const ResolvedCameraFrameRotation({
    required this.inputImageRotation,
    required this.previewRotation,
  });

  final InputImageRotation inputImageRotation;
  final CameraImageRotation previewRotation;
}

class DetectorCoordinateSpaceRequest {
  const DetectorCoordinateSpaceRequest({
    required this.platform,
    required this.rawSourceSize,
    required this.previewRotation,
  });

  final CameraRuntimePlatform platform;
  final Size rawSourceSize;
  final CameraImageRotation previewRotation;
}

class DetectorCoordinateSpace {
  const DetectorCoordinateSpace({
    required this.sourceSize,
    required this.rotation,
  });

  final Size sourceSize;
  final CameraImageRotation rotation;
}

class SelfieCameraFrameRequest {
  const SelfieCameraFrameRequest({
    required this.controller,
    required this.image,
  });

  final CameraController controller;
  final CameraImage image;
}

class PreparedSelfieFrame {
  const PreparedSelfieFrame({
    required this.inputImage,
    required this.sourceSize,
    required this.rotation,
    required this.mirrored,
  });

  final InputImage inputImage;
  final Size sourceSize;
  final CameraImageRotation rotation;
  final bool mirrored;
}

class RawFaceObservation {
  const RawFaceObservation({
    required this.bounds,
    this.yawDegrees,
    this.pitchDegrees,
    this.rollDegrees,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
    this.trackingId,
  });

  final Rect bounds;
  final double? yawDegrees;
  final double? pitchDegrees;
  final double? rollDegrees;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;
  final int? trackingId;
}

class MappedFaceObservation {
  const MappedFaceObservation({
    required this.geometry,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
    this.trackingId,
  });

  final DetectedFaceGeometry geometry;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;
  final int? trackingId;
}

class FaceObservationMappingRequest {
  FaceObservationMappingRequest({
    required List<RawFaceObservation> faces,
    required this.geometry,
  }) : faces = List.unmodifiable(faces);

  final List<RawFaceObservation> faces;
  final CameraPreviewGeometry geometry;
}

class SelfieFrameAnalysisRequest {
  const SelfieFrameAnalysisRequest({
    required this.controller,
    required this.image,
    required this.viewportSize,
    required this.guideRect,
    required this.policy,
  });

  final CameraController controller;
  final CameraImage image;
  final Size viewportSize;
  final Rect guideRect;
  final VerificationLivenessPolicy policy;
}

/// Device-side observations and framing guidance, not a liveness decision.
class SelfieFrameAnalysis {
  SelfieFrameAnalysis({
    required List<MappedFaceObservation> faces,
    required this.alignment,
  }) : faces = List.unmodifiable(faces);

  final List<MappedFaceObservation> faces;
  final StableFaceAlignment alignment;

  bool get suggestsCaptureReady => alignment.suggestsCaptureReady;
}
