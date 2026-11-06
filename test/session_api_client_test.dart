import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hindatech_kyc/hindatech_kyc.dart';
import 'package:hindatech_kyc/src/core/network/session_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fixtures/sdk_bootstrap_payload.dart';

void main() {
  final config = KycConfig(
    apiBaseUri: Uri.parse('https://api.example.com/api/v1/'),
  );

  test('adds session authorization and decodes a JSON response', () async {
    late http.BaseRequest sentRequest;
    final transport = SessionApiClient(
      config: config,
      session: _session(),
      httpClient: MockClient.streaming((request, _) async {
        sentRequest = request;
        return http.StreamedResponse(
          Stream.value(utf8.encode('{"status":"pending"}')),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(transport.close);

    final response = await transport.get(
      transport.endpoints.sdkVerificationSession('verification-id'),
    );

    expect(sentRequest.method, 'GET');
    expect(sentRequest.headers['authorization'], 'Bearer short-lived-token');
    expect(sentRequest.headers['accept'], 'application/json');
    expect(response, {'status': 'pending'});
  });

  test('encodes JSON request bodies', () async {
    late http.BaseRequest sentRequest;
    final transport = SessionApiClient(
      config: config,
      session: _session(),
      httpClient: MockClient.streaming((request, _) async {
        sentRequest = request;
        return http.StreamedResponse(Stream.empty(), 204);
      }),
    );
    addTearDown(transport.close);

    final response = await transport.post(
      transport.endpoints.sdkHostedAssetSubmit('verification-id'),
      body: {'confirm': true},
    );

    expect(sentRequest.headers['content-type'], 'application/json');
    expect(jsonDecode((sentRequest as http.Request).body), {'confirm': true});
    expect(response, isEmpty);
  });

  test('maps unauthorized responses without exposing the token', () async {
    final transport = SessionApiClient(
      config: config,
      session: _session(),
      httpClient: MockClient((_) async => http.Response('secret body', 401)),
    );
    addTearDown(transport.close);

    await expectLater(
      transport.get(
        transport.endpoints.sdkVerificationSession('verification-id'),
      ),
      throwsA(
        isA<ApiException>()
            .having(
              (exception) => exception.failure,
              'failure',
              ApiFailure.unauthorized,
            )
            .having((exception) => exception.statusCode, 'status', 401)
            .having(
              (exception) => exception.toString(),
              'message',
              allOf(
                isNot(contains('short-lived-token')),
                isNot(contains('secret body')),
              ),
            ),
      ),
    );
  });

  test('maps malformed success responses', () async {
    final transport = SessionApiClient(
      config: config,
      session: _session(),
      httpClient: MockClient((_) async => http.Response('not-json', 200)),
    );
    addTearDown(transport.close);

    await expectLater(
      transport.get(
        transport.endpoints.sdkVerificationSession('verification-id'),
      ),
      throwsA(
        isA<ApiException>().having(
          (exception) => exception.failure,
          'failure',
          ApiFailure.invalidResponse,
        ),
      ),
    );
  });

  test('does not send a request for an expired session', () async {
    var requestCount = 0;
    final transport = SessionApiClient(
      config: config,
      session: _session(sdkTokenExpiresAt: '2020-01-01T00:00:00Z'),
      httpClient: MockClient((_) async {
        requestCount++;
        return http.Response('{}', 200);
      }),
    );
    addTearDown(transport.close);

    await expectLater(
      transport.get(
        transport.endpoints.sdkVerificationSession('verification-id'),
      ),
      throwsA(
        isA<ApiException>().having(
          (exception) => exception.failure,
          'failure',
          ApiFailure.expiredSession,
        ),
      ),
    );
    expect(requestCount, 0);
  });
}

VerificationSession _session({
  String sdkTokenExpiresAt = '2099-01-01T00:00:00Z',
}) =>
    VerificationSession.fromJson(
      sdkBootstrapPayload(sdkTokenExpiresAt: sdkTokenExpiresAt),
    );
