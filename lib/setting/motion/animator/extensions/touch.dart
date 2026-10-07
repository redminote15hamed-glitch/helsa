import 'package:flutter/material.dart';
import '../core/speeds.dart';
import '../core/curves.dart';
import '../core/animator_wrapper.dart';

extension AnimatorTouch on Widget {
  Widget toScale({
    Duration s = AS.veryFast,
    Curve c = AC.decelerate,
    double scale = 0.95,
    bool ignoreHW = false,
  }) {
    return AnimatorWrapper(
      duration: AS.instant,
      touchDuration: s,
      touchCurve: c,
      touchScale: scale,
      ignoreHW: ignoreHW,
      child: this,
    );
  }

  Widget toPop({
    Duration s = AS.veryFast,
    Curve c = AC.elasticOut,
    double scale = 0.90,
    bool ignoreHW = false,
  }) {
    return AnimatorWrapper(
      duration: AS.instant,
      touchDuration: s,
      touchCurve: c,
      touchScale: scale,
      ignoreHW: ignoreHW,
      child: this,
    );
  }

  Widget toRotate({
    Duration s = AS.veryFast,
    Curve c = AC.decelerate,
    double scale = 0.95,
    bool ignoreHW = false,
  }) {
    return AnimatorWrapper(
      duration: AS.instant,
      touchDuration: s,
      touchCurve: c,
      touchScale: scale,
      flipY: 0.08,
      ignoreHW: ignoreHW,
      child: this,
    );
  }

  Widget toPerspective({
    Duration s = AS.balanced,
    Curve c = AC.easeOutCubic,
    double scale = 0.96,
    bool ignoreHW = false,
  }) {
    return AnimatorWrapper(
      duration: AS.instant,
      touchDuration: s,
      touchCurve: c,
      touchScale: scale,
      perspective: 1.2,
      ignoreHW: ignoreHW,
      child: this,
    );
  }

  Widget toPress({
    Duration s = AS.veryFast,
    Curve c = AC.decelerate,
    double scale = 0.93,
    bool ignoreHW = false,
  }) {
    return AnimatorWrapper(
      duration: AS.instant,
      touchDuration: s,
      touchCurve: c,
      touchScale: scale,
      ignoreHW: ignoreHW,
      child: this,
    );
  }
}
