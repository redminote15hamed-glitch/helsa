import 'package:flutter/material.dart';
import '../core/speeds.dart';
import '../core/curves.dart';
import '../core/animator_wrapper.dart';

extension AnimatorDelete on Widget {
  Widget deleteFade({
    Duration s = AS.fast,
    Curve c = AC.easeInCubic,
    int d = 0,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    return AnimatorWrapper(
      duration: s,
      curve: c,
      startOpacity: 1.0,
      endOpacity: 0.0,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }

  Widget deleteSlideUp({
    Duration s = AS.fast,
    Curve c = AC.easeInCubic,
    int d = 0,
    double y = 50.0,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    return AnimatorWrapper(
      duration: s,
      curve: c,
      startOffsetY: 0.0,
      endOffsetY: -y,
      startOpacity: 1.0,
      endOpacity: 0.0,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }

  Widget deleteSlideDown({
    Duration s = AS.fast,
    Curve c = AC.easeInCubic,
    int d = 0,
    double y = 50.0,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    return AnimatorWrapper(
      duration: s,
      curve: c,
      startOffsetY: 0.0,
      endOffsetY: y,
      startOpacity: 1.0,
      endOpacity: 0.0,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }

  Widget deleteScale({
    Duration s = AS.fast,
    Curve c = AC.easeInCubic,
    int d = 0,
    double to = 0.6,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    return AnimatorWrapper(
      duration: s,
      curve: c,
      startScale: 1.0,
      endScale: to,
      startOpacity: 1.0,
      endOpacity: 0.0,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }

  /// Shrink toward center then fade (clean removal).
  Widget deleteShrink({
    Duration s = AS.fast,
    Curve c = AC.easeInBack,
    int d = 0,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    return AnimatorWrapper(
      duration: s,
      curve: c,
      startScale: 1.0,
      endScale: 0.2,
      startOpacity: 1.0,
      endOpacity: 0.0,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }

  /// Soft drop downward (Xiaomi-like simple style).
  Widget deleteDrop({
    Duration s = AS.fast,
    Curve c = AC.easeInCubic,
    int d = 0,
    double y = 60.0,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    return AnimatorWrapper(
      duration: s,
      curve: c,
      startOffsetY: 0.0,
      endOffsetY: y,
      startScale: 1.0,
      endScale: 0.85,
      startOpacity: 1.0,
      endOpacity: 0.0,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }

  /// Crumple: slight rotate + shrink + fade.
  Widget deleteCrumple({
    Duration s = AS.fast,
    Curve c = AC.easeInCubic,
    int d = 0,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    return AnimatorWrapper(
      duration: s,
      curve: c,
      startScale: 1.0,
      endScale: 0.35,
      startOpacity: 1.0,
      endOpacity: 0.0,
      flipY: 0.35,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }

  Widget deleteToStart(
    BuildContext context, {
    Duration s = AS.fast,
    Curve c = AC.easeInCubic,
    int d = 0,
    double x = 50.0,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return AnimatorWrapper(
      duration: s,
      curve: c,
      startOffsetX: 0.0,
      endOffsetX: isRtl ? -x : x,
      startOpacity: 1.0,
      endOpacity: 0.0,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }

  Widget deleteToEnd(
    BuildContext context, {
    Duration s = AS.fast,
    Curve c = AC.easeInCubic,
    int d = 0,
    double x = 50.0,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return AnimatorWrapper(
      duration: s,
      curve: c,
      startOffsetX: 0.0,
      endOffsetX: isRtl ? x : -x,
      startOpacity: 1.0,
      endOpacity: 0.0,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }
}
