import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/face_guide_config.dart';

enum SelfieCaptureOverlayState { searching, guiding, ready, timedOut }

class SelfieCaptureOverlayStyle {
  const SelfieCaptureOverlayStyle({
    this.scrimColor = const Color(0xB3000000),
    this.searchingColor = const Color(0xFFF2F4F2),
    this.guidingColor = const Color(0xFFFFC857),
    this.readyColor = const Color(0xFF53D769),
    this.timedOutColor = const Color(0xFFFF7168),
    this.borderWidth = 3,
    this.progressWidth = 5,
    this.transitionDuration = const Duration(milliseconds: 280),
  });

  final Color scrimColor;
  final Color searchingColor;
  final Color guidingColor;
  final Color readyColor;
  final Color timedOutColor;
  final double borderWidth;
  final double progressWidth;
  final Duration transitionDuration;

  Color colorFor(SelfieCaptureOverlayState state) => switch (state) {
        SelfieCaptureOverlayState.searching => searchingColor,
        SelfieCaptureOverlayState.guiding => guidingColor,
        SelfieCaptureOverlayState.ready => readyColor,
        SelfieCaptureOverlayState.timedOut => timedOutColor,
      };
}

/// Responsive oval and guidance progress drawn over the visible camera area.
class SelfieCaptureOverlay extends StatelessWidget {
  const SelfieCaptureOverlay({
    super.key,
    this.guideConfig = const FaceGuideConfig(),
    this.style = const SelfieCaptureOverlayStyle(),
    this.state = SelfieCaptureOverlayState.searching,
    this.progress = 0,
  }) : assert(progress >= 0 && progress <= 1);

  final FaceGuideConfig guideConfig;
  final SelfieCaptureOverlayStyle style;
  final SelfieCaptureOverlayState state;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      duration: style.transitionDuration,
      tween: ColorTween(end: style.colorFor(state)),
      builder: (context, color, child) {
        return TweenAnimationBuilder<double>(
          duration: style.transitionDuration,
          tween: Tween(end: progress),
          builder: (context, animatedProgress, child) => CustomPaint(
            painter: _SelfieCaptureOverlayPainter(
              guideConfig: guideConfig,
              style: style,
              borderColor: color ?? style.colorFor(state),
              progress: animatedProgress,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class _SelfieCaptureOverlayPainter extends CustomPainter {
  const _SelfieCaptureOverlayPainter({
    required this.guideConfig,
    required this.style,
    required this.borderColor,
    required this.progress,
  });

  final FaceGuideConfig guideConfig;
  final SelfieCaptureOverlayStyle style;
  final Color borderColor;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final guide = guideConfig.resolve(Offset.zero & size);
    final oval = Path()..addOval(guide);
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      oval,
    );
    canvas.drawPath(outside, Paint()..color = style.scrimColor);
    canvas.drawOval(
      guide,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.borderWidth,
    );

    if (progress <= 0) return;
    canvas.drawArc(
      guide.inflate(style.progressWidth * 1.4),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.progressWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SelfieCaptureOverlayPainter oldDelegate) {
    return oldDelegate.guideConfig != guideConfig ||
        oldDelegate.style != style ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.progress != progress;
  }
}
