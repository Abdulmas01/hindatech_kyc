import '../core/serialization/json_fields.dart';
import 'verification_required_inputs.dart';

/// One workflow-declared structured payload attachment.
///
/// Payload contents may contain sensitive identity context and should not be
/// logged, added to analytics, or persisted beyond the active session.
class VerificationPayloadRequest {
  VerificationPayloadRequest({
    required this.payloadType,
    required Map<String, Object?> payload,
    Map<String, Object?>? metadata,
  })  : payload = Map.unmodifiable(payload),
        metadata = metadata == null ? null : Map.unmodifiable(metadata);

  final String payloadType;
  final Map<String, Object?> payload;
  final Map<String, Object?>? metadata;

  Map<String, Object?> toJson() => {
        'payloadType': payloadType.trim(),
        'payload': payload,
        if (metadata != null) 'metadata': metadata,
      };
}

/// NestJS receipt for one attached structured payload revision.
class VerificationPayloadReceipt {
  const VerificationPayloadReceipt({
    required this.id,
    required this.payloadTypeValue,
    required this.revision,
  });

  final String id;
  final String payloadTypeValue;
  final int revision;

  VerificationPayloadType get payloadType =>
      VerificationPayloadType.fromWireValue(payloadTypeValue);

  factory VerificationPayloadReceipt.fromJson(Map<String, Object?> json) {
    final revision = json['revision'];
    if (revision is! int || revision <= 0) {
      throw const FormatException('revision is missing or invalid.');
    }
    return VerificationPayloadReceipt(
      id: JsonFields.requiredString(json, 'id'),
      payloadTypeValue: JsonFields.requiredString(json, 'payloadType'),
      revision: revision,
    );
  }
}
