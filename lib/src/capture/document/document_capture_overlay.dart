import 'package:flutter/material.dart';

import 'document_capture_config.dart';

class DocumentCaptureOverlayStyle {
  const DocumentCaptureOverlayStyle({
    this.overlayColor = const Color(0x99000000),
    this.borderColor = const Color(0xFF35C759),
    this.borderRadius = 16,
    this.borderWidth = 2,
    this.cornerLength = 24,
    this.cornerWidth = 3,
  });

  final Color overlayColor;
  final Color borderColor;
  final double borderRadius;
  final double borderWidth;
  final double cornerLength;
  final double cornerWidth;
}

class DocumentCaptureOverlay extends StatelessWidget {
  const DocumentCaptureOverlay({
    super.key,
    this.visible = true,
    this.config = const DocumentCaptureConfig.balanced(),
    this.style = const DocumentCaptureOverlayStyle(),
  });

  final bool visible;
  final DocumentCaptureConfig config;
  final DocumentCaptureOverlayStyle style;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.expand();
    return CustomPaint(
      painter: _DocumentOverlayPainter(config: config, style: style),
      child: const SizedBox.expand(),
    );
  }
}

class _DocumentOverlayPainter extends CustomPainter {
  const _DocumentOverlayPainter({required this.config, required this.style});

  final DocumentCaptureConfig config;
  final DocumentCaptureOverlayStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * config.guideWidthFactor,
      height: size.width * config.guideWidthFactor * config.guideAspectRatio,
    );
    final roundedFrame = RRect.fromRectAndRadius(
      frame,
      Radius.circular(style.borderRadius),
    );

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(roundedFrame),
      ),
      Paint()..color = style.overlayColor,
    );
    canvas.drawRRect(
      roundedFrame,
      Paint()
        ..color = style.borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.borderWidth,
    );

    _drawCorner(
      canvas,
      frame.topLeft,
      Offset(frame.left + style.cornerLength, frame.top),
      Offset(frame.left, frame.top + style.cornerLength),
    );
    _drawCorner(
      canvas,
      frame.topRight,
      Offset(frame.right - style.cornerLength, frame.top),
      Offset(frame.right, frame.top + style.cornerLength),
    );
    _drawCorner(
      canvas,
      frame.bottomLeft,
      Offset(frame.left + style.cornerLength, frame.bottom),
      Offset(frame.left, frame.bottom - style.cornerLength),
    );
    _drawCorner(
      canvas,
      frame.bottomRight,
      Offset(frame.right - style.cornerLength, frame.bottom),
      Offset(frame.right, frame.bottom - style.cornerLength),
    );
  }

  void _drawCorner(Canvas canvas, Offset corner, Offset first, Offset second) {
    final paint = Paint()
      ..color = style.borderColor
      ..strokeWidth = style.cornerWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(corner, first, paint);
    canvas.drawLine(corner, second, paint);
  }

  @override
  bool shouldRepaint(covariant _DocumentOverlayPainter oldDelegate) {
    return oldDelegate.config != config || oldDelegate.style != style;
  }
}
