import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';
import 'package:hindatech_kyc/src/features/selfie_capture/data/models/selfie_frame_models.dart';
import 'package:hindatech_kyc/src/features/selfie_capture/data/services/selfie_camera_controller_factory.dart';

void main() {
  test('caches camera discovery and prefers the front camera', () async {
    var calls = 0;
    final factory = SelfieCameraControllerFactory(
      loadAvailableCameras: () async {
        calls++;
        return const [
          CameraDescription(
            name: 'back',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 90,
          ),
          CameraDescription(
            name: 'front',
            lensDirection: CameraLensDirection.front,
            sensorOrientation: 90,
          ),
        ];
      },
    );

    expect((await factory.selectCamera()).name, 'front');
    expect((await factory.selectCamera()).name, 'front');
    expect(calls, 1);

    factory.invalidateCameraCache();
    await factory.selectCamera();
    expect(calls, 2);
  });

  test('maps customer resolution and native stream formats', () {
    expect(
      SelfieCameraControllerFactory.resolutionPreset(
        SelfieCaptureResolution.high,
      ),
      ResolutionPreset.high,
    );
    expect(
      SelfieCameraControllerFactory.imageFormatGroup(
        CameraRuntimePlatform.android,
      ),
      ImageFormatGroup.nv21,
    );
    expect(
      SelfieCameraControllerFactory.imageFormatGroup(
        CameraRuntimePlatform.iOS,
      ),
      ImageFormatGroup.bgra8888,
    );
  });
}
