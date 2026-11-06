import 'verification_required_inputs.dart';

/// Input for staging one workflow-declared asset.
class HostedAssetUploadRequest {
  const HostedAssetUploadRequest({
    required this.inputType,
    required this.filePath,
    this.contentType,
  });

  final String inputType;
  final String filePath;

  /// Optional MIME type override. File extensions are used when omitted.
  final String? contentType;
}

/// A temporary asset staged by the NestJS hosted-upload endpoint.
///
/// [assetKey] is an opaque submission identifier, not a public file URL.
class HostedAsset {
  const HostedAsset({
    required this.assetKey,
    required this.verificationSessionId,
    required this.inputTypeValue,
    required this.contentType,
    required this.sizeBytes,
    required this.uploadedAt,
    required this.expiresAt,
  });

  final String assetKey;
  final String verificationSessionId;
  final String inputTypeValue;
  final String contentType;
  final int sizeBytes;
  final DateTime uploadedAt;
  final DateTime expiresAt;

  CaptureAssetType get inputType =>
      CaptureAssetType.fromWireValue(inputTypeValue);

  bool get isExpired => !expiresAt.isAfter(DateTime.now().toUtc());

  factory HostedAsset.fromJson(Map<String, Object?> json) {
    final sizeBytes = json['sizeBytes'];
    if (sizeBytes is! int || sizeBytes < 0) {
      throw const FormatException('Hosted asset sizeBytes is invalid.');
    }

    return HostedAsset(
      assetKey: _requiredString(json, 'assetKey'),
      verificationSessionId: _requiredString(json, 'verificationSessionId'),
      inputTypeValue: _requiredString(json, 'inputType'),
      contentType: _requiredString(json, 'contentType'),
      sizeBytes: sizeBytes,
      uploadedAt: _requiredDateTime(json, 'uploadedAt'),
      expiresAt: _requiredDateTime(json, 'expiresAt'),
    );
  }
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  final parsed = value is String ? value.trim() : '';
  if (parsed.isEmpty) throw FormatException('$key is missing or invalid.');
  return parsed;
}

DateTime _requiredDateTime(Map<String, Object?> json, String key) {
  final value = json[key];
  final parsed = value is String ? DateTime.tryParse(value) : null;
  if (parsed == null) throw FormatException('$key is missing or invalid.');
  return parsed.toUtc();
}
