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
    return response.json;
  },
);
```

Never place a permanent customer API credential in the Flutter application.
The backend must issue a token scoped to `client.session.verificationId` with a
short expiry.

Call `client.close()` when the verification flow is permanently finished so
the SDK can release its network resources.

Launch the public capture view from a page or route:

```dart
DocumentCaptureView(
  config: const DocumentCaptureConfig.highQuality(),
  onCompleted: (result) {
    final normalizedImagePath = result.normalizedPath;
    // Send the normalized image through your application's verification flow.
  },
  onCancel: () => Navigator.of(context).pop(),
  onError: (error) {
    // Present an appropriate message or record the failure.
  },
)
```

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
- Server-provided capture manifest
- Document-capture configuration and result models
- Adaptive document-frame processing
- Host-controlled advisory quality guidance and auto-capture
- Camera permission, selection, initialization, and lifecycle handling
- Document bounds detection, cropping, orientation correction, and resizing
- Lifecycle-safe document-capture state
- Customizable document framing overlay
- Customer-configurable copy and visual tokens
- Guided document capture view with capture, retake, and lifecycle handling
- Runnable Android and iOS integration example

The package does not currently bundle a production-approved quality model.
Upload orchestration and polling will be added incrementally.
