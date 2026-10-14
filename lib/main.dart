// فایل: main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:helsa/startup/splash/splash_screen.dart';
import 'package:helsa/setting/color/theme_color.dart';
import 'package:helsa/setting/color/edge_to_edge.dart';
import 'package:helsa/setting/storage/profile_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Hive — قبل از runApp
  await ProfileStore.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeData? _customTheme;

  void _updateTheme(ThemeData newTheme) {
    setState(() {
      _customTheme = newTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = _customTheme ?? AppTheme.getTheme(context);

    return MaterialApp(
      scrollBehavior: MyCustomScrollBehavior(),
      title: 'Helsa',
      debugShowCheckedModeBanner: false,
      theme: effectiveTheme,
      builder: (context, child) {
        return EdgeToEdgeWrapper(child: child!);
      },
      // بعد از اسپلش، خود SplashScreen باید چک کند:
      // ProfileStore.isSetupDone ? Home : Setup
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
