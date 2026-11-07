import 'dart:math' as math;
import 'dart:ui';

/// Responsive layout values for the face guide shown over a camera viewport.
class FaceGuideConfig {
  const FaceGuideConfig({
    this.widthFactor = 0.72,
    this.widthToHeightRatio = 0.70,
    this.maxWidth = 360,
    this.maxHeightFactor = 0.72,
    this.verticalAlignment = -0.08,
  })  : assert(widthFactor > 0 && widthFactor <= 1),
        assert(widthToHeightRatio > 0),
        assert(maxWidth > 0),
        assert(maxHeightFactor > 0 && maxHeightFactor <= 1),
        assert(verticalAlignment >= -1 && verticalAlignment <= 1);

  final double widthFactor;
  final double widthToHeightRatio;
  final double maxWidth;
  final double maxHeightFactor;
  final double verticalAlignment;

  Rect resolve(Rect availableRect) {
    var width = math.min(availableRect.width * widthFactor, maxWidth);
    var height = width / widthToHeightRatio;
    final maxHeight = availableRect.height * maxHeightFactor;
    if (height > maxHeight) {
      height = maxHeight;
      width = height * widthToHeightRatio;
    }

    final center = availableRect.center.translate(
      0,
      (availableRect.height - height) * verticalAlignment / 2,
    );
    return Rect.fromCenter(center: center, width: width, height: height);
  }
}
