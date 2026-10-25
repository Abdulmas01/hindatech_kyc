import 'package:camera/camera.dart';

import '../../../../core/camera/camera_device_selector.dart';
import '../../domain/models/document_capture_config.dart';

typedef AvailableCamerasLoader = Future<List<CameraDescription>> Function();

class DocumentCameraControllerFactory {
  const DocumentCameraControllerFactory({
    this.loadAvailableCameras = availableCameras,
  });

  final AvailableCamerasLoader loadAvailableCameras;

  Future<CameraController> create(DocumentCaptureConfig config) async {
    final cameras = await loadAvailableCameras();
    final description = CameraDeviceSelector.select(
      cameras,
      preferredDirection: CameraLensDirection.back,
    );
    final controller = CameraController(
      description,
      resolutionPreset(config.resolution),
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await controller.initialize();
      return controller;
    } catch (_) {
      await controller.dispose();
      rethrow;
    }
  }

  static ResolutionPreset resolutionPreset(
    DocumentCaptureResolution resolution,
  ) {
    return switch (resolution) {
      DocumentCaptureResolution.low => ResolutionPreset.low,
      DocumentCaptureResolution.medium => ResolutionPreset.medium,
      DocumentCaptureResolution.high => ResolutionPreset.high,
      DocumentCaptureResolution.veryHigh => ResolutionPreset.veryHigh,
    };
  }
}
