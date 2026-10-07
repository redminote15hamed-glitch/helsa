/// Animator system – single import entry point.
///
/// Usage:
/// ```dart
/// import 'package:your_app/animator/animator.dart';
///
/// await HardwareProfiler.init(); // once in main()
///
/// MyWidget().enFade()
/// MyWidget().addPop()
/// MyWidget().deleteDrop()
/// MyWidget().toPress()
/// ```

library animator;

export 'core/speeds.dart';
export 'core/curves.dart';
export 'core/theme.dart';
export 'core/hardware_profiler.dart';
export 'core/animator_wrapper.dart';

export 'extensions/entrance.dart';
export 'extensions/exit.dart';
export 'extensions/touch.dart';
export 'extensions/add.dart';
export 'extensions/delete.dart';
export 'extensions/utility.dart';

export 'presets/presets.dart';
