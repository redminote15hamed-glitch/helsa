/// Standard animation durations.
abstract class AS {
  static const Duration instant = Duration.zero;
  static const Duration speedy = Duration(milliseconds: 75);
  static const Duration veryFast = Duration(milliseconds: 150);
  static const Duration fast = Duration(milliseconds: 225);
  static const Duration balanced = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration verySlow = Duration(milliseconds: 600);
  static const Duration relaxed = Duration(milliseconds: 800);
}
