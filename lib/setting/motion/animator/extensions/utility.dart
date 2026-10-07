import 'package:flutter/material.dart';
import '../core/animator_wrapper.dart';

extension AnimatorUtility on Widget {
  Widget chainAnimation({
    required Duration duration,
    required Curve curve,
    int delayMs = 0,
    double startScale = 1.0,
    double endScale = 1.0,
    double startOpacity = 1.0,
    double endOpacity = 1.0,
    double startOffsetY = 0.0,
    double endOffsetY = 0.0,
    double startOffsetX = 0.0,
    double endOffsetX = 0.0,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    return AnimatorWrapper(
      duration: duration,
      curve: curve,
      startScale: startScale,
      endScale: endScale,
      startOpacity: startOpacity,
      endOpacity: endOpacity,
      startOffsetY: startOffsetY,
      endOffsetY: endOffsetY,
      startOffsetX: startOffsetX,
      endOffsetX: endOffsetX,
      delayMs: delayMs,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }
}
