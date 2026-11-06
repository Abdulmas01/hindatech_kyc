import '../core/serialization/json_fields.dart';

/// A known asset slot declared by a verification workflow.
enum CaptureAssetType {
  documentFront('document_front'),
  documentBack('document_back'),
  selfiePrimary('selfie_primary'),
  referenceFace('reference_face'),
  livenessFrame('liveness_frame'),
  unknown('unknown');

  const CaptureAssetType(this.wireValue);

  final String wireValue;

  static CaptureAssetType fromWireValue(String value) {
    for (final type in values) {
      if (type != unknown && type.wireValue == value) return type;
    }
    return unknown;
  }
}

/// A known structured payload slot declared by a verification workflow.
enum VerificationPayloadType {
  subjectAnchor('subject_anchor'),
  subjectProfile('subject_profile'),
  subjectContact('subject_contact'),
  subjectMetadata('subject_metadata'),
  referenceProvenance('reference_provenance'),
  ninLookupRequest('nin_lookup_request'),
  unknown('unknown');

  const VerificationPayloadType(this.wireValue);

  final String wireValue;

  static VerificationPayloadType fromWireValue(String value) {
    for (final type in values) {
      if (type != unknown && type.wireValue == value) return type;
    }
    return unknown;
  }
}

/// One asset slot requested by the selected workflow.
class CaptureRequirement {
  const CaptureRequirement({
    required this.assetTypeValue,
    required this.isRequired,
  });

  final String assetTypeValue;
  final bool isRequired;

  CaptureAssetType get assetType =>
      CaptureAssetType.fromWireValue(assetTypeValue);
}

/// NestJS-owned workflow inputs returned during SDK bootstrap and recovery.
class VerificationRequiredInputs {
  VerificationRequiredInputs({
    required List<String> requiredAssetTypes,
    required List<String> optionalAssetTypes,
    required List<String> requiredPayloadTypes,
    required List<String> optionalPayloadTypes,
    required List<String> requiredAllOfFields,
    required List<String> requiredAnyOfFields,
  })  : requiredAssetTypes = List.unmodifiable(requiredAssetTypes),
        optionalAssetTypes = List.unmodifiable(optionalAssetTypes),
        requiredPayloadTypes = List.unmodifiable(requiredPayloadTypes),
        optionalPayloadTypes = List.unmodifiable(optionalPayloadTypes),
        requiredAllOfFields = List.unmodifiable(requiredAllOfFields),
        requiredAnyOfFields = List.unmodifiable(requiredAnyOfFields);

  final List<String> requiredAssetTypes;
  final List<String> optionalAssetTypes;
  final List<String> requiredPayloadTypes;
  final List<String> optionalPayloadTypes;
  final List<String> requiredAllOfFields;
  final List<String> requiredAnyOfFields;

  Iterable<CaptureRequirement> get assetRequirements sync* {
    for (final value in requiredAssetTypes) {
      yield CaptureRequirement(assetTypeValue: value, isRequired: true);
    }
    for (final value in optionalAssetTypes) {
      yield CaptureRequirement(assetTypeValue: value, isRequired: false);
    }
  }

  bool allowsAssetType(String value) =>
      requiredAssetTypes.contains(value) || optionalAssetTypes.contains(value);

  bool allowsPayloadType(String value) =>
      requiredPayloadTypes.contains(value) ||
      optionalPayloadTypes.contains(value);

  factory VerificationRequiredInputs.fromJson(Map<String, Object?> json) {
    return VerificationRequiredInputs(
      requiredAssetTypes:
          JsonFields.requiredStringList(json, 'requiredAssetTypes'),
      optionalAssetTypes:
          JsonFields.requiredStringList(json, 'optionalAssetTypes'),
      requiredPayloadTypes:
          JsonFields.requiredStringList(json, 'requiredPayloadTypes'),
      optionalPayloadTypes:
          JsonFields.requiredStringList(json, 'optionalPayloadTypes'),
      requiredAllOfFields:
          JsonFields.requiredStringList(json, 'requiredAllOfFields'),
      requiredAnyOfFields:
          JsonFields.requiredStringList(json, 'requiredAnyOfFields'),
    );
  }
}
