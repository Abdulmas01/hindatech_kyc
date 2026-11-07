import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../models/selfie_frame_models.dart';
import 'camera_frame_rotation_resolver.dart';

class SelfieInputImageAdapter {
  const SelfieInputImageAdapter({
    this.rotationResolver = const CameraFrameRotationResolver(),
  });

  final CameraFrameRotationResolver rotationResolver;

  PreparedSelfieFrame? prepare(SelfieCameraFrameRequest request) {
    final platform = _currentPlatform();
    if (platform == null) return null;

    final description = request.controller.description;
    final resolved = rotationResolver.resolve(
      CameraFrameRotationRequest(
        platform: platform,
        sensorOrientation: description.sensorOrientation,
        lensDirection: description.lensDirection,
        deviceOrientation: request.controller.value.deviceOrientation,
      ),
    );
    if (resolved == null) return null;

    final image = request.image;
    final sourceSize = Size(image.width.toDouble(), image.height.toDouble());
    final inputImage = switch (platform) {
      CameraRuntimePlatform.iOS => _prepareIosImage(
          image,
          sourceSize,
          resolved.inputImageRotation,
        ),
      CameraRuntimePlatform.android => _prepareAndroidImage(
          image,
          sourceSize,
          resolved.inputImageRotation,
        ),
    };
    if (inputImage == null) return null;

    final coordinateSpace = rotationResolver.detectorCoordinateSpace(
      DetectorCoordinateSpaceRequest(
        platform: platform,
        rawSourceSize: sourceSize,
        previewRotation: resolved.previewRotation,
      ),
    );

    return PreparedSelfieFrame(
      inputImage: inputImage,
      sourceSize: coordinateSpace.sourceSize,
      rotation: coordinateSpace.rotation,
      mirrored: description.lensDirection == CameraLensDirection.front,
    );
  }

  CameraRuntimePlatform? _currentPlatform() {
    if (Platform.isAndroid) return CameraRuntimePlatform.android;
    if (Platform.isIOS) return CameraRuntimePlatform.iOS;
    return null;
  }

  InputImage? _prepareIosImage(
    CameraImage image,
    Size size,
    InputImageRotation rotation,
  ) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format != InputImageFormat.bgra8888 || image.planes.length != 1) {
      return null;
    }
    final plane = image.planes.single;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: size,
        rotation: rotation,
        format: InputImageFormat.bgra8888,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  InputImage? _prepareAndroidImage(
    CameraImage image,
    Size size,
    InputImageRotation rotation,
  ) {
    Uint8List? bytes;
    if (image.planes.length == 1) {
      // CameraX versions before 0.6.23 can return requested NV21 bytes while
      // reporting the stream as YUV420. The single-plane layout is the
      // reliable discriminator because this controller always requests NV21.
      bytes = _readSinglePlaneNv21(image);
    } else {
      bytes = _yuv420ToNv21(image);
    }
    if (bytes == null) return null;

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: size,
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.width,
      ),
    );
  }

  Uint8List? _readSinglePlaneNv21(CameraImage image) {
    return normalizeSinglePlaneNv21Bytes(
      source: image.planes.single.bytes,
      width: image.width,
      height: image.height,
    );
  }

  Uint8List? _yuv420ToNv21(CameraImage image) {
    if (image.planes.length != 3) return null;

    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    final uvWidth = width ~/ 2;
    final uvHeight = height ~/ 2;
    final output = Uint8List(width * height + uvWidth * uvHeight * 2);

    var destination = 0;
    for (var row = 0; row < height; row++) {
      final source = row * yPlane.bytesPerRow;
      if (source + width > yPlane.bytes.length) return null;
      output.setRange(destination, destination + width, yPlane.bytes, source);
      destination += width;
    }

    final uStride = uPlane.bytesPerPixel ?? 1;
    final vStride = vPlane.bytesPerPixel ?? 1;
    for (var row = 0; row < uvHeight; row++) {
      final uRow = row * uPlane.bytesPerRow;
      final vRow = row * vPlane.bytesPerRow;
      for (var column = 0; column < uvWidth; column++) {
        final uIndex = uRow + column * uStride;
        final vIndex = vRow + column * vStride;
        if (uIndex >= uPlane.bytes.length || vIndex >= vPlane.bytes.length) {
          return null;
        }
        output[destination++] = vPlane.bytes[vIndex];
        output[destination++] = uPlane.bytes[uIndex];
      }
    }
    return output;
  }
}

/// Normalizes a possibly padded CameraX NV21 buffer for ML Kit.
Uint8List? normalizeSinglePlaneNv21Bytes({
  required Uint8List source,
  required int width,
  required int height,
}) {
  final expectedLength = width * height * 3 ~/ 2;
  if (source.length < expectedLength) return null;
  if (source.length == expectedLength) return source;
  return Uint8List.sublistView(source, 0, expectedLength);
}
