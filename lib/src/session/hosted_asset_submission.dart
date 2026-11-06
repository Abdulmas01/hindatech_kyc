import 'verification_session.dart';

/// Exact staged asset selections for one hosted submission.
class HostedAssetSubmissionRequest {
  HostedAssetSubmissionRequest({
    required Map<String, String> assets,
  }) : assets = Map.unmodifiable(assets);

  /// Maps each workflow input type to the exact staged asset key selected.
  final Map<String, String> assets;

  Map<String, Object?> toJson() => {'assets': assets};
}

/// NestJS acknowledgement that selected assets entered processing.
class VerificationSubmission {
  const VerificationSubmission({
    required this.verificationSessionId,
    required this.statusValue,
    required this.submittedAt,
  });

  final String verificationSessionId;
  final String statusValue;
  final DateTime submittedAt;

  VerificationSessionStatus get status =>
      VerificationSessionStatus.fromWireValue(statusValue);

  factory VerificationSubmission.fromJson(Map<String, Object?> json) {
    return VerificationSubmission(
      verificationSessionId: _requiredString(json, 'verificationSessionId'),
      statusValue: _requiredString(json, 'status'),
      submittedAt: _requiredDateTime(json, 'submittedAt'),
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
