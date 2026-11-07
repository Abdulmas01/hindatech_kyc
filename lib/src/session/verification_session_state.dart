import '../core/serialization/json_fields.dart';
import 'hosted_asset.dart';
import 'verification_liveness_policy.dart';
import 'verification_required_inputs.dart';
import 'verification_result.dart';
import 'verification_session.dart';
import 'verification_session_policies.dart';

/// Recoverable SDK runtime state returned by the NestJS session route.
class VerificationSessionState {
  VerificationSessionState({
    required this.verificationSessionId,
    required this.sessionModeValue,
    required this.assetIngestionModeValue,
    required List<String> supportedAssetIngestionModeValues,
    required this.workflowKey,
    required this.statusValue,
    required this.requiredInputs,
    required this.uploadPolicy,
    required this.livenessPolicy,
    required this.polling,
    required this.rebootstrap,
    required this.result,
    required List<HostedAsset> hostedAssets,
  })  : supportedAssetIngestionModeValues =
            List.unmodifiable(supportedAssetIngestionModeValues),
        hostedAssets = List.unmodifiable(hostedAssets);

  final String verificationSessionId;
  final String sessionModeValue;
  final String assetIngestionModeValue;
  final List<String> supportedAssetIngestionModeValues;
  final String workflowKey;
  final String statusValue;
  final VerificationRequiredInputs requiredInputs;
  final VerificationUploadPolicy uploadPolicy;
  final VerificationLivenessPolicy? livenessPolicy;
  final VerificationPollingPolicy polling;
  final VerificationRebootstrapPolicy rebootstrap;
  final VerificationResult result;

  /// Every unexpired staged upload returned by NestJS, including duplicates.
  final List<HostedAsset> hostedAssets;

  VerificationSessionStatus get status =>
      VerificationSessionStatus.fromWireValue(statusValue);

  AssetIngestionMode get assetIngestionMode =>
      AssetIngestionMode.fromWireValue(assetIngestionModeValue);

  /// Whether this state ends SDK polling for the active verification.
  bool get isTerminal => switch (status) {
        VerificationSessionStatus.completed ||
        VerificationSessionStatus.failed ||
        VerificationSessionStatus.manualReview ||
        VerificationSessionStatus.expired ||
        VerificationSessionStatus.cancelled =>
          true,
        _ => false,
      };

  /// Returns every recovered candidate for [inputType] without selecting one.
  Iterable<HostedAsset> hostedAssetsFor(String inputType) =>
      hostedAssets.where((asset) => asset.inputTypeValue == inputType);

  factory VerificationSessionState.fromJson(Map<String, Object?> json) {
    final verificationSessionId =
        JsonFields.requiredString(json, 'verificationSessionId');
    final result = VerificationResult.fromJson(
      JsonFields.requiredMap(json, 'session'),
    );
    final statusValue = JsonFields.requiredString(json, 'status');
    if (result.verificationSessionId != verificationSessionId ||
        result.statusValue != statusValue) {
      throw const FormatException('Session result identity is invalid.');
    }
    final rawAssets = JsonFields.requiredList(json, 'hostedAssets');
    final hostedAssets = rawAssets.map((value) {
      if (value is! Map) {
        throw const FormatException('hostedAssets contains an invalid value.');
      }
      final asset = HostedAsset.fromJson(Map<String, Object?>.from(value));
      if (asset.verificationSessionId != verificationSessionId) {
        throw const FormatException(
          'Hosted asset belongs to another verification session.',
        );
      }
      return asset;
    }).toList(growable: false);

    return VerificationSessionState(
      verificationSessionId: verificationSessionId,
      sessionModeValue: JsonFields.requiredString(json, 'sessionMode'),
      assetIngestionModeValue:
          JsonFields.requiredString(json, 'assetIngestionMode'),
      supportedAssetIngestionModeValues:
          JsonFields.requiredStringList(json, 'supportedAssetIngestionModes'),
      workflowKey: JsonFields.requiredString(json, 'workflowKey'),
      statusValue: statusValue,
      requiredInputs: VerificationRequiredInputs.fromJson(
        JsonFields.requiredMap(json, 'requiredInputs'),
      ),
      uploadPolicy: VerificationUploadPolicy.fromJson(
        JsonFields.requiredMap(json, 'uploadPolicy'),
      ),
      livenessPolicy: VerificationLivenessPolicy.readNullable(json),
      polling: VerificationPollingPolicy.fromJson(
        JsonFields.requiredMap(json, 'polling'),
      ),
      rebootstrap: VerificationRebootstrapPolicy.fromJson(
        JsonFields.requiredMap(json, 'rebootstrap'),
      ),
      result: result,
      hostedAssets: hostedAssets,
    );
  }
}
