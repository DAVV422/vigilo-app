import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'core/logging/app_logger.dart';
import 'core/push/push_notification_service.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';

const _log = AppLogger('App');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sin estos dos enganches, una excepción que escapa de un `build`, de un
  // callback o de un `Future` sin `await` no deja rastro en un build release:
  // la app muestra la pantalla roja (o nada) y el log queda vacío. Con esto,
  // cualquier error no capturado termina en logcat con su stack.
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    _log.error(
      'Error no capturado de Flutter en ${details.library ?? 'desconocido'}',
      details.exception,
      details.stack,
    );
    previousOnError?.call(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    _log.error('Error asíncrono no capturado', error, stack);
    return true; // ya quedó registrado; no tirar la app por esto
  };

  // Modo demo: cero dependencias externas (ni backend ni Firebase), para
  // que una presentación nunca se quede colgada esperando una red que no
  // está. Envuelto en try/catch de todos modos: un Firebase mal configurado
  // (p. ej. un emulador sin Google Play Services) nunca debe tumbar el
  // arranque de la app en modo normal.
  if (!AppConfig.demoMode) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e, st) {
      _log.error('Firebase no se pudo inicializar; la app sigue sin push', e, st);
    }
  }

  _log.info(
    'Arrancando Vigilo | api=${AppConfig.apiBaseUrl} | demo=${AppConfig.demoMode} '
    '| release=$kReleaseMode',
  );

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
