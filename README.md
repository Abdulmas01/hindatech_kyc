# Hindatech KYC

Flutter SDK for integrating document capture, policy-guided selfie capture,
and backend-authoritative Hindatech identity-verification workflows into a
customer application.

> This package is a pre-release. Its public API can change before version 1.0.

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
  config: KycConfig.production(),
  sessionProvider: () async {
    final response = await customerApi.createVerification();
    // Return the NestJS SDK bootstrap response unchanged.
    return response.json;
  },
);
```

`KycConfig.production()` uses
`https://api.kyc.hindatech.com/api/v1/`. Use the standard constructor to
override the base URI for a sandbox, local NestJS instance, or customer proxy:

```dart
final config = KycConfig(
  apiBaseUri: Uri.parse('https://sandbox.example.com/api/v1/'),
);
```

Never place a permanent customer API credential in the Flutter application.
The backend must return the NestJS SDK bootstrap contract. Its token must be
scoped to `client.session.verificationSessionId` with a short expiry.

For workflows that execute liveness, use the nullable backend policy rather
than a hardcoded challenge sequence:

```dart
final policy = client.session.livenessPolicy;
if (policy != null) {
  final challenges = policy.createGuidanceSequence();
  final timeout = policy.challengeTimeout;
  final stableFrames = policy.alignmentStabilityFrames;

  // Apply policy.requireSingleFace, policy.requireNeutralPose, and
  // policy.requireReturnToNeutral while presenting these challenges.
}
```

With `activeGuidanceRole=guidance_only`, completing these actions only permits
capture to continue; it is not a successful liveness result. The final decision
comes from backend processing when `decisionAuthority=backend`. Do not submit an
ordered challenge sequence when `temporalEvidenceSupported` is `false`.

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

For a workflow with a non-null `livenessPolicy`, launch the selfie view with
that exact policy. The SDK uses active challenges only as capture guidance;
NestJS remains responsible for the liveness decision.

```dart
Future<void> handleSelfieCapture(SelfieCaptureResult result) async {
  try {
    final hostedAsset = await client.uploadHostedAsset(
      HostedAssetUploadRequest(
        inputType: CaptureAssetType.selfiePrimary.wireValue,
        filePath: result.path,
      ),
    );
    selectedAssetKeys[hostedAsset.inputTypeValue] = hostedAsset.assetKey;
  } finally {
    await result.deleteLocalFile();
  }
}

final livenessPolicy = client.session.livenessPolicy;
if (livenessPolicy != null) {
  SelfieCaptureView(
    policy: livenessPolicy,
    config: const SelfieCaptureConfig.balanced(),
    onCompleted: handleSelfieCapture,
    onCancel: () => Navigator.of(context).pop(),
  );
}
```

Pass a `RouteObserver<ModalRoute<dynamic>>` registered on the host Navigator
when the capture route can be covered without being disposed. The view also
tracks `ModalRoute.isCurrentOf` automatically; the observer provides an
explicit integration point for custom navigation setups.

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
  if (state.isTerminal) {
    final result = state.result;
    handleVerificationOutcome(
      decision: result.decision,
      failureCode: result.failureCode,
      reasonCodes: result.reasonCodes,
    );
  }
}
```

The host may provide `VerificationPollingOptions` to override the interval or
set a timeout. Poll requests are sequential, stop at terminal states, and stop
when the stream subscription is cancelled. `VerificationResult` contains the
NestJS-normalized outcome needed by the mobile flow; detailed AI evidence stays
behind the product backend boundary.

Cancel a session before processing begins:

```dart
final cancelledState = await client.cancelSession();
```

After cancellation succeeds, stop capture and discard local pending upload
state. Retrying cancellation safely returns the same cancelled state.

Record the exact notice presented before input upload:

```dart
final evidence = await client.recordConsentEvidence(
  VerificationConsentRequest(
    purposeCode: 'verification_processing',
    noticeId: 'kyc_notice',
    noticeVersion: '2026-01',
    noticeSha256: sha256OfExactPresentedNotice,
  ),
);

final retainedEvidence = await client.listConsentEvidence();
```

The digest must be SHA-256 over the exact notice presented. Consent evidence is
a client assertion; it does not establish identity or legal sufficiency.

Customers using their own asset storage can submit short-lived HTTPS
references instead of uploading files through the SDK:

```dart
final submission = await client.submitExternalAssets(
  ExternalAssetSubmissionRequest(
    assets: {
      CaptureAssetType.documentFront.wireValue: ExternalAssetReference(
        referenceUri: temporaryReferenceFromCustomerBackend,
        referenceId: 'customer-document-front-2026-08-02',
        storageProvider: 'customer-s3',
        contentType: 'image/jpeg',
        expiresAt: referenceExpiry,
      ),
    },
  ),
);
```

The customer backend owns URL signing and storage credentials. The SDK only
validates and submits the temporary reference to NestJS; it never receives
permanent storage credentials. Signed URLs must not be logged or persisted.

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
- Nullable backend-owned liveness capture guidance policy
- NestJS upload, polling, and re-bootstrap policies
- Workflow-aware NestJS hosted asset upload and typed asset receipts
- Session recovery with duplicate staged-asset preservation
- Exact-key hosted asset submission
- Workflow-declared structured payload attachment
- Cancellable, sequential verification status polling
- Idempotent pre-processing session cancellation
- Validated consent evidence recording and retrieval
- Customer-managed external asset reference submission
- Stable customer-safe results on recovered and polled session state
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
- Backend-policy-driven face alignment and active capture guidance
- Lifecycle-safe selfie camera analysis with adaptive frame processing
- Responsive selfie guide, configurable transitions, capture, and retake flow
- Explicit ownership and cleanup for temporary selfie images
- Runnable Android and iOS document and selfie integration example

The package does not currently bundle a production-approved quality model.
Remaining workflow orchestration will be added incrementally.

The runnable example includes an optional diagnostics sheet for physical-device
testing. Its document quality buttons inject simulated advisory observations;
they validate SDK guidance behavior, not a quality model or verification result.

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE).
