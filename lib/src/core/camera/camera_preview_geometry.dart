import 'dart:math' as math;
import 'dart:ui';

/// Clockwise rotation from detector-image coordinates to upright preview space.
enum CameraImageRotation {
  degrees0,
  degrees90,
  degrees180,
  degrees270,
}

/// Maps detector coordinates into a centered, cover-fitted camera viewport.
///
/// Front-camera mirroring is applied after rotation so detector bounds and the
/// visible preview share one coordinate system.
class CameraPreviewGeometry {
  CameraPreviewGeometry({
    required this.sourceSize,
    required this.viewportSize,
    required this.rotation,
    required this.mirrored,
  })  : assert(sourceSize.width > 0 && sourceSize.height > 0),
        assert(viewportSize.width > 0 && viewportSize.height > 0);

  final Size sourceSize;
  final Size viewportSize;
  final CameraImageRotation rotation;
  final bool mirrored;

  Size get orientedSourceSize => switch (rotation) {
        CameraImageRotation.degrees0 ||
        CameraImageRotation.degrees180 =>
          sourceSize,
        CameraImageRotation.degrees90 ||
        CameraImageRotation.degrees270 =>
          Size(sourceSize.height, sourceSize.width),
      };

  double get coverScale => math.max(
        viewportSize.width / orientedSourceSize.width,
        viewportSize.height / orientedSourceSize.height,
      );

  Offset get coverOffset => Offset(
        (viewportSize.width - orientedSourceSize.width * coverScale) / 2,
        (viewportSize.height - orientedSourceSize.height * coverScale) / 2,
      );

  Offset mapPoint(Offset sourcePoint) {
    final rotated = _rotate(sourcePoint);
    final orientedWidth = orientedSourceSize.width;
    final visible =
        mirrored ? Offset(orientedWidth - rotated.dx, rotated.dy) : rotated;
    return Offset(
      visible.dx * coverScale + coverOffset.dx,
      visible.dy * coverScale + coverOffset.dy,
    );
  }

  Rect mapRect(Rect sourceRect) {
    final points = [
      mapPoint(sourceRect.topLeft),
      mapPoint(sourceRect.topRight),
      mapPoint(sourceRect.bottomLeft),
      mapPoint(sourceRect.bottomRight),
    ];
    final xs = points.map((point) => point.dx);
    final ys = points.map((point) => point.dy);
    return Rect.fromLTRB(
      xs.reduce(math.min),
      ys.reduce(math.min),
      xs.reduce(math.max),
      ys.reduce(math.max),
    );
  }

  Offset _rotate(Offset point) => switch (rotation) {
        CameraImageRotation.degrees0 => point,
        CameraImageRotation.degrees90 =>
          Offset(sourceSize.height - point.dy, point.dx),
        CameraImageRotation.degrees180 => Offset(
            sourceSize.width - point.dx,
            sourceSize.height - point.dy,
          ),
        CameraImageRotation.degrees270 =>
          Offset(point.dy, sourceSize.width - point.dx),
      };
}
