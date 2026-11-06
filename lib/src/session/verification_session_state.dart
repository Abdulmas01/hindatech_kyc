import 'hosted_asset.dart';
import 'verification_required_inputs.dart';
import 'verification_session.dart';
import 'verification_session_policies.dart';

/// Recoverable SDK runtime state returned by the NestJS session route.
class VerificationSessionState {
  VerificationSessionState({
    required this.verificationSessionId,
    required this.sessionModeValue,
    required this.assetIngestionModeValue,
    required this.workflowKey,
    required this.statusValue,
    required this.requiredInputs,
    required this.uploadPolicy,
    required this.polling,
    required this.rebootstrap,
    required List<HostedAsset> hostedAssets,
  }) : hostedAssets = List.unmodifiable(hostedAssets);

  final String verificationSessionId;
  final String sessionModeValue;
  final String assetIngestionModeValue;
  final String workflowKey;
  final String statusValue;
  final VerificationRequiredInputs requiredInputs;
  final VerificationUploadPolicy uploadPolicy;
  final VerificationPollingPolicy polling;
  final VerificationRebootstrapPolicy rebootstrap;

  /// Every unexpired staged upload returned by NestJS, including duplicates.
  final List<HostedAsset> hostedAssets;

  VerificationSessionStatus get status =>
      VerificationSessionStatus.fromWireValue(statusValue);

  AssetIngestionMode get assetIngestionMode =>
      AssetIngestionMode.fromWireValue(assetIngestionModeValue);

  /// Returns every recovered candidate for [inputType] without selecting one.
  Iterable<HostedAsset> hostedAssetsFor(String inputType) =>
      hostedAssets.where((asset) => asset.inputTypeValue == inputType);

  factory VerificationSessionState.fromJson(Map<String, Object?> json) {
    final verificationSessionId =
        _requiredString(json, 'verificationSessionId');
    final rawAssets = json['hostedAssets'];
    if (rawAssets is! List) {
      throw const FormatException('hostedAssets must be a list.');
    }
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
      sessionModeValue: _requiredString(json, 'sessionMode'),
      assetIngestionModeValue: _requiredString(json, 'assetIngestionMode'),
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
      hostedAssets: hostedAssets,
    );
  }
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  final parsed = value is String ? value.trim() : '';
  if (parsed.isEmpty) throw FormatException('$key is missing or invalid.');
  return parsed;
}

Map<String, Object?> _requiredMap(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! Map) throw FormatException('$key is missing or invalid.');
  return Map<String, Object?>.from(value);
}
