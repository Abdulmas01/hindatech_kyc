import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../config/kyc_config.dart';
import '../../session/verification_session.dart';
import 'api_exception.dart';
import 'api_endpoints.dart';
import 'multipart_file_request.dart';

/// Performs API requests authorized by one short-lived verification session.
///
/// This transport is internal to the SDK so feature services share the same
/// endpoint, authorization, timeout, and failure-handling rules.
class SessionApiClient {
  SessionApiClient({
    required KycConfig config,
    required VerificationSession session,
    http.Client? httpClient,
  })  : _config = config,
        _session = session,
        _httpClient = httpClient ?? http.Client(),
        endpoints = ApiEndpoints(config.apiBaseUri);

  final KycConfig _config;
  final VerificationSession _session;
  final http.Client _httpClient;
  final ApiEndpoints endpoints;

  Future<Map<String, Object?>> get(Uri uri) => _send('GET', uri);

  Future<Map<String, Object?>> post(
    Uri uri, {
    Map<String, Object?>? body,
  }) =>
      _send('POST', uri, body: body);

  Future<Map<String, Object?>> postMultipart(
    Uri uri,
    MultipartFileRequest multipart,
  ) async {
    _ensureSessionIsActive();

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({
        HttpHeaders.acceptHeader: 'application/json',
        HttpHeaders.authorizationHeader: 'Bearer ${_session.sdkToken}',
      })
      ..fields.addAll(multipart.fields)
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          multipart.filePath,
          contentType: MediaType.parse(multipart.contentType),
        ),
      );
    return _sendRequest(request);
  }

  Future<Map<String, Object?>> _send(
    String method,
    Uri uri, {
    Map<String, Object?>? body,
  }) async {
    _ensureSessionIsActive();

    final request = http.Request(method, uri)
      ..headers.addAll({
        HttpHeaders.acceptHeader: 'application/json',
        HttpHeaders.authorizationHeader: 'Bearer ${_session.sdkToken}',
        if (body != null) HttpHeaders.contentTypeHeader: 'application/json',
      });
    if (body != null) request.body = jsonEncode(body);

    return _sendRequest(request);
  }

  Future<Map<String, Object?>> _sendRequest(http.BaseRequest request) async {
    try {
      final response = await _httpClient
          .send(request)
          .then(http.Response.fromStream)
          .timeout(_config.requestTimeout);
      return _decode(response);
    } on ApiException {
      rethrow;
    } on TimeoutException catch (error) {
      throw ApiException(
        failure: ApiFailure.timeout,
        message: 'The verification request timed out.',
        cause: error,
      );
    } on http.ClientException catch (error) {
      throw ApiException(
        failure: ApiFailure.connection,
        message: 'The verification service could not be reached.',
        cause: error,
      );
    } on SocketException catch (error) {
      throw ApiException(
        failure: ApiFailure.connection,
        message: 'The verification service could not be reached.',
        cause: error,
      );
    }
  }

  Map<String, Object?> _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _statusException(response);
    }
    if (response.statusCode == HttpStatus.noContent || response.body.isEmpty) {
      return const {};
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) throw const FormatException();
      return Map<String, Object?>.from(decoded);
    } catch (error) {
      throw ApiException(
        failure: ApiFailure.invalidResponse,
        message: 'The verification service returned an invalid response.',
        statusCode: response.statusCode,
        cause: error,
      );
    }
  }

  ApiException _statusException(http.Response response) {
    final statusCode = response.statusCode;
    final failure = switch (statusCode) {
      HttpStatus.unauthorized => ApiFailure.unauthorized,
      HttpStatus.forbidden => ApiFailure.forbidden,
      HttpStatus.requestTimeout => ApiFailure.timeout,
      HttpStatus.tooManyRequests => ApiFailure.rateLimited,
      >= 500 => ApiFailure.server,
      _ => ApiFailure.rejected,
    };
    final envelope = _decodeErrorEnvelope(response.body);
    return ApiException(
      failure: failure,
      message: switch (failure) {
        ApiFailure.unauthorized =>
          'The verification session is not authorized.',
        ApiFailure.forbidden =>
          'The verification session cannot perform this request.',
        ApiFailure.timeout => 'The verification request timed out.',
        ApiFailure.rateLimited =>
          'The verification service is receiving too many requests.',
        ApiFailure.server =>
          'The verification service is temporarily unavailable.',
        _ => 'The verification request was rejected.',
      },
      statusCode: statusCode,
      code: envelope.code,
      details: envelope.details,
    );
  }

  ({String? code, Map<String, Object?> details}) _decodeErrorEnvelope(
    String body,
  ) {
    if (body.isEmpty) return (code: null, details: const {});
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return (code: null, details: const {});
      final json = Map<String, Object?>.from(decoded);
      final rawCode = json['code'];
      final code = rawCode is String && rawCode.trim().isNotEmpty
          ? rawCode.trim()
          : null;
      final details = <String, Object?>{};
      for (final key in const [
        'missingInputs',
        'unexpectedInputs',
        'retryAfterSeconds',
      ]) {
        if (json.containsKey(key)) details[key] = json[key];
      }
      return (code: code, details: Map.unmodifiable(details));
    } catch (_) {
      return (code: null, details: const {});
    }
  }

  void _ensureSessionIsActive() {
    if (_session.isExpired) {
      throw const ApiException(
        failure: ApiFailure.expiredSession,
        message: 'The verification session has expired.',
      );
    }
  }

  void close() => _httpClient.close();
}
