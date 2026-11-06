import 'dart:io';

import '../config/kyc_config.dart';
import '../core/network/api_exception.dart';
import '../core/network/session_api_client.dart';
import '../session/hosted_asset.dart';
import '../session/session_bootstrap_exception.dart';
import '../session/verification_session.dart';
import '../session/verification_session_policies.dart';

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

  /// Stages one workflow-declared asset through the NestJS hosted upload.
  ///
  /// Repeated uploads for the same input type create separate staged assets.
  /// Keep the returned [HostedAsset.assetKey] and submit that exact key later.
  /// After an ambiguous timeout, recover session state before retrying.
  Future<HostedAsset> uploadHostedAsset(
    HostedAssetUploadRequest request,
  ) async {
    final normalizedInputType = request.inputType.trim();
    if (!session.allows(VerificationSessionAction.uploadAsset)) {
      throw StateError('This session does not allow asset upload.');
    }
    if (session.assetIngestionMode != AssetIngestionMode.smartKycHosted ||
        !session.supportedAssetIngestionModeValues
            .contains(AssetIngestionMode.smartKycHosted.wireValue)) {
      throw StateError('This session does not allow hosted asset upload.');
    }
    if (!session.requiredInputs.allowsAssetType(normalizedInputType)) {
      throw ArgumentError.value(
        request.inputType,
        'inputType',
        'Must be declared by the verification workflow.',
      );
    }

    final file = File(request.filePath);
    if (!await file.exists()) {
      throw FileSystemException(
        'The upload file does not exist.',
        request.filePath,
      );
    }
    final sizeBytes = await file.length();
    if (sizeBytes > session.uploadPolicy.maxFileSizeBytes) {
      throw ArgumentError.value(
        sizeBytes,
        'filePath',
        'File exceeds the session upload limit.',
      );
    }

    final resolvedContentType = request.contentType?.trim().toLowerCase() ??
        _contentTypeForPath(request.filePath);
    if (!session.uploadPolicy.acceptedMimeTypes.contains(resolvedContentType)) {
      throw ArgumentError.value(
        resolvedContentType,
        'contentType',
        'Must be accepted by the session upload policy.',
      );
    }

    final response = await _apiClient.postMultipart(
      _apiClient.endpoints.sdkHostedAssets(session.verificationSessionId),
      fields: {'inputType': normalizedInputType},
      filePath: request.filePath,
      contentType: resolvedContentType,
    );

    try {
      final asset = HostedAsset.fromJson(response);
      if (asset.verificationSessionId != session.verificationSessionId ||
          asset.inputTypeValue != normalizedInputType) {
        throw const FormatException('Hosted asset identity is invalid.');
      }
      return asset;
    } catch (error) {
      throw ApiException(
        failure: ApiFailure.invalidResponse,
        message: 'The verification service returned an invalid asset.',
        cause: error,
      );
    }
  }

  static String _contentTypeForPath(String filePath) {
    final path = filePath.toLowerCase();
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'image/jpeg';
    if (path.endsWith('.png')) return 'image/png';
    return 'application/octet-stream';
  }

  /// Releases network resources owned by this client.
  void close() => _apiClient.close();
}
