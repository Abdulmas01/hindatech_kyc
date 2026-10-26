# Hindatech KYC example

This app demonstrates a host application launching `DocumentCaptureView` and
receiving a `DocumentCaptureResult` through the public SDK API.

Run it on a physical Android or iOS device because document capture requires a
camera:

```sh
flutter pub get
flutter run
```

The Android camera permission and iOS camera usage description are configured
in this example. Customer applications must add the same platform entries.
