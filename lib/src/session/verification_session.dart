import 'verification_required_inputs.dart';
import 'verification_session_policies.dart';

enum VerificationSessionStatus {
  started('started'),
  uploaded('uploaded'),
  processing('processing'),
  completed('completed'),
  failed('failed'),
  manualReview('manual_review'),
  expired('expired'),
  cancelled('cancelled'),
  unknown('unknown');

  const VerificationSessionStatus(this.wireValue);

  final String wireValue;

  static VerificationSessionStatus fromWireValue(String value) {
    for (final status in values) {
      if (status != unknown && status.wireValue == value) return status;
    }
    return unknown;
  }
}

enum VerificationSessionAction {
  readSession('session:read'),
  uploadAsset('asset:upload'),
  writePayload('payload:write'),
  submitSession('session:submit'),
  cancelSession('session:cancel'),
  readConsent('consent:read'),
  recordConsent('consent:record');

  const VerificationSessionAction(this.wireValue);

  final String wireValue;
}

/// A NestJS-issued authorization and workflow contract for one verification.
class VerificationSession {
  VerificationSession({
    required this.verificationSessionId,
    required this.sdkToken,
    required this.sdkTokenExpiresAt,
    required this.sessionExpiresAt,
    required List<String> allowedActions,
    required this.sessionModeValue,
    required this.assetIngestionModeValue,
    required List<String> supportedAssetIngestionModeValues,
    required this.workflowKey,
    required this.statusValue,
    required this.requiredInputs,
    required this.uploadPolicy,
    required this.polling,
    required this.rebootstrap,
  })  : allowedActions = List.unmodifiable(allowedActions),
        supportedAssetIngestionModeValues =
            List.unmodifiable(supportedAssetIngestionModeValues);

  final String verificationSessionId;
  final String sdkToken;
  final DateTime sdkTokenExpiresAt;
  final DateTime sessionExpiresAt;
  final List<String> allowedActions;
  final String sessionModeValue;
  final String assetIngestionModeValue;
  final List<String> supportedAssetIngestionModeValues;
  final String workflowKey;
  final String statusValue;
  final VerificationRequiredInputs requiredInputs;
  final VerificationUploadPolicy uploadPolicy;
  final VerificationPollingPolicy polling;
  final VerificationRebootstrapPolicy rebootstrap;

  VerificationSessionStatus get status =>
      VerificationSessionStatus.fromWireValue(statusValue);

  AssetIngestionMode get assetIngestionMode =>
      AssetIngestionMode.fromWireValue(assetIngestionModeValue);

  bool allows(VerificationSessionAction action) =>
      allowedActions.contains(action.wireValue);

  bool get isExpired {
    final now = DateTime.now().toUtc();
    return !sdkTokenExpiresAt.isAfter(now) || !sessionExpiresAt.isAfter(now);
  }

  factory VerificationSession.fromJson(Map<String, Object?> json) {
    return VerificationSession(
      verificationSessionId: _requiredString(json, 'verificationSessionId'),
      sdkToken: _requiredString(json, 'sdkToken'),
      sdkTokenExpiresAt: _requiredDateTime(json, 'sdkTokenExpiresAt'),
      sessionExpiresAt: _requiredDateTime(json, 'sessionExpiresAt'),
      allowedActions: _requiredStringList(json, 'allowedActions'),
      sessionModeValue: _requiredString(json, 'sessionMode'),
      assetIngestionModeValue: _requiredString(json, 'assetIngestionMode'),
      supportedAssetIngestionModeValues:
          _requiredStringList(json, 'supportedAssetIngestionModes'),
      workflowKey: _requiredString(json, 'workflowKey'),
      statusValue: _requiredString(json, 'status'),
      requiredInputs: VerificationRequiredInputs.fromJson(
        _requiredMap(json, 'requiredInputs'),
      ),
      uploadPolicy: VerificationUploadPolicy.fromJson(
        _requiredMap(json, 'uploadPolicy'),
      ),
      polling: VerificationPollingPolicy.fromJson(
        _requiredMap(json, 'polling'),
      ),
      rebootstrap: VerificationRebootstrapPolicy.fromJson(
        _requiredMap(json, 'rebootstrap'),
      ),
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
  final parsed = DateTime.tryParse(json[key]?.toString() ?? '')?.toUtc();
  if (parsed == null) throw FormatException('$key is missing or invalid.');
  return parsed;
}

List<String> _requiredStringList(Map<String, Object?> json, String key) {
  final raw = json[key];
  if (raw is! List) throw FormatException('$key must be a list.');
  return raw.map((value) {
    final parsed = value is String ? value.trim() : '';
    if (parsed.isEmpty) {
      throw FormatException('$key contains an invalid value.');
    }
    return parsed;
  }).toList(growable: false);
}

Map<String, Object?> _requiredMap(Map<String, Object?> json, String key) {
  final raw = json[key];
  if (raw is! Map) throw FormatException('$key is missing or invalid.');
  return Map<String, Object?>.from(raw);
}
