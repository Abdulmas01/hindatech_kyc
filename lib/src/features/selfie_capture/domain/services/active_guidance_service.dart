import '../../../../session/verification_liveness_policy.dart';
import '../models/active_guidance.dart';
import '../models/face_alignment.dart';

typedef GuidanceClock = DateTime Function();

class ActiveGuidanceService {
  ActiveGuidanceService({
    required ActiveGuidanceConfig config,
    GuidanceClock? clock,
  })  : _policy = config.policy,
        _config = config.detection,
        _clock = clock ?? DateTime.now {
    _validatePolicy();
    _restart();
  }

  final VerificationLivenessPolicy _policy;
  final ActiveGuidanceDetectionConfig _config;
  final GuidanceClock _clock;

  late List<VerificationLivenessChallenge> _sequence;
  late ActiveGuidanceState _state;
  int _challengeIndex = 0;
  bool _blinkPrimed = false;
  int? _trackingId;

  ActiveGuidanceState get state => _state;

  ActiveGuidanceState evaluate(ActiveGuidanceFrame frame) {
    if (_isTerminal) return _state;
    final now = _clock();
    if (_deadlineReached(now)) return _timeOut();

    final face = _usableFace(frame);
    if (face == null) return _alignFace(frame.alignment.assessment.signal);
    _trackFace(face);

    return switch (_state.phase) {
      ActiveGuidancePhase.awaitingAlignment =>
        _evaluateInitialAlignment(frame, now),
      ActiveGuidancePhase.performingChallenge => _evaluateChallenge(
          _GuidanceEvaluationContext(frame: frame, face: face, now: now),
        ),
      ActiveGuidancePhase.returningToNeutral => _evaluateReturnToNeutral(
          _GuidanceEvaluationContext(frame: frame, face: face, now: now),
        ),
      ActiveGuidancePhase.awaitingCaptureAlignment =>
        _evaluateCaptureAlignment(frame),
      ActiveGuidancePhase.captureSuggested ||
      ActiveGuidancePhase.timedOut =>
        _state,
    };
  }

  ActiveGuidanceState checkTimeout() {
    if (_isTerminal) return _state;
    return _deadlineReached(_clock()) ? _timeOut() : _state;
  }

  ActiveGuidanceState restart() {
    _restart();
    return _state;
  }

  bool get _isTerminal =>
      _state.phase == ActiveGuidancePhase.captureSuggested ||
      _state.phase == ActiveGuidancePhase.timedOut;

  void _validatePolicy() {
    if (_policy.mode !=
        VerificationLivenessCaptureMode.passiveWithActiveGuidance) {
      throw UnsupportedError(
        'The SDK does not support this liveness capture mode.',
      );
    }
    if (!_policy.isGuidanceOnly) {
      throw UnsupportedError(
        'The SDK supports active liveness challenges as guidance only.',
      );
    }
    if (!_policy.isBackendAuthoritative) {
      throw UnsupportedError(
        'The SDK requires backend-authoritative liveness decisions.',
      );
    }
  }

  void _restart() {
    _sequence = _policy.createGuidanceSequence();
    _challengeIndex = 0;
    _blinkPrimed = false;
    _trackingId = null;
    _state = ActiveGuidanceState(
      phase: ActiveGuidancePhase.awaitingAlignment,
      signal: ActiveGuidanceSignal.alignFace,
      activeChallenge: null,
      completedChallengeCount: 0,
      totalChallengeCount: _sequence.length,
      challengeDeadline: null,
      alignmentSignal: null,
    );
  }

  ActiveGuidanceFace? _usableFace(ActiveGuidanceFrame frame) {
    if (frame.faceCount == 0) {
      _blinkPrimed = false;
      _trackingId = null;
      return null;
    }
    if (_policy.requireSingleFace && frame.faceCount != 1) {
      _blinkPrimed = false;
      _trackingId = null;
      return null;
    }
    return frame.primaryFace;
  }

  void _trackFace(ActiveGuidanceFace face) {
    final nextTrackingId = face.trackingId;
    if (_trackingId != null &&
        nextTrackingId != null &&
        _trackingId != nextTrackingId) {
      _blinkPrimed = false;
    }
    _trackingId = nextTrackingId;
  }

  ActiveGuidanceState _evaluateInitialAlignment(
    ActiveGuidanceFrame frame,
    DateTime now,
  ) {
    if (!frame.alignment.suggestsCaptureReady) {
      return _alignFace(frame.alignment.assessment.signal);
    }
    return _activateChallenge(now);
  }

  ActiveGuidanceState _evaluateChallenge(_GuidanceEvaluationContext context) {
    final challenge = _sequence[_challengeIndex];
    if (!_framingSupportsChallenge(context.frame, challenge)) {
      return _alignFace(context.frame.alignment.assessment.signal);
    }

    return switch (challenge) {
      VerificationLivenessChallenge.blink =>
        _evaluateBlink(context.face, context.now),
      VerificationLivenessChallenge.turnLeft ||
      VerificationLivenessChallenge.turnRight =>
        _evaluateHeadTurn(context.face, context.now),
      VerificationLivenessChallenge.unknown => throw UnsupportedError(
          'The liveness policy contains an unsupported guidance challenge.',
        ),
    };
  }

  bool _framingSupportsChallenge(
    ActiveGuidanceFrame frame,
    VerificationLivenessChallenge challenge,
  ) {
    final signal = frame.alignment.assessment.signal;
    if (signal == FaceAlignmentSignal.aligned) return true;
    final isHeadTurn = challenge == VerificationLivenessChallenge.turnLeft ||
        challenge == VerificationLivenessChallenge.turnRight;
    return isHeadTurn &&
        (signal == FaceAlignmentSignal.lookStraight ||
            signal == FaceAlignmentSignal.holdStill);
  }

  ActiveGuidanceState _evaluateBlink(
    ActiveGuidanceFace face,
    DateTime now,
  ) {
    final left = face.leftEyeOpenProbability;
    final right = face.rightEyeOpenProbability;
    if (left == null || right == null) {
      return _withSignal(ActiveGuidanceSignal.faceNotClear);
    }
    if (left > _config.blinkOpenThreshold &&
        right > _config.blinkOpenThreshold) {
      _blinkPrimed = true;
      return _withSignal(ActiveGuidanceSignal.blink);
    }
    if (_blinkPrimed &&
        left < _config.blinkClosedThreshold &&
        right < _config.blinkClosedThreshold) {
      _blinkPrimed = false;
      return _completeGesture(now);
    }
    return _withSignal(ActiveGuidanceSignal.blink);
  }

  ActiveGuidanceState _evaluateHeadTurn(
    ActiveGuidanceFace face,
    DateTime now,
  ) {
    final yaw = face.yawDegrees;
    if (yaw == null) {
      return _withSignal(ActiveGuidanceSignal.faceNotClear);
    }
    final challenge = _sequence[_challengeIndex];
    final completed = switch (challenge) {
      VerificationLivenessChallenge.turnLeft =>
        yaw < -_config.headTurnThresholdDegrees,
      VerificationLivenessChallenge.turnRight =>
        yaw > _config.headTurnThresholdDegrees,
      VerificationLivenessChallenge.blink ||
      VerificationLivenessChallenge.unknown =>
        false,
    };
    return completed
        ? _completeGesture(now)
        : _withSignal(_signalFor(challenge));
  }

  ActiveGuidanceState _completeGesture(DateTime now) {
    if (_policy.requireReturnToNeutral) {
      _state = _copyState(
        phase: ActiveGuidancePhase.returningToNeutral,
        signal: ActiveGuidanceSignal.returnToNeutral,
      );
      return _state;
    }
    return _advance(now);
  }

  ActiveGuidanceState _evaluateReturnToNeutral(
    _GuidanceEvaluationContext context,
  ) {
    if (!context.frame.alignment.suggestsCaptureReady ||
        !_returnedToNeutral(context.face)) {
      return _withSignal(ActiveGuidanceSignal.returnToNeutral);
    }
    return _advance(context.now);
  }

  bool _returnedToNeutral(ActiveGuidanceFace face) {
    final challenge = _sequence[_challengeIndex];
    if (challenge == VerificationLivenessChallenge.blink) {
      final left = face.leftEyeOpenProbability;
      final right = face.rightEyeOpenProbability;
      return left != null &&
          right != null &&
          left > _config.blinkOpenThreshold &&
          right > _config.blinkOpenThreshold;
    }
    final yaw = face.yawDegrees;
    return yaw != null && yaw.abs() <= _config.neutralYawThresholdDegrees;
  }

  ActiveGuidanceState _advance(DateTime now) {
    final completed = _challengeIndex + 1;
    if (completed >= _sequence.length) {
      _state = ActiveGuidanceState(
        phase: ActiveGuidancePhase.awaitingCaptureAlignment,
        signal: ActiveGuidanceSignal.alignFace,
        activeChallenge: null,
        completedChallengeCount: completed,
        totalChallengeCount: _sequence.length,
        challengeDeadline: null,
        alignmentSignal: null,
      );
      return _state;
    }

    _challengeIndex++;
    _blinkPrimed = false;
    return _activateChallenge(now, completedChallengeCount: completed);
  }

  ActiveGuidanceState _activateChallenge(
    DateTime now, {
    int? completedChallengeCount,
  }) {
    final challenge = _sequence[_challengeIndex];
    _state = ActiveGuidanceState(
      phase: ActiveGuidancePhase.performingChallenge,
      signal: _signalFor(challenge),
      activeChallenge: challenge,
      completedChallengeCount:
          completedChallengeCount ?? _state.completedChallengeCount,
      totalChallengeCount: _sequence.length,
      challengeDeadline: now.add(_policy.challengeTimeout),
      alignmentSignal: null,
    );
    return _state;
  }

  ActiveGuidanceState _evaluateCaptureAlignment(ActiveGuidanceFrame frame) {
    if (!frame.alignment.suggestsCaptureReady) {
      return _alignFace(frame.alignment.assessment.signal);
    }
    _state = ActiveGuidanceState(
      phase: ActiveGuidancePhase.captureSuggested,
      signal: ActiveGuidanceSignal.captureSuggested,
      activeChallenge: null,
      completedChallengeCount: _sequence.length,
      totalChallengeCount: _sequence.length,
      challengeDeadline: null,
      alignmentSignal: FaceAlignmentSignal.aligned,
    );
    return _state;
  }

  ActiveGuidanceState _alignFace(FaceAlignmentSignal? alignmentSignal) {
    _state = _copyState(
      signal: ActiveGuidanceSignal.alignFace,
      alignmentSignal: alignmentSignal,
    );
    return _state;
  }

  ActiveGuidanceState _withSignal(ActiveGuidanceSignal signal) {
    _state = _copyState(signal: signal, alignmentSignal: null);
    return _state;
  }

  ActiveGuidanceState _timeOut() {
    _state = ActiveGuidanceState(
      phase: ActiveGuidancePhase.timedOut,
      signal: ActiveGuidanceSignal.timedOut,
      activeChallenge: _state.activeChallenge,
      completedChallengeCount: _state.completedChallengeCount,
      totalChallengeCount: _state.totalChallengeCount,
      challengeDeadline: _state.challengeDeadline,
      alignmentSignal: _state.alignmentSignal,
    );
    return _state;
  }

  bool _deadlineReached(DateTime now) {
    final deadline = _state.challengeDeadline;
    return deadline != null && !now.isBefore(deadline);
  }

  ActiveGuidanceSignal _signalFor(VerificationLivenessChallenge challenge) =>
      switch (challenge) {
        VerificationLivenessChallenge.blink => ActiveGuidanceSignal.blink,
        VerificationLivenessChallenge.turnLeft => ActiveGuidanceSignal.turnLeft,
        VerificationLivenessChallenge.turnRight =>
          ActiveGuidanceSignal.turnRight,
        VerificationLivenessChallenge.unknown => throw UnsupportedError(
            'The liveness policy contains an unsupported guidance challenge.',
          ),
      };

  ActiveGuidanceState _copyState({
    ActiveGuidancePhase? phase,
    ActiveGuidanceSignal? signal,
    FaceAlignmentSignal? alignmentSignal,
  }) {
    return ActiveGuidanceState(
      phase: phase ?? _state.phase,
      signal: signal ?? _state.signal,
      activeChallenge: _state.activeChallenge,
      completedChallengeCount: _state.completedChallengeCount,
      totalChallengeCount: _state.totalChallengeCount,
      challengeDeadline: _state.challengeDeadline,
      alignmentSignal: alignmentSignal,
    );
  }
}

class _GuidanceEvaluationContext {
  const _GuidanceEvaluationContext({
    required this.frame,
    required this.face,
    required this.now,
  });

  final ActiveGuidanceFrame frame;
  final ActiveGuidanceFace face;
  final DateTime now;
}
