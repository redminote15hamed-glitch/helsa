// lib/home/services/step_tracker.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:helsa/setting/storage/profile_store.dart';

/// Live steps + calories + real walking timer (only while walking).
class StepTracker extends ChangeNotifier {
  StepTracker._();
  static final StepTracker instance = StepTracker._();

  static const String _boxName = 'helsa_steps';
  static const String _keyDay = 'day';
  static const String _keySteps = 'steps';
  static const String _keyBaseline = 'baseline';
  static const String _keyActiveSec = 'active_sec';

  /// اگر این مدت قدم جدیدی نیاید → توقف تایمر
  static const Duration _idleTimeout = Duration(seconds: 8);

  StreamSubscription<StepCount>? _sub;
  Timer? _tick;
  Box<dynamic>? _box;

  int steps = 0;
  int stepsGoal = 8000;
  int calories = 0;
  int caloriesGoal = 300;

  /// ثانیهٔ واقعی پیاده‌روی امروز
  int activeSeconds = 0;
  int activeMinutesGoal = 30;

  bool isWalking = false;
  bool permissionGranted = false;
  bool available = false;
  String? error;

  DateTime? _lastStepAt;
  int _lastStepValue = 0;

  int get activeMinutes => activeSeconds ~/ 60;

  String get activeTimeLabel {
    final m = activeSeconds ~/ 60;
    final s = activeSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic>? get _profile => ProfileStore.profile;

  double get _weightKg {
    final w = _profile?['weight'];
    if (w is num && w > 0) return w.toDouble();
    return 70.0;
  }

  double get _heightCm {
    final h = _profile?['height'];
    if (h is num && h > 0) return h.toDouble();
    return 170.0;
  }

  int get _age {
    final a = _profile?['age'];
    if (a is int && a > 0) return a;
    if (a is num && a > 0) return a.round();
    return 30;
  }

  /// male / female از setup
  String get _gender {
    final g = _profile?['gender']?.toString().toLowerCase() ?? '';
    if (g.startsWith('f')) return 'female';
    if (g.startsWith('m')) return 'male';
    return 'male';
  }

  /// 0 sedentary … 4 very active
  int get _activityLevel {
    final a = _profile?['activityLevel'];
    if (a is int) return a.clamp(0, 4);
    if (a is num) return a.round().clamp(0, 4);
    return 2;
  }

  Future<void> init() async {
    _box = await Hive.openBox<dynamic>(_boxName);
    _computeGoalsFromProfile();
    _loadToday();
    await _requestPermissionAndListen();
  }

  /// هدف‌ها از داده Hive (سن، جنسیت، وزن، قد، سطح فعالیت)
  void _computeGoalsFromProfile() {
    final level = _activityLevel;
    final age = _age;
    final female = _gender == 'female';
    final weight = _weightKg;
    final height = _heightCm;

    // —— قدم ——
    // پایه بر اساس فعالیت
    const baseSteps = [5000, 6500, 8000, 10000, 12000];
    var stepGoal = baseSteps[level];

    // سن: بالاتر از ۴۵ کمی کمتر، زیر ۲۵ کمی بیشتر
    if (age >= 60) {
      stepGoal = (stepGoal * 0.85).round();
    } else if (age >= 45) {
      stepGoal = (stepGoal * 0.92).round();
    } else if (age < 25) {
      stepGoal = (stepGoal * 1.05).round();
    }

    // زنان معمولاً هدف کمی کمتر از مردان در همان سطح (اختیاری ملایم)
    if (female) {
      stepGoal = (stepGoal * 0.95).round();
    }

    stepsGoal = stepGoal.clamp(4000, 15000);

    // —— کالری هدف روز (تقریبی از BMR × ضریب فعالیت، فقط بخش «حرکت») ——
    // Harris–Benedict ساده
    final bmr = female
        ? (447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age))
        : (88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age));
    const activityFactor = [1.2, 1.375, 1.55, 1.725, 1.9];
    final tdee = bmr * activityFactor[level];
    // هدف کالری سوزانده با قدم ≈ بخشی از TDEE (۱۰–۱۵٪)
    caloriesGoal = (tdee * 0.12).round().clamp(150, 800);

    // —— دقیقه فعال ——
    const baseMin = [20, 25, 30, 40, 50];
    var minGoal = baseMin[level];
    if (age >= 60) minGoal = (minGoal * 0.9).round();
    activeMinutesGoal = minGoal.clamp(15, 60);
  }

  /// اگر پروفایل عوض شد دوباره صدا بزن
  void refreshGoals() {
    _computeGoalsFromProfile();
    _recalcCalories();
    notifyListeners();
  }

  String get _todayKey {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  void _loadToday() {
    final box = _box;
    if (box == null) return;
    if (box.get(_keyDay) != _todayKey) {
      box.put(_keyDay, _todayKey);
      box.put(_keySteps, 0);
      box.put(_keyBaseline, null);
      box.put(_keyActiveSec, 0);
      steps = 0;
      activeSeconds = 0;
    } else {
      steps = (box.get(_keySteps) as int?) ?? 0;
      activeSeconds = (box.get(_keyActiveSec) as int?) ?? 0;
    }
    _recalcCalories();
    notifyListeners();
  }

  Future<void> _requestPermissionAndListen() async {
    try {
      final status = await Permission.activityRecognition.request();
      permissionGranted = status.isGranted || status.isLimited || kIsWeb;

      if (!permissionGranted) {
        error = 'permission';
        available = false;
        notifyListeners();
        return;
      }

      _sub?.cancel();
      _sub = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: (e) {
          error = e.toString();
          available = false;
          _stopWalking();
          notifyListeners();
        },
        cancelOnError: false,
      );
      available = true;
      error = null;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      available = false;
      notifyListeners();
    }
  }

  void _onStepCount(StepCount event) {
    final box = _box;
    if (box == null) return;

    final total = event.steps;
    final day = _todayKey;

    if (box.get(_keyDay) != day) {
      box.put(_keyDay, day);
      box.put(_keyBaseline, total);
      box.put(_keySteps, 0);
      box.put(_keyActiveSec, 0);
      steps = 0;
      activeSeconds = 0;
    }

    var baseline = box.get(_keyBaseline) as int?;
    if (baseline == null) {
      baseline = total;
      box.put(_keyBaseline, baseline);
    }
    if (total < baseline) {
      baseline = total;
      box.put(_keyBaseline, baseline);
    }

    final newSteps = (total - baseline).clamp(0, 200000);
    final increased = newSteps > steps;

    steps = newSteps;
    box.put(_keySteps, steps);
    _recalcCalories();

    if (increased) {
      _lastStepAt = DateTime.now();
      _lastStepValue = steps;
      _startWalking();
    }

    notifyListeners();
  }

  void _startWalking() {
    if (isWalking) return;
    isWalking = true;
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    notifyListeners();
  }

  void _onTick() {
    final last = _lastStepAt;
    if (last == null ||
        DateTime.now().difference(last) > _idleTimeout) {
      _stopWalking();
      return;
    }
    // فقط وقتی واقعاً در حال راه‌رفتن است
    activeSeconds += 1;
    _box?.put(_keyActiveSec, activeSeconds);
    notifyListeners();
  }

  void _stopWalking() {
    if (!isWalking && _tick == null) return;
    isWalking = false;
    _tick?.cancel();
    _tick = null;
    notifyListeners();
  }

  /// بعد از «خیر» در نوتیف — تایمر را متوقف کن (قدم‌ها همچنان جمع می‌شوند)
  void pauseWalkingDetection() {
    _stopWalking();
    _lastStepAt = null;
  }

  void _recalcCalories() {
    calories = (steps * 0.04 * (_weightKg / 70.0)).round();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tick?.cancel();
    super.dispose();
  }
}
