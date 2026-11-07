# Hindatech KYC example

This app demonstrates a host application launching `DocumentCaptureView` and
`SelfieCaptureView`, then taking ownership of their local capture results.

Run it on a physical Android or iOS device because both flows require a camera:

```sh
flutter pub get
flutter run
```

The selfie screen uses `demoLivenessPolicy()` only so its camera UI can be
tested without a backend. Production applications must pass the nullable
`client.session.livenessPolicy` returned by NestJS bootstrap or recovery. The
demo fixture does not represent a local liveness decision and temporal evidence
submission remains disabled.

The Android camera permission and iOS camera usage description are configured
in this example. Customer applications must add the same platform entries. The
example also registers and passes a `RouteObserver` so camera analysis pauses
when another route covers the capture screen.

## Physical-device validation

- Cold-start each capture screen and confirm the loading message remains visible
  until the preview is ready.
- Cover the selfie screen with another route, return to it, and confirm there is
  only one active camera stream and guidance continues from the paused state.
- Background and resume the app during alignment and during a challenge; the
  challenge deadline must not advance while inactive.
- Check portrait and landscape layouts and confirm the detected face guidance
  agrees with the visible oval.
- Exercise permission denial, permanent denial, challenge timeout, retry,
  retake, cancellation, and successful capture.
- After upload or abandonment, verify the host deletes the local capture result.
