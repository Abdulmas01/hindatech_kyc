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

## Current foundation

- SDK configuration
- Short-lived session model
- Server-provided capture manifest
- Document-capture configuration and result models
- Adaptive document-frame processing
- Camera permission, selection, initialization, and lifecycle handling

Capture UI, document detection, upload orchestration, and polling will be added
incrementally.
