import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: VigiloApp(),
    ),
  );
}

class VigiloApp extends StatelessWidget {
  const VigiloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vigilo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const SplashScreen(),
    );
  }
}
