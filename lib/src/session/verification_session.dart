import '../core/serialization/json_fields.dart';
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
      verificationSessionId:
          JsonFields.requiredString(json, 'verificationSessionId'),
      sdkToken: JsonFields.requiredString(json, 'sdkToken'),
      sdkTokenExpiresAt: JsonFields.requiredDateTime(json, 'sdkTokenExpiresAt'),
      sessionExpiresAt: JsonFields.requiredDateTime(json, 'sessionExpiresAt'),
      allowedActions: JsonFields.requiredStringList(json, 'allowedActions'),
      sessionModeValue: JsonFields.requiredString(json, 'sessionMode'),
      assetIngestionModeValue:
          JsonFields.requiredString(json, 'assetIngestionMode'),
      supportedAssetIngestionModeValues:
          JsonFields.requiredStringList(json, 'supportedAssetIngestionModes'),
      workflowKey: JsonFields.requiredString(json, 'workflowKey'),
      statusValue: JsonFields.requiredString(json, 'status'),
      requiredInputs: VerificationRequiredInputs.fromJson(
        JsonFields.requiredMap(json, 'requiredInputs'),
      ),
      uploadPolicy: VerificationUploadPolicy.fromJson(
        JsonFields.requiredMap(json, 'uploadPolicy'),
      ),
      polling: VerificationPollingPolicy.fromJson(
        JsonFields.requiredMap(json, 'polling'),
      ),
      rebootstrap: VerificationRebootstrapPolicy.fromJson(
        JsonFields.requiredMap(json, 'rebootstrap'),
      ),
    );
  }
}
