// فایل: main.dart
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:helsa/startup/splash/splash_screen.dart';
import 'package:helsa/setting/color/edge_to_edge.dart';
import 'package:helsa/setting/storage/profile_store.dart';
import 'package:helsa/setting/storage/theme_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await ProfileStore.init();
  try {
    await ThemeStore.open();
  } catch (e, st) {
    debugPrint('ThemeStore.open failed: $e\n$st');
    // Retry once — cold start race with SecureHive
    try {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await ThemeStore.open();
    } catch (e2, st2) {
      debugPrint('ThemeStore.open retry failed: $e2\n$st2');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ThemeStore.revision,
      builder: (context, _, __) {
        final data = ThemeStore.themeData();
        final night = ThemeStore.night.value;
        return MaterialApp(
          scrollBehavior: MyCustomScrollBehavior(),
          title: 'Helsa',
          debugShowCheckedModeBanner: false,
          theme: data,
          darkTheme: data,
          themeMode: night ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) {
            return EdgeToEdgeWrapper(child: child!);
          },
          home: SplashScreen(
            onThemeChanged: (_) {},
          ),
        );
      },
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
