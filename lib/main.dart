import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'core/push/push_notification_service.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Modo demo: cero dependencias externas (ni backend ni Firebase), para
  // que una presentación nunca se quede colgada esperando una red que no
  // está. Envuelto en try/catch de todos modos: un Firebase mal configurado
  // (p. ej. un emulador sin Google Play Services) nunca debe tumbar el
  // arranque de la app en modo normal.
  if (!AppConfig.demoMode) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      developer.log('Firebase no se pudo inicializar; la app sigue sin push: $e', name: 'Push', level: 1000);
    }
  }

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
