import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:hindatech_kyc/src/core/camera/camera_preview_geometry.dart';
import 'package:hindatech_kyc/src/features/selfie_capture/data/models/selfie_frame_models.dart';
import 'package:hindatech_kyc/src/features/selfie_capture/data/services/camera_frame_rotation_resolver.dart';

void main() {
  const resolver = CameraFrameRotationResolver();

  test('combines Android front sensor and device rotations', () {
    final result = resolver.resolve(
      const CameraFrameRotationRequest(
        platform: CameraRuntimePlatform.android,
        sensorOrientation: 90,
        lensDirection: CameraLensDirection.front,
        deviceOrientation: DeviceOrientation.landscapeLeft,
      ),
    );

    expect(result?.inputImageRotation, InputImageRotation.rotation180deg);
    expect(result?.previewRotation, CameraImageRotation.degrees180);
  });

  test('subtracts Android back-camera device compensation', () {
    final result = resolver.resolve(
      const CameraFrameRotationRequest(
        platform: CameraRuntimePlatform.android,
        sensorOrientation: 90,
        lensDirection: CameraLensDirection.back,
        deviceOrientation: DeviceOrientation.landscapeLeft,
      ),
    );

    expect(result?.inputImageRotation, InputImageRotation.rotation0deg);
    expect(result?.previewRotation, CameraImageRotation.degrees0);
  });

  test('uses the iOS sensor orientation directly', () {
    final result = resolver.resolve(
      const CameraFrameRotationRequest(
        platform: CameraRuntimePlatform.iOS,
        sensorOrientation: 270,
        lensDirection: CameraLensDirection.front,
        deviceOrientation: DeviceOrientation.portraitUp,
      ),
    );

    expect(result?.inputImageRotation, InputImageRotation.rotation270deg);
    expect(result?.previewRotation, CameraImageRotation.degrees270);
  });

  test('rejects unsupported sensor rotations', () {
    final result = resolver.resolve(
      const CameraFrameRotationRequest(
        platform: CameraRuntimePlatform.iOS,
        sensorOrientation: 45,
        lensDirection: CameraLensDirection.front,
        deviceOrientation: DeviceOrientation.portraitUp,
      ),
    );

    expect(result, isNull);
  });

  test('uses Android rotation-adjusted detector coordinates', () {
    final result = resolver.detectorCoordinateSpace(
      const DetectorCoordinateSpaceRequest(
        platform: CameraRuntimePlatform.android,
        rawSourceSize: Size(1280, 720),
        previewRotation: CameraImageRotation.degrees90,
      ),
    );

    expect(result.sourceSize, const Size(720, 1280));
    expect(result.rotation, CameraImageRotation.degrees0);
  });

  test('keeps iOS detector coordinates raw for preview mapping', () {
    final result = resolver.detectorCoordinateSpace(
      const DetectorCoordinateSpaceRequest(
        platform: CameraRuntimePlatform.iOS,
        rawSourceSize: Size(1280, 720),
        previewRotation: CameraImageRotation.degrees90,
      ),
    );

    expect(result.sourceSize, const Size(1280, 720));
    expect(result.rotation, CameraImageRotation.degrees90);
  });
}
