import '../config/kyc_config.dart';
import '../core/network/session_api_client.dart';
import '../session/session_bootstrap_exception.dart';
import '../session/verification_session.dart';

/// Loads a verification session from the application's trusted backend.
///
/// The application owns this request because its endpoint and user
/// authentication are customer-specific. The returned map must be the NestJS
/// SDK bootstrap response for one verification session.
typedef VerificationSessionProvider = Future<Map<String, Object?>> Function();

/// Holds the validated configuration and session used by an SDK workflow.
class KycClient {
  KycClient._({
    required this.config,
    required this.session,
  }) : _apiClient = SessionApiClient(config: config, session: session);

  final KycConfig config;
  final VerificationSession session;
  final SessionApiClient _apiClient;

  /// Creates a client from an already parsed session.
  ///
  /// Long-lived customer API credentials must never be used as the session
  /// token. Session scope and expiry must also be enforced by the backend.
  factory KycClient.fromSession({
    required KycConfig config,
    required VerificationSession session,
  }) {
    _ensureSessionIsActive(session);
    return KycClient._(config: config, session: session);
  }

  /// Requests a session through the host application and validates its shape.
  static Future<KycClient> bootstrap({
    required KycConfig config,
    required VerificationSessionProvider sessionProvider,
  }) async {
    late final Map<String, Object?> payload;
    try {
      payload = await sessionProvider();
    } catch (error) {
      throw SessionBootstrapException(
        failure: SessionBootstrapFailure.provider,
        message: 'The application could not create a verification session.',
        cause: error,
      );
    }

    late final VerificationSession session;
    try {
      session = VerificationSession.fromJson(payload);
    } catch (error) {
      throw SessionBootstrapException(
        failure: SessionBootstrapFailure.invalidResponse,
        message: 'The verification session response is invalid.',
        cause: error,
      );
    }

    return KycClient.fromSession(config: config, session: session);
  }

  static void _ensureSessionIsActive(VerificationSession session) {
    if (session.isExpired) {
      throw const SessionBootstrapException(
        failure: SessionBootstrapFailure.expiredSession,
        message: 'The verification session has expired.',
      );
    }
  }

  /// Releases network resources owned by this client.
  void close() => _apiClient.close();
}
