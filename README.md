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
  config: KycConfig(apiBaseUri: Uri.parse('https://api.example.com')),
  sessionProvider: () async {
    final response = await customerApi.createVerification();
    return response.json;
  },
);
```

Never place a permanent customer API credential in the Flutter application.
The backend must issue a token scoped to `client.session.verificationId` with a
short expiry.

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

## Current foundation

- SDK configuration
- Validated short-lived session bootstrap
- Server-provided capture manifest
- Document-capture configuration and result models
- Adaptive document-frame processing
- Camera permission, selection, initialization, and lifecycle handling
- Document bounds detection, cropping, orientation correction, and resizing
- Lifecycle-safe document-capture state
- Customizable document framing overlay
- Customer-configurable copy and visual tokens
- Guided document capture view with capture, retake, and lifecycle handling
- Runnable Android and iOS integration example

Live quality guidance, upload orchestration, and polling will be added
incrementally.
