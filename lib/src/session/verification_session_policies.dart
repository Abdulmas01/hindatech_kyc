import '../core/serialization/json_fields.dart';

enum AssetIngestionMode {
  smartKycHosted('smartkyc_hosted'),
  externalReference('external_reference'),
  unknown('unknown');

  const AssetIngestionMode(this.wireValue);

  final String wireValue;

  static AssetIngestionMode fromWireValue(String value) {
    for (final mode in values) {
      if (mode != unknown && mode.wireValue == value) return mode;
    }
    return unknown;
  }
}

/// Backend-provided limits and transport details for hosted asset upload.
class VerificationUploadPolicy {
  VerificationUploadPolicy({
    required this.modeValue,
    required this.maxFileSizeBytes,
    required List<String> acceptedMimeTypes,
    required this.redirectsAllowed,
    required this.uploadTransportValue,
    required this.proxyUploadUrlTemplate,
  }) : acceptedMimeTypes = List.unmodifiable(acceptedMimeTypes);

  final String modeValue;
  final int maxFileSizeBytes;
  final List<String> acceptedMimeTypes;
  final bool redirectsAllowed;
  final String uploadTransportValue;
  final String proxyUploadUrlTemplate;

  AssetIngestionMode get mode => AssetIngestionMode.fromWireValue(modeValue);

  factory VerificationUploadPolicy.fromJson(Map<String, Object?> json) {
    final maxFileSizeBytes = json['maxFileSizeBytes'];
    if (maxFileSizeBytes is! int || maxFileSizeBytes <= 0) {
      throw const FormatException('Upload maxFileSizeBytes is invalid.');
    }
    final redirectsAllowed = json['redirectsAllowed'];
    if (redirectsAllowed is! bool) {
      throw const FormatException('Upload redirectsAllowed is invalid.');
    }
    return VerificationUploadPolicy(
      modeValue: JsonFields.requiredString(json, 'mode'),
      maxFileSizeBytes: maxFileSizeBytes,
      acceptedMimeTypes:
          JsonFields.requiredStringList(json, 'acceptedMimeTypes'),
      redirectsAllowed: redirectsAllowed,
      uploadTransportValue: JsonFields.requiredString(json, 'uploadTransport'),
      proxyUploadUrlTemplate:
          JsonFields.requiredString(json, 'proxyUploadUrlTemplate'),
    );
  }
}

/// Backend-provided polling location and starting interval.
class VerificationPollingPolicy {
  const VerificationPollingPolicy({
    required this.statusPath,
    required this.recommendedInterval,
  });

  final String statusPath;
  final Duration recommendedInterval;

  factory VerificationPollingPolicy.fromJson(Map<String, Object?> json) {
    final intervalMs = json['recommendedIntervalMs'];
    if (intervalMs is! int || intervalMs <= 0) {
      throw const FormatException('Polling interval is invalid.');
    }
    return VerificationPollingPolicy(
      statusPath: JsonFields.requiredString(json, 'statusUrl'),
      recommendedInterval: Duration(milliseconds: intervalMs),
    );
  }
}

/// Backend-provided behavior for replacing an expired SDK session.
class VerificationRebootstrapPolicy {
  const VerificationRebootstrapPolicy({
    required this.createOrResumePath,
    required this.idempotencyRequired,
    required this.expiredSessionBehaviorValue,
  });

  final String createOrResumePath;
  final bool idempotencyRequired;
  final String expiredSessionBehaviorValue;

  factory VerificationRebootstrapPolicy.fromJson(Map<String, Object?> json) {
    final idempotencyRequired = json['idempotencyRequired'];
    if (idempotencyRequired is! bool) {
      throw const FormatException(
          'Rebootstrap idempotencyRequired is invalid.');
    }
    return VerificationRebootstrapPolicy(
      createOrResumePath: JsonFields.requiredString(json, 'createOrResumeUrl'),
      idempotencyRequired: idempotencyRequired,
      expiredSessionBehaviorValue:
          JsonFields.requiredString(json, 'expiredSessionBehavior'),
    );
  }
}
