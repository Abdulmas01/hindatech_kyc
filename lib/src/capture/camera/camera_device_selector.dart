import 'package:camera/camera.dart';

class CameraDeviceSelector {
  const CameraDeviceSelector._();

  static CameraDescription select(
    List<CameraDescription> cameras, {
    required CameraLensDirection preferredDirection,
  }) {
    if (cameras.isEmpty) {
      throw CameraException(
        'camera_not_available',
        'No camera is available on this device.',
      );
    }

    return cameras.firstWhere(
      (camera) => camera.lensDirection == preferredDirection,
      orElse: () => cameras.first,
    );
  }
}
