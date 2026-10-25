import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';
import 'package:hindatech_kyc/src/core/camera/camera_device_selector.dart';
import 'package:hindatech_kyc/src/core/camera/camera_lifecycle_coordinator.dart';
import 'package:hindatech_kyc/src/core/camera/camera_permission_service.dart';
import 'package:hindatech_kyc/src/features/document_capture/data/services/document_camera_controller_factory.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  group('CameraDeviceSelector', () {
    const front = CameraDescription(
      name: 'front',
      lensDirection: CameraLensDirection.front,
      sensorOrientation: 0,
    );
    const back = CameraDescription(
      name: 'back',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 90,
    );

    test('selects the preferred camera', () {
      final selected = CameraDeviceSelector.select(
        const [front, back],
        preferredDirection: CameraLensDirection.back,
      );

      expect(selected, back);
    });

    test('falls back to the first available camera', () {
      final selected = CameraDeviceSelector.select(
        const [front],
        preferredDirection: CameraLensDirection.back,
      );

      expect(selected, front);
    });

    test('reports an unavailable camera', () {
      expect(
        () => CameraDeviceSelector.select(
          const [],
          preferredDirection: CameraLensDirection.back,
        ),
        throwsA(isA<CameraException>()),
      );
    });
  });

  test('maps package resolution without exposing CameraController', () {
    expect(
      DocumentCameraControllerFactory.resolutionPreset(
        DocumentCaptureResolution.high,
      ),
      ResolutionPreset.high,
    );
  });

  test('maps camera permission states', () {
    expect(
      CameraPermissionService.mapStatus(PermissionStatus.granted),
      CameraPermissionResult.granted,
    );
    expect(
      CameraPermissionService.mapStatus(PermissionStatus.permanentlyDenied),
      CameraPermissionResult.permanentlyDenied,
    );
  });

  test('lifecycle coordinator skips queued work after disposal', () async {
    final coordinator = CameraLifecycleCoordinator();
    var wasCalled = false;
    coordinator.markDisposed();

    await coordinator.queueTransition(() async {
      wasCalled = true;
    });

    expect(wasCalled, isFalse);
    expect(coordinator.isDisposed, isTrue);
  });
}
