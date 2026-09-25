// فایل: main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helsa/startup/splash/splash_screen.dart';
import 'package:helsa/setting/color/theme_color.dart';
import 'package:helsa/setting/color/edge_to_edge.dart';
import 'package:flutter/gestures.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // استفاده از تم سیستم به عنوان تم پیش‌فرض بدون قفل کردن متد
  ThemeData? _customTheme;

  // تابعی برای تغییر تم از داخل تنظیمات یا انیمیشن سوییچ تم
  void _updateTheme(ThemeData newTheme) {
    setState(() {
      _customTheme = newTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    // اگر کاربر تم سفارشی انتخاب نکرده باشد، برنامه به صورت کاملاً داینامیک با تغییرات تم سیستم تغییر موضع می‌دهد
    final effectiveTheme = _customTheme ?? AppTheme.getTheme(context);

    return MaterialApp(
      scrollBehavior: MyCustomScrollBehavior(),
      title: 'Helsa',
      debugShowCheckedModeBanner: false,
      theme: effectiveTheme,
      builder: (context, child) {
        return EdgeToEdgeWrapper(child: child!);
      },
      home: SplashScreen(onThemeChanged: _updateTheme),
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
