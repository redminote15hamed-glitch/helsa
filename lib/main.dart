// فایل: main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:helsa/startup/splash/splash_screen.dart';
import 'package:helsa/setting/color/edge_to_edge.dart';
import 'package:helsa/setting/storage/profile_store.dart';
import 'package:helsa/setting/storage/theme_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await ProfileStore.init();
  try {
    await ThemeStore.open();
  } catch (_) {}

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
          // Brightness is already baked into [data]; keep mode in sync
          // so Theme.of(context).brightness matches everywhere.
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
