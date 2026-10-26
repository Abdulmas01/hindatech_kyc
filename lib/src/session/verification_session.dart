import 'capture_manifest.dart';

/// A short-lived authorization and capture plan for one verification.
///
/// Applications obtain this payload from their backend. The contained token
/// must be scoped to this verification and must not be replaced with a
/// long-lived customer API credential.
class VerificationSession {
  const VerificationSession({
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
  final CaptureManifest captureManifest;

  bool get isExpired =>
      expiresAt != null && !expiresAt!.isAfter(DateTime.now().toUtc());

  factory VerificationSession.fromJson(Map<String, Object?> json) {
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

    return VerificationSession(
      verificationId: verificationId,
      sdkToken: sdkToken,
      workflowKey: workflowKey,
      expiresAt:
          DateTime.tryParse(json['expires_at']?.toString() ?? '')?.toUtc(),
      captureManifest: CaptureManifest.fromJson(manifestJson),
    );
  }

  static String? _optionalString(Object? value) {
    final parsed = value?.toString().trim();
    return parsed == null || parsed.isEmpty ? null : parsed;
  }
}
