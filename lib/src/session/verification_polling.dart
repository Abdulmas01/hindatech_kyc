/// Host-controlled limits for SDK session polling.
class VerificationPollingOptions {
  const VerificationPollingOptions({
    this.interval,
    this.timeout,
  });

  /// Overrides the backend-recommended polling interval when provided.
  final Duration? interval;

  /// Stops polling with a [TimeoutException] after this duration.
  final Duration? timeout;

  void validate() {
    if (interval != null && interval! <= Duration.zero) {
      throw ArgumentError.value(
        interval,
        'interval',
        'Must be greater than zero.',
      );
    }
    if (timeout != null && timeout! <= Duration.zero) {
      throw ArgumentError.value(
        timeout,
        'timeout',
        'Must be greater than zero.',
      );
    }
  }
}
