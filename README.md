# Hindatech KYC

Flutter SDK for integrating Hindatech identity-verification workflows into a
customer application.

> This package is under active development and is not ready for production or
> publication on pub.dev.

## Security

The host application obtains a short-lived SDK token from its backend.
Long-lived API credentials must never be embedded in a Flutter application.

## Platform setup

Android applications must declare camera access in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

iOS applications must provide `NSCameraUsageDescription` in `Info.plist`.

## Usage

Create the verification on your trusted backend, then return its short-lived
SDK token and capture manifest to the application. The application retains
control of its own endpoint and authentication:

```dart
final client = await KycClient.bootstrap(
  config: KycConfig(
    apiBaseUri: Uri.parse('https://api.example.com/api/v1/'),
  ),
  sessionProvider: () async {
    final response = await customerApi.createVerification();
    // Return the NestJS SDK bootstrap response unchanged.
    return response.json;
  },
);
```

Never place a permanent customer API credential in the Flutter application.
The backend must return the NestJS SDK bootstrap contract. Its token must be
scoped to `client.session.verificationSessionId` with a short expiry.

Call `client.close()` when the verification flow is permanently finished so
the SDK can release its network resources.

Launch the public capture view from a page or route:

```dart
Future<void> handleDocumentCapture(DocumentCaptureResult result) async {
  try {
    final hostedAsset = await client.uploadHostedAsset(
      HostedAssetUploadRequest(
        inputType: CaptureAssetType.documentFront.wireValue,
        filePath: result.normalizedPath,
      ),
    );
    selectedAssetKeys[hostedAsset.inputTypeValue] = hostedAsset.assetKey;
  } finally {
    await result.deleteLocalFiles();
  }
}

DocumentCaptureView(
  config: const DocumentCaptureConfig.highQuality(),
  onCompleted: handleDocumentCapture,
  onCancel: () => Navigator.of(context).pop(),
  onError: (error) {
    // Present an appropriate message or record the failure.
  },
)
```

Choose the asset slot from `client.session.requiredInputs`. Keep the returned
`assetKey` for submission. Uploading the same input type again creates another
temporary asset. If an upload times out after the request may have reached the
server, recover the session before retrying.

```dart
final recovered = await client.recoverSession();
final frontCandidates = recovered
    .hostedAssetsFor(CaptureAssetType.documentFront.wireValue)
    .toList();

final submission = await client.submitHostedAssets(
  HostedAssetSubmissionRequest(assets: selectedAssetKeys),
);
```

Recovery preserves every staged candidate. Select the intended candidate and
submit its exact key; the SDK does not silently choose among duplicate uploads.

Attach structured inputs only when declared by the active workflow:

```dart
await client.attachPayload(
  VerificationPayloadRequest(
    payloadType: VerificationPayloadType.referenceProvenance.wireValue,
    payload: {
      'source': 'customer_account',
      'referenceId': 'profile-photo-123',
    },
    metadata: {'capturedBy': 'customer_backend'},
  ),
);
```

Payload contents can contain sensitive identity context. Do not log them or
persist them beyond the active verification session.

After submission, poll the SDK state using the backend-recommended interval:

```dart
await for (final state in client.pollSession()) {
  updateVerificationStatus(state.status);
}
```

The host may provide `VerificationPollingOptions` to override the interval or
set a timeout. Poll requests are sequential, stop at terminal states, and stop
when the stream subscription is cancelled.

Cancel a session before processing begins:

```dart
final cancelledState = await client.cancelSession();
```

After cancellation succeeds, stop capture and discard local pending upload
state. Retrying cancellation safely returns the same cancelled state.

The capture view deletes files discarded with Retake or abandoned before the
Continue action. After Continue invokes `onCompleted`, ownership transfers to
the host application. Delete both local images with `result.deleteLocalFiles()`
after upload, cancellation, or any other processing finishes.

See [`example/`](example/) for a runnable integration using only the public API.

## Local quality guidance

Camera-quality observations are optional and advisory. The host application
may supply a local `Stream<DocumentQualityAssessment>`, customize all guidance
copy and colors, disable auto-capture, or disable quality guidance entirely.
These observations never determine the verification result.

```dart
final captureConfig = const DocumentCaptureConfig.balanced().copyWith(
  autoCaptureEnabled: false,
  qualityGuidanceMode: DocumentQualityGuidanceMode.advisory,
);

DocumentCaptureView(
  config: captureConfig,
  qualityAssessments: localAssessor.assessments,
  onQualityError: reportNonBlockingQualityError,
  onCompleted: handleCapture,
)
```

## Current foundation

- SDK configuration
- Validated short-lived session bootstrap
- Centralized, session-authorized API transport and endpoint definitions
- NestJS-provided required asset and payload inputs
- NestJS upload, polling, and re-bootstrap policies
- Workflow-aware NestJS hosted asset upload and typed asset receipts
- Session recovery with duplicate staged-asset preservation
- Exact-key hosted asset submission
- Workflow-declared structured payload attachment
- Cancellable, sequential verification status polling
- Idempotent pre-processing session cancellation
- Document-capture configuration and result models
- Adaptive document-frame processing
- Host-controlled advisory quality guidance and auto-capture
- Camera permission, selection, initialization, and lifecycle handling
- Document bounds detection, cropping, orientation correction, and resizing
- Explicit ownership and cleanup for temporary document images
- Lifecycle-safe document-capture state
- Customizable document framing overlay
- Customer-configurable copy and visual tokens
- Guided document capture view with capture, retake, and lifecycle handling
- Runnable Android and iOS integration example

The package does not currently bundle a production-approved quality model.
Remaining workflow orchestration will be added incrementally.
