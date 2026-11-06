import '../core/serialization/json_fields.dart';
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
      verificationSessionId:
          JsonFields.requiredString(json, 'verificationSessionId'),
      statusValue: JsonFields.requiredString(json, 'status'),
      submittedAt: JsonFields.requiredDateTime(json, 'submittedAt'),
    );
  }
}
