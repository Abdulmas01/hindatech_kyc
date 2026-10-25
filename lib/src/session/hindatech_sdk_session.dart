import 'hindatech_capture_manifest.dart';

/// A short-lived, session-scoped SDK authorization returned by Hindatech.
class HindatechSdkSession {
  const HindatechSdkSession({
    required this.verificationId,
    required this.sdkToken,
    required this.captureManifest,
    this.workflowKey,
    this.expiresAt,
  });

  final String verificationId;
  final String sdkToken;
  final String? workflowKey;
  final DateTime? expiresAt;
  final HindatechCaptureManifest captureManifest;

  bool get isExpired =>
      expiresAt != null && !expiresAt!.isAfter(DateTime.now().toUtc());

  factory HindatechSdkSession.fromJson(Map<String, Object?> json) {
    final verificationId = json['id']?.toString().trim() ?? '';
    final sdkToken = json['sdk_token']?.toString().trim() ?? '';
    final rawManifest = json['capture_manifest'];

    if (verificationId.isEmpty) {
      throw const FormatException('Verification id is missing.');
    }
    if (sdkToken.isEmpty) {
      throw const FormatException('SDK token is missing.');
    }
    if (rawManifest is! Map) {
      throw const FormatException('Capture manifest is missing.');
    }

    final workflowKey = _optionalString(json['workflow_key']);
    final manifestJson = Map<String, Object?>.from(rawManifest);
    if (workflowKey != null && manifestJson['workflow_key'] == null) {
      manifestJson['workflow_key'] = workflowKey;
    }

    return HindatechSdkSession(
      verificationId: verificationId,
      sdkToken: sdkToken,
      workflowKey: workflowKey,
      expiresAt:
          DateTime.tryParse(json['expires_at']?.toString() ?? '')?.toUtc(),
      captureManifest: HindatechCaptureManifest.fromJson(manifestJson),
    );
  }

  static String? _optionalString(Object? value) {
    final parsed = value?.toString().trim();
    return parsed == null || parsed.isEmpty ? null : parsed;
  }
}
