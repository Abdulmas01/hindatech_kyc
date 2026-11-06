import 'dart:io';

import '../config/kyc_config.dart';
import '../core/async/polling_runner.dart';
import '../core/network/api_exception.dart';
import '../core/network/multipart_file_request.dart';
import '../core/network/session_api_client.dart';
import '../session/hosted_asset.dart';
import '../session/hosted_asset_submission.dart';
import '../session/session_bootstrap_exception.dart';
import '../session/verification_session.dart';
import '../session/verification_session_policies.dart';
import '../session/verification_session_state.dart';
import '../session/verification_payload.dart';
import '../session/verification_polling.dart';

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
      MultipartFileRequest(
        fields: {'inputType': normalizedInputType},
        filePath: request.filePath,
        contentType: resolvedContentType,
      ),
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

  /// Attaches one structured payload declared by the active workflow.
  Future<VerificationPayloadReceipt> attachPayload(
    VerificationPayloadRequest request,
  ) async {
    if (!session.allows(VerificationSessionAction.writePayload)) {
      throw StateError('This session does not allow payload attachment.');
    }
    final payloadType = request.payloadType.trim();
    if (!session.requiredInputs.allowsPayloadType(payloadType)) {
      throw ArgumentError.value(
        request.payloadType,
        'payloadType',
        'Must be declared by the verification workflow.',
      );
    }

    final response = await _apiClient.post(
      _apiClient.endpoints.sdkVerificationPayloads(
        session.verificationSessionId,
      ),
      body: request.toJson(),
    );
    try {
      final receipt = VerificationPayloadReceipt.fromJson(response);
      if (receipt.payloadTypeValue != payloadType) {
        throw const FormatException('Attached payload type is invalid.');
      }
      return receipt;
    } catch (error) {
      throw _invalidResponse(
        'The verification service returned an invalid payload receipt.',
        error,
      );
    }
  }

  /// Recovers current SDK state and every unexpired staged hosted asset.
  ///
  /// Multiple assets may be returned for one input type. The caller must keep
  /// or choose an exact [HostedAsset.assetKey] before submission.
  Future<VerificationSessionState> recoverSession() async {
    if (!session.allows(VerificationSessionAction.readSession)) {
      throw StateError('This session does not allow state recovery.');
    }

    final response = await _apiClient.get(
      _apiClient.endpoints.sdkVerificationSession(
        session.verificationSessionId,
      ),
    );
    try {
      final state = VerificationSessionState.fromJson(response);
      if (state.verificationSessionId != session.verificationSessionId ||
          state.workflowKey != session.workflowKey) {
        throw const FormatException('Recovered session identity is invalid.');
      }
      return state;
    } catch (error) {
      throw _invalidResponse(
        'The verification service returned invalid session state.',
        error,
      );
    }
  }

  /// Polls recoverable SDK state until a terminal status is received.
  ///
  /// The first request is immediate. Later requests use the backend-provided
  /// interval unless [options] overrides it. Requests never overlap, and
  /// cancelling the stream subscription prevents further polling.
  Stream<VerificationSessionState> pollSession([
    VerificationPollingOptions options = const VerificationPollingOptions(),
  ]) {
    options.validate();
    return PollingRunner.run(
      PollingTask(
        load: recoverSession,
        shouldContinue: (state) => !state.isTerminal,
        interval: options.interval ?? session.polling.recommendedInterval,
        timeout: options.timeout,
      ),
    );
  }

  /// Submits exact hosted asset keys selected for the workflow input slots.
  Future<VerificationSubmission> submitHostedAssets(
    HostedAssetSubmissionRequest request,
  ) async {
    if (!session.allows(VerificationSessionAction.submitSession)) {
      throw StateError('This session does not allow submission.');
    }
    if (session.assetIngestionMode != AssetIngestionMode.smartKycHosted) {
      throw StateError('This session does not use hosted asset submission.');
    }
    _validateHostedAssetSelection(request.assets);

    final response = await _apiClient.post(
      _apiClient.endpoints.sdkHostedAssetSubmit(
        session.verificationSessionId,
      ),
      body: request.toJson(),
    );
    try {
      final submission = VerificationSubmission.fromJson(response);
      if (submission.verificationSessionId != session.verificationSessionId) {
        throw const FormatException('Submitted session identity is invalid.');
      }
      return submission;
    } catch (error) {
      throw _invalidResponse(
        'The verification service returned an invalid submission.',
        error,
      );
    }
  }

  void _validateHostedAssetSelection(Map<String, String> assets) {
    if (assets.isEmpty) {
      throw ArgumentError.value(
        assets,
        'assets',
        'Must contain the workflow asset selections.',
      );
    }
    for (final entry in assets.entries) {
      if (!session.requiredInputs.allowsAssetType(entry.key) ||
          entry.value.trim().isEmpty) {
        throw ArgumentError.value(
          assets,
          'assets',
          'Contains an undeclared input type or empty asset key.',
        );
      }
    }
    final missingRequired = session.requiredInputs.requiredAssetTypes
        .where((inputType) => !assets.containsKey(inputType));
    if (missingRequired.isNotEmpty) {
      throw ArgumentError.value(
        assets,
        'assets',
        'Missing required workflow asset selections.',
      );
    }
  }

  static ApiException _invalidResponse(String message, Object cause) {
    return ApiException(
      failure: ApiFailure.invalidResponse,
      message: message,
      cause: cause,
    );
  }

  /// Releases network resources owned by this client.
  void close() => _apiClient.close();
}
