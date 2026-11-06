/// Categorizes failures returned by the verification API transport.
enum ApiFailure {
  connection,
  timeout,
  unauthorized,
  forbidden,
  rateLimited,
  rejected,
  server,
  invalidResponse,
  expiredSession,
}

/// A typed API failure that is safe to present to application error handling.
///
/// Response bodies and authorization tokens are intentionally excluded.
class ApiException implements Exception {
  const ApiException({
    required this.failure,
    required this.message,
    this.statusCode,
    this.code,
    this.details = const {},
    this.cause,
  });

  final ApiFailure failure;
  final String message;
  final int? statusCode;

  /// Stable NestJS error code for programmatic handling, when supplied.
  final String? code;

  /// Non-standard error envelope fields such as submission input details.
  ///
  /// Authentication tokens and raw response bodies are never included.
  final Map<String, Object?> details;
  final Object? cause;

  bool get isRetryable =>
      failure == ApiFailure.connection ||
      failure == ApiFailure.timeout ||
      failure == ApiFailure.rateLimited ||
      failure == ApiFailure.server;

  @override
  String toString() => 'ApiException: $message';
}
