# Hindatech KYC

Flutter SDK for integrating Hindatech identity-verification workflows into a
customer application.

> This package is under active development and is not ready for production or
> publication on pub.dev.

## Security

The host application obtains a short-lived SDK token from its backend.
Long-lived API credentials must never be embedded in a Flutter application.

## Current foundation

- SDK configuration
- Short-lived session model
- Server-provided capture manifest
- Document-capture configuration and result models
- Adaptive document-frame processing

Capture UI, upload orchestration, and polling will be added incrementally.
