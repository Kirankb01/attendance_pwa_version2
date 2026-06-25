import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'widgets/debug_overlay.dart';

void main() {
  runApp(const FacePocApp());
}

class FacePocApp extends StatelessWidget {
  const FacePocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Recognition POC',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return DebugOverlay(child: child!);
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00D4FF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
        useMaterial3: true,
        fontFamily: 'Roboto',
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

