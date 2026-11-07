import '../core/serialization/json_fields.dart';
import 'verification_session.dart';

/// A product-facing decision returned by the verification service.
enum VerificationDecision {
  pending('pending'),
  accept('accept'),
  reject('reject'),
  manualReview('manual_review'),
  notApplicable('not_applicable'),
  unknown('unknown');

  const VerificationDecision(this.wireValue);

  final String wireValue;

  static VerificationDecision fromWireValue(String value) {
    for (final decision in values) {
      if (decision != unknown && decision.wireValue == value) return decision;
    }
    return unknown;
  }
}

/// Stable customer-safe verification information included in session state.
///
/// Detailed AI evidence remains a backend concern. This model exposes only the
/// normalized outcome and failure information needed to finish a mobile flow.
class VerificationResult {
  VerificationResult({
    required this.verificationSessionId,
    required this.statusValue,
    required this.decisionValue,
    required this.riskScore,
    required this.createdAt,
    required this.completedAt,
    required this.failureCode,
    required this.failureMessage,
    required List<String> reasonCodes,
  }) : reasonCodes = List.unmodifiable(reasonCodes);

  final String verificationSessionId;
  final String statusValue;
  final String decisionValue;
  final double? riskScore;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? failureCode;
  final String? failureMessage;
  final List<String> reasonCodes;

  VerificationSessionStatus get status =>
      VerificationSessionStatus.fromWireValue(statusValue);

  VerificationDecision get decision =>
      VerificationDecision.fromWireValue(decisionValue);

  factory VerificationResult.fromJson(Map<String, Object?> json) {
    return VerificationResult(
      verificationSessionId: JsonFields.requiredString(json, 'id'),
      statusValue: JsonFields.requiredString(json, 'status'),
      decisionValue: JsonFields.requiredString(json, 'decision'),
      riskScore: _requiredNullableDouble(json, 'riskScore'),
      createdAt: JsonFields.requiredDateTime(json, 'createdAt'),
      completedAt: _requiredNullableDateTime(json, 'completedAt'),
      failureCode: _optionalString(json, 'failureCode'),
      failureMessage: _optionalString(json, 'failureMessage'),
      reasonCodes: json.containsKey('reasonCodes')
          ? JsonFields.requiredStringList(json, 'reasonCodes')
          : const [],
    );
  }

  static double? _requiredNullableDouble(
    Map<String, Object?> json,
    String key,
  ) {
    if (!json.containsKey(key)) {
      throw FormatException('$key is missing.');
    }
    final value = json[key];
    if (value == null) return null;
    if (value is! num || !value.isFinite) {
      throw FormatException('$key is invalid.');
    }
    return value.toDouble();
  }

  static DateTime? _requiredNullableDateTime(
    Map<String, Object?> json,
    String key,
  ) {
    if (!json.containsKey(key)) {
      throw FormatException('$key is missing.');
    }
    final value = json[key];
    if (value == null) return null;
    final parsed = value is String ? DateTime.tryParse(value) : null;
    if (parsed == null) throw FormatException('$key is invalid.');
    return parsed.toUtc();
  }

  static String? _optionalString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null) return null;
    final parsed = value is String ? value.trim() : '';
    if (parsed.isEmpty) throw FormatException('$key is invalid.');
    return parsed;
  }
}
