import '../core/serialization/json_fields.dart';

enum VerificationDocumentQualityMode {
  guidanceOnly('guidance_only'),
  unknown('unknown');

  const VerificationDocumentQualityMode(this.wireValue);

  final String wireValue;

  static VerificationDocumentQualityMode fromWireValue(String value) {
    for (final mode in values) {
      if (mode != unknown && mode.wireValue == value) return mode;
    }
    return unknown;
  }
}

enum VerificationDocumentQualityDecisionAuthority {
  backend('backend'),
  unknown('unknown');

  const VerificationDocumentQualityDecisionAuthority(this.wireValue);

  final String wireValue;

  static VerificationDocumentQualityDecisionAuthority fromWireValue(
    String value,
  ) {
    for (final authority in values) {
      if (authority != unknown && authority.wireValue == value) {
        return authority;
      }
    }
    return unknown;
  }
}

enum VerificationDocumentQualitySignal {
  good('good'),
  blurry('blurry'),
  glare('glare'),
  dark('dark'),
  noDocument('no_document'),
  unknown('unknown');

  const VerificationDocumentQualitySignal(this.wireValue);

  final String wireValue;

  static VerificationDocumentQualitySignal fromWireValue(String value) {
    for (final signal in values) {
      if (signal != unknown && signal.wireValue == value) return signal;
    }
    return unknown;
  }
}

/// Backend-owned policy for optional device-local document quality guidance.
///
/// Local observations may improve capture guidance or trigger capture when
/// permitted, but they never replace backend document validation.
class VerificationDocumentQualityPolicy {
  VerificationDocumentQualityPolicy({
    required this.version,
    required this.modeValue,
    required this.decisionAuthorityValue,
    required this.localInferenceEnabled,
    required this.autoCaptureAllowed,
    required this.stabilityFrames,
    required this.samplingInterval,
    required List<String> supportedSignalValues,
    required Map<String, double> minimumConfidenceBySignal,
  })  : supportedSignalValues = List.unmodifiable(supportedSignalValues),
        minimumConfidenceBySignal = Map.unmodifiable(minimumConfidenceBySignal);

  final String version;
  final String modeValue;
  final String decisionAuthorityValue;
  final bool localInferenceEnabled;
  final bool autoCaptureAllowed;
  final int stabilityFrames;
  final Duration samplingInterval;
  final List<String> supportedSignalValues;
  final Map<String, double> minimumConfidenceBySignal;

  VerificationDocumentQualityMode get mode =>
      VerificationDocumentQualityMode.fromWireValue(modeValue);

  VerificationDocumentQualityDecisionAuthority get decisionAuthority =>
      VerificationDocumentQualityDecisionAuthority.fromWireValue(
        decisionAuthorityValue,
      );

  List<VerificationDocumentQualitySignal> get supportedSignals =>
      List.unmodifiable(
        supportedSignalValues.map(
          VerificationDocumentQualitySignal.fromWireValue,
        ),
      );

  bool get isGuidanceOnly =>
      mode == VerificationDocumentQualityMode.guidanceOnly;

  bool get isBackendAuthoritative =>
      decisionAuthority == VerificationDocumentQualityDecisionAuthority.backend;

  double? minimumConfidenceFor(VerificationDocumentQualitySignal signal) =>
      minimumConfidenceBySignal[signal.wireValue];

  factory VerificationDocumentQualityPolicy.fromJson(
    Map<String, Object?> json,
  ) {
    final supportedSignalValues =
        JsonFields.requiredStringList(json, 'supportedSignals');
    if (supportedSignalValues.isEmpty) {
      throw const FormatException('supportedSignals cannot be empty.');
    }

    final minimumConfidenceBySignal = _readConfidenceMap(
      JsonFields.requiredMap(json, 'minimumConfidenceBySignal'),
    );
    for (final signal in supportedSignalValues) {
      if (!minimumConfidenceBySignal.containsKey(signal)) {
        throw FormatException(
          'minimumConfidenceBySignal is missing "$signal".',
        );
      }
    }

    return VerificationDocumentQualityPolicy(
      version: JsonFields.requiredString(json, 'version'),
      modeValue: JsonFields.requiredString(json, 'mode'),
      decisionAuthorityValue:
          JsonFields.requiredString(json, 'decisionAuthority'),
      localInferenceEnabled: _requiredBool(json, 'localInferenceEnabled'),
      autoCaptureAllowed: _requiredBool(json, 'autoCaptureAllowed'),
      stabilityFrames: _positiveInt(json, 'stabilityFrames'),
      samplingInterval: Duration(
        milliseconds: _positiveInt(json, 'samplingIntervalMs'),
      ),
      supportedSignalValues: supportedSignalValues,
      minimumConfidenceBySignal: minimumConfidenceBySignal,
    );
  }

  /// Reads the required nullable policy field used by SDK session contracts.
  static VerificationDocumentQualityPolicy? readNullable(
    Map<String, Object?> json,
  ) {
    if (!json.containsKey('documentQualityPolicy')) {
      throw const FormatException('documentQualityPolicy is missing.');
    }
    final value = json['documentQualityPolicy'];
    if (value == null) return null;
    if (value is! Map) {
      throw const FormatException('documentQualityPolicy is invalid.');
    }
    return VerificationDocumentQualityPolicy.fromJson(
      Map<String, Object?>.from(value),
    );
  }

  static Map<String, double> _readConfidenceMap(
    Map<String, Object?> json,
  ) {
    final result = <String, double>{};
    for (final entry in json.entries) {
      final value = entry.value;
      if (entry.key.trim().isEmpty || value is! num) {
        throw const FormatException(
          'minimumConfidenceBySignal contains an invalid value.',
        );
      }
      final confidence = value.toDouble();
      if (!confidence.isFinite || confidence < 0 || confidence > 1) {
        throw const FormatException(
          'minimumConfidenceBySignal values must be between zero and one.',
        );
      }
      result[entry.key] = confidence;
    }
    return result;
  }

  static int _positiveInt(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! int || value <= 0) {
      throw FormatException('$key is missing or invalid.');
    }
    return value;
  }

  static bool _requiredBool(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! bool) {
      throw FormatException('$key is missing or invalid.');
    }
    return value;
  }
}
