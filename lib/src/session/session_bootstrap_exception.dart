/// Identifies the stage at which session bootstrap failed.
enum SessionBootstrapFailure {
  provider,
  invalidResponse,
  expiredSession,
}

/// A safe, typed failure produced while preparing a verification session.
///
/// Its message and string representation do not include the SDK token or the
/// bootstrap response, so they can be reported without leaking credentials.
/// The optional [cause] is intended for local diagnosis and may contain details
/// supplied by the host application's network layer.
class SessionBootstrapException implements Exception {
  const SessionBootstrapException({
    required this.failure,
    required this.message,
    this.cause,
  });

  final SessionBootstrapFailure failure;
  final String message;
  final Object? cause;

  @override
  String toString() => 'SessionBootstrapException: $message';
}
