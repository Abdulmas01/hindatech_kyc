import '../core/serialization/json_fields.dart';

/// Client assertion that one exact consent notice was presented and affirmed.
///
/// This evidence does not establish subject identity or legal sufficiency.
class VerificationConsentRequest {
  VerificationConsentRequest({
    required String purposeCode,
    required String noticeId,
    required String noticeVersion,
    required String noticeSha256,
  })  : purposeCode = purposeCode.trim(),
        noticeId = noticeId.trim(),
        noticeVersion = noticeVersion.trim(),
        noticeSha256 = noticeSha256.trim().toLowerCase() {
    _validate();
  }

  static final RegExp _purposePattern = RegExp(r'^[a-z][a-z0-9_.-]{0,63}$');
  static final RegExp _noticeIdPattern =
      RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.-]{0,63}$');
  static final RegExp _noticeVersionPattern =
      RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.-]{0,31}$');
  static final RegExp _sha256Pattern = RegExp(r'^[a-f0-9]{64}$');

  final String purposeCode;
  final String noticeId;
  final String noticeVersion;
  final String noticeSha256;

  Map<String, Object?> toJson() => {
        'purposeCode': purposeCode,
        'noticeId': noticeId,
        'noticeVersion': noticeVersion,
        'noticeSha256': noticeSha256,
      };

  void _validate() {
    if (!_purposePattern.hasMatch(purposeCode)) {
      throw ArgumentError.value(purposeCode, 'purposeCode', 'Is invalid.');
    }
    if (!_noticeIdPattern.hasMatch(noticeId)) {
      throw ArgumentError.value(noticeId, 'noticeId', 'Is invalid.');
    }
    if (!_noticeVersionPattern.hasMatch(noticeVersion)) {
      throw ArgumentError.value(noticeVersion, 'noticeVersion', 'Is invalid.');
    }
    if (!_sha256Pattern.hasMatch(noticeSha256)) {
      throw ArgumentError.value(
        noticeSha256,
        'noticeSha256',
        'Must be a 64-character SHA-256 digest.',
      );
    }
  }
}

/// Consent evidence recorded by the verification service.
class VerificationConsentEvidence {
  const VerificationConsentEvidence({
    required this.id,
    required this.purposeCode,
    required this.noticeId,
    required this.noticeVersion,
    required this.noticeSha256,
    required this.sourceType,
    required this.affirmedAt,
  });

  final String id;
  final String purposeCode;
  final String noticeId;
  final String noticeVersion;
  final String noticeSha256;
  final String sourceType;
  final DateTime affirmedAt;

  factory VerificationConsentEvidence.fromJson(Map<String, Object?> json) {
    final noticeSha256 = JsonFields.requiredString(json, 'noticeSha256');
    if (!VerificationConsentRequest._sha256Pattern
        .hasMatch(noticeSha256.toLowerCase())) {
      throw const FormatException('noticeSha256 is invalid.');
    }
    return VerificationConsentEvidence(
      id: JsonFields.requiredString(json, 'id'),
      purposeCode: JsonFields.requiredString(json, 'purposeCode'),
      noticeId: JsonFields.requiredString(json, 'noticeId'),
      noticeVersion: JsonFields.requiredString(json, 'noticeVersion'),
      noticeSha256: noticeSha256.toLowerCase(),
      sourceType: JsonFields.requiredString(json, 'sourceType'),
      affirmedAt: JsonFields.requiredDateTime(json, 'affirmedAt'),
    );
  }
}

/// Consent evidence records currently retained for one verification session.
class VerificationConsentEvidenceList {
  VerificationConsentEvidenceList({
    required List<VerificationConsentEvidence> results,
  }) : results = List.unmodifiable(results);

  final List<VerificationConsentEvidence> results;

  factory VerificationConsentEvidenceList.fromJson(
    Map<String, Object?> json,
  ) {
    final results = JsonFields.requiredList(json, 'results').map((value) {
      if (value is! Map) {
        throw const FormatException('results contains an invalid value.');
      }
      return VerificationConsentEvidence.fromJson(
        Map<String, Object?>.from(value),
      );
    }).toList(growable: false);
    return VerificationConsentEvidenceList(results: results);
  }
}
