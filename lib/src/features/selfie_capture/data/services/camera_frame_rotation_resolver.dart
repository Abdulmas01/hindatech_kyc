import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../../../core/camera/camera_preview_geometry.dart';
import '../models/selfie_frame_models.dart';

class CameraFrameRotationResolver {
  const CameraFrameRotationResolver();

  ResolvedCameraFrameRotation? resolve(CameraFrameRotationRequest request) {
    final degrees = switch (request.platform) {
      CameraRuntimePlatform.iOS => request.sensorOrientation,
      CameraRuntimePlatform.android => _androidRotation(request),
    };
    final inputRotation = InputImageRotationValue.fromRawValue(degrees);
    final previewRotation = _previewRotation(degrees);
    if (inputRotation == null || previewRotation == null) return null;

    return ResolvedCameraFrameRotation(
      inputImageRotation: inputRotation,
      previewRotation: previewRotation,
    );
  }

  /// Describes the coordinate space used by bounds returned from ML Kit.
  DetectorCoordinateSpace detectorCoordinateSpace(
    DetectorCoordinateSpaceRequest request,
  ) {
    if (request.platform == CameraRuntimePlatform.iOS) {
      return DetectorCoordinateSpace(
        sourceSize: request.rawSourceSize,
        rotation: request.previewRotation,
      );
    }

    final swapsAxes =
        request.previewRotation == CameraImageRotation.degrees90 ||
            request.previewRotation == CameraImageRotation.degrees270;
    return DetectorCoordinateSpace(
      sourceSize: swapsAxes
          ? Size(request.rawSourceSize.height, request.rawSourceSize.width)
          : request.rawSourceSize,
      rotation: CameraImageRotation.degrees0,
    );
  }

  int _androidRotation(CameraFrameRotationRequest request) {
    const orientationDegrees = {
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };
    final compensation = orientationDegrees[request.deviceOrientation]!;
    if (request.lensDirection == CameraLensDirection.front) {
      return (request.sensorOrientation + compensation) % 360;
    }
    return (request.sensorOrientation - compensation + 360) % 360;
  }

  CameraImageRotation? _previewRotation(int degrees) => switch (degrees) {
        0 => CameraImageRotation.degrees0,
        90 => CameraImageRotation.degrees90,
        180 => CameraImageRotation.degrees180,
        270 => CameraImageRotation.degrees270,
        _ => null,
      };
}
