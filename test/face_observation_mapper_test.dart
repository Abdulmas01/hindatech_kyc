import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/src/core/camera/camera_preview_geometry.dart';
import 'package:hindatech_kyc/src/features/selfie_capture/data/models/selfie_frame_models.dart';
import 'package:hindatech_kyc/src/features/selfie_capture/data/services/face_observation_mapper.dart';

void main() {
  test('maps detector bounds and preserves challenge observations', () {
    const mapper = FaceObservationMapper();
    final result = mapper.map(
      FaceObservationMappingRequest(
        faces: const [
          RawFaceObservation(
            bounds: Rect.fromLTRB(0, 25, 50, 75),
            yawDegrees: 7,
            pitchDegrees: -3,
            rollDegrees: 2,
            leftEyeOpenProbability: 0.25,
            rightEyeOpenProbability: 0.75,
            trackingId: 4,
          ),
        ],
        geometry: CameraPreviewGeometry(
          sourceSize: const Size(200, 100),
          viewportSize: const Size(100, 200),
          rotation: CameraImageRotation.degrees90,
          mirrored: true,
        ),
      ),
    );

    expect(result.single.geometry.bounds, const Rect.fromLTRB(25, 0, 75, 50));
    expect(result.single.geometry.yawDegrees, 7);
    expect(result.single.geometry.pitchDegrees, -3);
    expect(result.single.geometry.rollDegrees, 2);
    expect(result.single.leftEyeOpenProbability, 0.25);
    expect(result.single.rightEyeOpenProbability, 0.75);
    expect(result.single.trackingId, 4);
  });
}
