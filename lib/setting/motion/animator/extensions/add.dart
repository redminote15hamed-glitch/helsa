import 'package:flutter/material.dart';
import '../core/speeds.dart';
import '../core/curves.dart';
import '../core/animator_wrapper.dart';

extension AnimatorAdd on Widget {
  Widget addFade({
    Duration s = AS.balanced,
    Curve c = AC.easeOutCubic,
    int d = 0,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    return AnimatorWrapper(
      duration: s,
      curve: c,
      startOpacity: 0.0,
      endOpacity: 1.0,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }

  Widget addSlideUp({
    Duration s = AS.balanced,
    Curve c = AC.easeOutCubic,
    int d = 0,
    double y = 40.0,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    return AnimatorWrapper(
      duration: s,
      curve: c,
      startOffsetY: y,
      endOffsetY: 0.0,
      startOpacity: 0.0,
      endOpacity: 1.0,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }

  Widget addSlideDown({
    Duration s = AS.balanced,
    Curve c = AC.easeOutCubic,
    int d = 0,
    double y = 40.0,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    return AnimatorWrapper(
      duration: s,
      curve: c,
      startOffsetY: -y,
      endOffsetY: 0.0,
      startOpacity: 0.0,
      endOpacity: 1.0,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }

  Widget addScale({
    Duration s = AS.balanced,
    Curve c = AC.easeOutCubic,
    int d = 0,
    double from = 0.85,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    return AnimatorWrapper(
      duration: s,
      curve: c,
      startScale: from,
      endScale: 1.0,
      startOpacity: 0.0,
      endOpacity: 1.0,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }

  Widget addPop({
    Duration s = AS.veryFast,
    Curve c = AC.elasticOut,
    int d = 0,
    double from = 0.4,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    return AnimatorWrapper(
      duration: s,
      curve: c,
      startScale: from,
      endScale: 1.0,
      startOpacity: 0.0,
      endOpacity: 1.0,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }

  /// Soft rise from below into place.
  Widget addRise({
    Duration s = AS.balanced,
    Curve c = AC.easeOutCubic,
    int d = 0,
    double y = 30.0,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    return AnimatorWrapper(
      duration: s,
      curve: c,
      startOffsetY: y,
      endOffsetY: 0.0,
      startScale: 0.96,
      endScale: 1.0,
      startOpacity: 0.0,
      endOpacity: 1.0,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }

  /// Drops gently into place from slightly above.
  Widget addDropIn({
    Duration s = AS.balanced,
    Curve c = AC.easeOutCubic,
    int d = 0,
    double y = 24.0,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    return AnimatorWrapper(
      duration: s,
      curve: c,
      startOffsetY: -y,
      endOffsetY: 0.0,
      startScale: 0.92,
      endScale: 1.0,
      startOpacity: 0.0,
      endOpacity: 1.0,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }

  Widget addFromStart(
    BuildContext context, {
    Duration s = AS.balanced,
    Curve c = AC.easeOutCubic,
    int d = 0,
    double x = 40.0,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return AnimatorWrapper(
      duration: s,
      curve: c,
      startOffsetX: isRtl ? x : -x,
      endOffsetX: 0.0,
      startOpacity: 0.0,
      endOpacity: 1.0,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }

  Widget addFromEnd(
    BuildContext context, {
    Duration s = AS.balanced,
    Curve c = AC.easeOutCubic,
    int d = 0,
    double x = 40.0,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return AnimatorWrapper(
      duration: s,
      curve: c,
      startOffsetX: isRtl ? -x : x,
      endOffsetX: 0.0,
      startOpacity: 0.0,
      endOpacity: 1.0,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }
}
