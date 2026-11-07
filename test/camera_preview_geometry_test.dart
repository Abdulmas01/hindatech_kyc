import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/src/core/camera/camera_preview_geometry.dart';
import 'package:hindatech_kyc/src/features/selfie_capture/domain/models/face_guide_config.dart';

void main() {
  test('maps through the centered cover crop used by the preview', () {
    final geometry = CameraPreviewGeometry(
      sourceSize: const Size(400, 200),
      viewportSize: const Size(200, 200),
      rotation: CameraImageRotation.degrees0,
      mirrored: false,
    );

    expect(
      geometry.mapRect(const Rect.fromLTRB(100, 0, 300, 200)),
      const Rect.fromLTRB(0, 0, 200, 200),
    );
  });

  test('maps clockwise rotation into upright preview space', () {
    final geometry = CameraPreviewGeometry(
      sourceSize: const Size(400, 200),
      viewportSize: const Size(200, 400),
      rotation: CameraImageRotation.degrees90,
      mirrored: false,
    );

    expect(
      geometry.mapRect(const Rect.fromLTRB(0, 0, 400, 200)),
      const Rect.fromLTRB(0, 0, 200, 400),
    );
  });

  test('mirrors front-camera detector bounds into visible preview space', () {
    final geometry = CameraPreviewGeometry(
      sourceSize: const Size(200, 400),
      viewportSize: const Size(200, 400),
      rotation: CameraImageRotation.degrees0,
      mirrored: true,
    );

    expect(
      geometry.mapRect(const Rect.fromLTRB(0, 100, 50, 300)),
      const Rect.fromLTRB(150, 100, 200, 300),
    );
  });

  test('resolves a bounded responsive oval inside the camera area', () {
    const config = FaceGuideConfig();

    final guide = config.resolve(const Rect.fromLTRB(0, 40, 400, 760));

    expect(guide.width, lessThanOrEqualTo(360));
    expect(guide.height, lessThanOrEqualTo(720 * 0.72));
    expect(const Rect.fromLTRB(0, 40, 400, 760).contains(guide.center), isTrue);
  });
}
