import 'package:flutter/material.dart';
import '../core/speeds.dart';
import '../core/curves.dart';
import '../core/animator_wrapper.dart';

extension AnimatorExit on Widget {
  Widget exFade({
    Duration s = AS.fast,
    Curve c = AC.easeInCubic,
    int d = 0,
    double to = 0.0,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    return AnimatorWrapper(
      duration: s,
      curve: c,
      startOpacity: 1.0,
      endOpacity: to,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }

  Widget exBlur({
    Duration s = AS.balanced,
    Curve c = AC.easeInCubic,
    int d = 0,
    double sig = 10.0,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    return AnimatorWrapper(
      duration: s,
      curve: c,
      startBlur: 0.0,
      endBlur: sig,
      startOpacity: 1.0,
      endOpacity: 0.0,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }

  Widget exScale({
    Duration s = AS.fast,
    Curve c = AC.easeInCubic,
    int d = 0,
    double to = 0.5,
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

  Widget exZoom({
    Duration s = AS.fast,
    Curve c = AC.easeInCubic,
    int d = 0,
    double to = 1.3,
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

  Widget exSlideUp({
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

  Widget exSlideDown({
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

  Widget exSlideStart(
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

  Widget exSlideEnd(
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

  Widget exFlipX({
    Duration s = AS.balanced,
    Curve c = AC.easeInCubic,
    int d = 0,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    return AnimatorWrapper(
      duration: s,
      curve: c,
      flipX: -1.0,
      perspective: 1.0,
      startOpacity: 1.0,
      endOpacity: 0.0,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }

  Widget exFlipY({
    Duration s = AS.balanced,
    Curve c = AC.easeInCubic,
    int d = 0,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    return AnimatorWrapper(
      duration: s,
      curve: c,
      flipY: -1.0,
      perspective: 1.0,
      startOpacity: 1.0,
      endOpacity: 0.0,
      delayMs: d,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }
}
