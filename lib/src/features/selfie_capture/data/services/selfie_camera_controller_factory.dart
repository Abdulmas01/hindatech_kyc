import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';

import '../../../../core/camera/camera_device_selector.dart';
import '../../domain/models/selfie_capture_config.dart';
import '../models/selfie_frame_models.dart';

typedef SelfieAvailableCamerasLoader = Future<List<CameraDescription>>
    Function();

class SelfieCameraControllerFactory {
  SelfieCameraControllerFactory({
    this.loadAvailableCameras = availableCameras,
  });

  final SelfieAvailableCamerasLoader loadAvailableCameras;
  Future<List<CameraDescription>>? _cameraCache;

  Future<CameraDescription> selectCamera() async {
    final cameras = await _loadCameras();
    return CameraDeviceSelector.select(
      cameras,
      preferredDirection: CameraLensDirection.front,
    );
  }

  Future<CameraController> create(SelfieCaptureConfig config) async {
    final description = await selectCamera();
    final controller = CameraController(
      description,
      resolutionPreset(config.resolution),
      enableAudio: false,
      imageFormatGroup: imageFormatGroup(_currentPlatform()),
    );

    try {
      await controller.initialize().timeout(config.cameraStartupTimeout);
      return controller;
    } catch (_) {
      await controller.dispose();
      rethrow;
    }
  }

  void invalidateCameraCache() => _cameraCache = null;

  Future<List<CameraDescription>> _loadCameras() async {
    final future = _cameraCache ??= loadAvailableCameras();
    try {
      return await future;
    } catch (_) {
      if (identical(_cameraCache, future)) _cameraCache = null;
      rethrow;
    }
  }

  CameraRuntimePlatform _currentPlatform() => Platform.isIOS
      ? CameraRuntimePlatform.iOS
      : CameraRuntimePlatform.android;

  static ResolutionPreset resolutionPreset(
    SelfieCaptureResolution resolution,
  ) =>
      switch (resolution) {
        SelfieCaptureResolution.medium => ResolutionPreset.medium,
        SelfieCaptureResolution.high => ResolutionPreset.high,
        SelfieCaptureResolution.veryHigh => ResolutionPreset.veryHigh,
      };

  static ImageFormatGroup imageFormatGroup(CameraRuntimePlatform platform) =>
      switch (platform) {
        CameraRuntimePlatform.android => ImageFormatGroup.nv21,
        CameraRuntimePlatform.iOS => ImageFormatGroup.bgra8888,
      };
}
