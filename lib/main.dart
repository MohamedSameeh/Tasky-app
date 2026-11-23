import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'app_scope.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase in the real build, in-memory demo data with --dart-define=DEMO=true.
  await AppScope.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppScope.theme,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Tasky',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          // Let lists and pagers be dragged with a mouse or trackpad on web/desktop.
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: PointerDeviceKind.values.toSet(),
          ),
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
