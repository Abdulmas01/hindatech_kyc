import 'dart:math';

import '../core/serialization/json_fields.dart';

enum VerificationLivenessCaptureMode {
  passiveWithActiveGuidance('passive_with_active_guidance'),
  unknown('unknown');

  const VerificationLivenessCaptureMode(this.wireValue);

  final String wireValue;

  static VerificationLivenessCaptureMode fromWireValue(String value) {
    for (final mode in values) {
      if (mode != unknown && mode.wireValue == value) return mode;
    }
    return unknown;
  }
}

enum VerificationLivenessDecisionAuthority {
  backend('backend'),
  unknown('unknown');

  const VerificationLivenessDecisionAuthority(this.wireValue);

  final String wireValue;

  static VerificationLivenessDecisionAuthority fromWireValue(String value) {
    for (final authority in values) {
      if (authority != unknown && authority.wireValue == value) {
        return authority;
      }
    }
    return unknown;
  }
}

enum VerificationLivenessActiveGuidanceRole {
  guidanceOnly('guidance_only'),
  unknown('unknown');

  const VerificationLivenessActiveGuidanceRole(this.wireValue);

  final String wireValue;

  static VerificationLivenessActiveGuidanceRole fromWireValue(String value) {
    for (final role in values) {
      if (role != unknown && role.wireValue == value) return role;
    }
    return unknown;
  }
}

enum VerificationLivenessChallenge {
  blink('blink'),
  turnLeft('turn_left'),
  turnRight('turn_right'),
  unknown('unknown');

  const VerificationLivenessChallenge(this.wireValue);

  final String wireValue;

  static VerificationLivenessChallenge fromWireValue(String value) {
    for (final challenge in values) {
      if (challenge != unknown && challenge.wireValue == value) {
        return challenge;
      }
    }
    return unknown;
  }
}

/// Backend-owned capture guidance for workflows that execute liveness.
///
/// Active challenge completion is capture guidance only when
/// [activeGuidanceRole] is [VerificationLivenessActiveGuidanceRole.guidanceOnly].
/// It must never be converted into a successful local liveness decision.
class VerificationLivenessPolicy {
  VerificationLivenessPolicy({
    required this.version,
    required this.modeValue,
    required this.decisionAuthorityValue,
    required this.activeGuidanceRoleValue,
    required this.challengeCount,
    required List<String> allowedChallengeValues,
    required this.randomize,
    required this.challengeTimeout,
    required this.alignmentStabilityFrames,
    required this.requireSingleFace,
    required this.requireNeutralPose,
    required this.requireReturnToNeutral,
    required this.temporalEvidenceSupported,
  }) : allowedChallengeValues = List.unmodifiable(allowedChallengeValues);

  final String version;
  final String modeValue;
  final String decisionAuthorityValue;
  final String activeGuidanceRoleValue;
  final int challengeCount;
  final List<String> allowedChallengeValues;
  final bool randomize;
  final Duration challengeTimeout;
  final int alignmentStabilityFrames;
  final bool requireSingleFace;
  final bool requireNeutralPose;
  final bool requireReturnToNeutral;
  final bool temporalEvidenceSupported;

  VerificationLivenessCaptureMode get mode =>
      VerificationLivenessCaptureMode.fromWireValue(modeValue);

  VerificationLivenessDecisionAuthority get decisionAuthority =>
      VerificationLivenessDecisionAuthority.fromWireValue(
        decisionAuthorityValue,
      );

  VerificationLivenessActiveGuidanceRole get activeGuidanceRole =>
      VerificationLivenessActiveGuidanceRole.fromWireValue(
        activeGuidanceRoleValue,
      );

  List<VerificationLivenessChallenge> get allowedChallenges =>
      List.unmodifiable(
        allowedChallengeValues.map(
          VerificationLivenessChallenge.fromWireValue,
        ),
      );

  bool get isGuidanceOnly =>
      activeGuidanceRole == VerificationLivenessActiveGuidanceRole.guidanceOnly;

  bool get isBackendAuthoritative =>
      decisionAuthority == VerificationLivenessDecisionAuthority.backend;

  /// Whether this contract permits ordered challenge evidence submission.
  bool get canSubmitTemporalEvidence => temporalEvidenceSupported;

  /// Selects the active guidance sequence declared by this session policy.
  ///
  /// The sequence is randomized only when instructed by NestJS. Unknown future
  /// challenge values are rejected here because this SDK cannot render them.
  List<VerificationLivenessChallenge> createGuidanceSequence() {
    final challenges = allowedChallenges.toList(growable: true);
    if (challenges.contains(VerificationLivenessChallenge.unknown)) {
      throw UnsupportedError(
        'The liveness policy contains an unsupported guidance challenge.',
      );
    }
    if (randomize) challenges.shuffle(Random.secure());
    return List.unmodifiable(challenges.take(challengeCount));
  }

  factory VerificationLivenessPolicy.fromJson(Map<String, Object?> json) {
    final challengeCount = _positiveInt(json, 'challengeCount');
    final allowedChallengeValues =
        JsonFields.requiredStringList(json, 'allowedChallenges');
    if (allowedChallengeValues.length < challengeCount) {
      throw const FormatException(
        'allowedChallenges cannot satisfy challengeCount.',
      );
    }
    final timeoutMs = _positiveInt(json, 'challengeTimeoutMs');

    return VerificationLivenessPolicy(
      version: JsonFields.requiredString(json, 'version'),
      modeValue: JsonFields.requiredString(json, 'mode'),
      decisionAuthorityValue:
          JsonFields.requiredString(json, 'decisionAuthority'),
      activeGuidanceRoleValue:
          JsonFields.requiredString(json, 'activeGuidanceRole'),
      challengeCount: challengeCount,
      allowedChallengeValues: allowedChallengeValues,
      randomize: _requiredBool(json, 'randomize'),
      challengeTimeout: Duration(milliseconds: timeoutMs),
      alignmentStabilityFrames: _positiveInt(json, 'alignmentStabilityFrames'),
      requireSingleFace: _requiredBool(json, 'requireSingleFace'),
      requireNeutralPose: _requiredBool(json, 'requireNeutralPose'),
      requireReturnToNeutral: _requiredBool(json, 'requireReturnToNeutral'),
      temporalEvidenceSupported:
          _requiredBool(json, 'temporalEvidenceSupported'),
    );
  }

  /// Reads the required nullable policy field used by SDK session contracts.
  static VerificationLivenessPolicy? readNullable(
    Map<String, Object?> json,
  ) {
    if (!json.containsKey('livenessPolicy')) {
      throw const FormatException('livenessPolicy is missing.');
    }
    final value = json['livenessPolicy'];
    if (value == null) return null;
    if (value is! Map) {
      throw const FormatException('livenessPolicy is invalid.');
    }
    return VerificationLivenessPolicy.fromJson(
      Map<String, Object?>.from(value),
    );
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
