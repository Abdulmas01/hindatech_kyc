Map<String, Object?> sdkBootstrapPayload({
  String sdkTokenExpiresAt = '2099-01-01T00:00:00Z',
  String sessionExpiresAt = '2099-01-01T00:30:00Z',
  List<String> requiredAssetTypes = const ['document_front'],
  List<String> optionalAssetTypes = const ['document_back'],
}) =>
    {
      'verificationSessionId': 'verification-id',
      'sdkToken': 'short-lived-token',
      'sdkTokenExpiresAt': sdkTokenExpiresAt,
      'allowedActions': [
        'session:read',
        'asset:upload',
        'payload:write',
        'session:submit',
        'session:cancel',
        'consent:read',
        'consent:record',
      ],
      'sessionExpiresAt': sessionExpiresAt,
      'sessionMode': 'sdk_capture',
      'assetIngestionMode': 'smartkyc_hosted',
      'supportedAssetIngestionModes': [
        'smartkyc_hosted',
        'external_reference',
      ],
      'workflowKey': 'document_extract',
      'status': 'started',
      'requiredInputs': {
        'requiredAssetTypes': requiredAssetTypes,
        'optionalAssetTypes': optionalAssetTypes,
        'requiredPayloadTypes': <String>[],
        'optionalPayloadTypes': ['subject_metadata'],
        'requiredAllOfFields': <String>[],
        'requiredAnyOfFields': ['subjectReference', 'subjectExternalId'],
      },
      'uploadPolicy': {
        'mode': 'smartkyc_hosted',
        'maxFileSizeBytes': 10485760,
        'acceptedMimeTypes': ['image/jpeg', 'image/png'],
        'redirectsAllowed': false,
        'uploadTransport': 'proxy_multipart',
        'proxyUploadUrlTemplate':
            '/api/v1/sdk/verification-sessions/{verificationSessionId}/assets/hosted',
      },
      'polling': {
        'statusUrl': '/api/v1/sdk/verification-sessions/verification-id',
        'recommendedIntervalMs': 3000,
      },
      'rebootstrap': {
        'createOrResumeUrl': '/api/v1/sdk/verification-sessions/bootstrap',
        'idempotencyRequired': true,
        'expiredSessionBehavior': 'new_session_on_expiry',
      },
    };
