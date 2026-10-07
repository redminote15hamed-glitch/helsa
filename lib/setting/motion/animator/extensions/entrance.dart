import 'package:flutter/material.dart';
import '../core/speeds.dart';
import '../core/curves.dart';
import '../core/animator_wrapper.dart';

extension AnimatorEntrance on Widget {
  Widget enFade({
    Duration s = AS.balanced,
    Curve c = AC.easeInOutSine,
    int d = 0,
    double from = 0.0,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    return AnimatorWrapper(
      duration: s,
      curve: c,
      startOpacity: from,
      endOpacity: 1.0,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }

  Widget enBlur({
    Duration s = AS.slow,
    Curve c = AC.easeInOutSine,
    int d = 0,
    double sig = 10.0,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    return AnimatorWrapper(
      duration: s,
      curve: c,
      startBlur: sig,
      endBlur: 0.0,
      startOpacity: 0.0,
      endOpacity: 1.0,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }

  Widget enShimmer({
    Duration s = AS.slow,
    Curve c = AC.linear,
    bool ignoreHW = false,
  }) {
    return AnimatorWrapper(
      duration: s,
      curve: c,
      startOpacity: 0.35,
      endOpacity: 1.0,
      isShimmer: true,
      ignoreHW: ignoreHW,
      child: this,
    );
  }

  Widget enScale({
    Duration s = AS.balanced,
    Curve c = AC.easeOutCubic,
    int d = 0,
    double from = 0.8,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    return AnimatorWrapper(
      duration: s,
      curve: c,
      startScale: from,
      endScale: 1.0,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }

  Widget enPop({
    Duration s = AS.veryFast,
    Curve c = AC.elasticOut,
    int d = 0,
    double from = 0.3,
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

  Widget enZoom({
    Duration s = AS.balanced,
    Curve c = AC.easeOutCubic,
    int d = 0,
    double from = 0.5,
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

  Widget enSlideUp({
    Duration s = AS.balanced,
    Curve c = AC.easeOutCubic,
    int d = 0,
    double y = 50.0,
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

  Widget enSlideDown({
    Duration s = AS.balanced,
    Curve c = AC.easeOutCubic,
    int d = 0,
    double y = 50.0,
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

  Widget enSlideStart(
    BuildContext context, {
    Duration s = AS.balanced,
    Curve c = AC.easeOutCubic,
    int d = 0,
    double x = 50.0,
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

  Widget enSlideEnd(
    BuildContext context, {
    Duration s = AS.balanced,
    Curve c = AC.easeOutCubic,
    int d = 0,
    double x = 50.0,
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

  Widget enRotate({
    Duration s = AS.balanced,
    Curve c = AC.easeInOutBack,
    int d = 0,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    return AnimatorWrapper(
      duration: s,
      curve: c,
      flipY: 1.0,
      startOpacity: 0.0,
      endOpacity: 1.0,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }

  Widget enFlipX({
    Duration s = AS.slow,
    Curve c = AC.easeInOutBack,
    int d = 0,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    return AnimatorWrapper(
      duration: s,
      curve: c,
      flipX: 1.0,
      perspective: 1.0,
      startOpacity: 0.0,
      endOpacity: 1.0,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }

  Widget enFlipY({
    Duration s = AS.slow,
    Curve c = AC.easeInOutBack,
    int d = 0,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    return AnimatorWrapper(
      duration: s,
      curve: c,
      flipY: 1.0,
      perspective: 1.0,
      startOpacity: 0.0,
      endOpacity: 1.0,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }

  Widget enHero({
    Duration s = AS.balanced,
    Curve c = AC.easeOutCubic,
    int d = 0,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    return AnimatorWrapper(
      duration: s,
      curve: c,
      startScale: 0.85,
      endScale: 1.0,
      startOpacity: 0.0,
      endOpacity: 1.0,
      startOffsetY: 20.0,
      endOffsetY: 0.0,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }

  Widget enGlass({
    Duration s = AS.slow,
    Curve c = AC.easeInOutSine,
    int d = 0,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    return AnimatorWrapper(
      duration: s,
      curve: c,
      startBlur: 12.0,
      endBlur: 0.0,
      startScale: 0.95,
      endScale: 1.0,
      startOpacity: 0.0,
      endOpacity: 1.0,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }
}
