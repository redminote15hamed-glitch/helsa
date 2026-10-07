import 'package:flutter/material.dart';

/// Standard animation curves.
abstract class AC {
  static const Curve easeInOutSine = Curves.easeInOutSine;
  static const Curve easeOutCubic = Curves.easeOutCubic;
  static const Curve easeInCubic = Curves.easeInCubic;
  static const Curve elasticOut = Curves.elasticOut;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve easeInOutBack = Curves.easeInOutBack;
  static const Curve easeInBack = Curves.easeInBack;
  static const Curve decelerate = Curves.decelerate;
  static const Curve linear = Curves.linear;
}
