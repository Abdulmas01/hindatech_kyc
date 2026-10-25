import 'package:permission_handler/permission_handler.dart';

enum CameraPermissionResult { granted, denied, permanentlyDenied, restricted }

class CameraPermissionService {
  const CameraPermissionService();

  Future<CameraPermissionResult> request() async {
    return mapStatus(await Permission.camera.request());
  }

  Future<bool> openSettings() => openAppSettings();

  static CameraPermissionResult mapStatus(PermissionStatus status) {
    if (status.isGranted || status.isLimited || status.isProvisional) {
      return CameraPermissionResult.granted;
    }
    if (status.isPermanentlyDenied) {
      return CameraPermissionResult.permanentlyDenied;
    }
    if (status.isRestricted) {
      return CameraPermissionResult.restricted;
    }
    return CameraPermissionResult.denied;
  }
}
