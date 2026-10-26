import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../config/kyc_config.dart';
import '../../session/verification_session.dart';
import 'api_exception.dart';
import 'api_endpoints.dart';

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

  Future<Map<String, Object?>> _send(
    String method,
    Uri uri, {
    Map<String, Object?>? body,
  }) async {
    if (_session.isExpired) {
      throw const ApiException(
        failure: ApiFailure.expiredSession,
        message: 'The verification session has expired.',
      );
    }

    final request = http.Request(method, uri)
      ..headers.addAll({
        HttpHeaders.acceptHeader: 'application/json',
        HttpHeaders.authorizationHeader: 'Bearer ${_session.sdkToken}',
        if (body != null) HttpHeaders.contentTypeHeader: 'application/json',
      });
    if (body != null) request.body = jsonEncode(body);

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
      throw _statusException(response.statusCode);
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

  ApiException _statusException(int statusCode) {
    final failure = switch (statusCode) {
      HttpStatus.unauthorized => ApiFailure.unauthorized,
      HttpStatus.forbidden => ApiFailure.forbidden,
      HttpStatus.requestTimeout => ApiFailure.timeout,
      HttpStatus.tooManyRequests => ApiFailure.rateLimited,
      >= 500 => ApiFailure.server,
      _ => ApiFailure.rejected,
    };
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
    );
  }

  void close() => _httpClient.close();
}
