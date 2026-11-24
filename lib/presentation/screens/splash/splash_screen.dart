import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../../screens/login_screen.dart';
import '../dashboard/dashboard_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Dos esperas en paralelo, no en fila:
    //
    // - El splash se muestra un mínimo de 2,5 s (UT-601).
    // - La restauración de sesión puede tardar más que eso: pide el perfil
    //   y, si el access token venció —cosa habitual, dura 15 minutos—, el
    //   interceptor lo renueva con el refresh token y reintenta. Son dos
    //   viajes de red que en un arranque en frío no siempre entran en 2,5 s.
    //
    // Decidir a dónde ir antes de que eso termine es leer un estado que
    // todavía no se sabe, y mandar al login a alguien que sí tenía sesión.
    await Future.wait([
      Future<void>.delayed(const Duration(milliseconds: 2500)),
      ref.read(authProvider.notifier).ready,
    ]);

    if (!mounted) return;

    final hasSession = ref.read(authProvider) != null;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => hasSession ? const DashboardScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(),
            Icon(Icons.shield, size: 100, color: AppColors.onPrimary),
            SizedBox(height: 16),
            Text(
              'VIGILO',
              style: TextStyle(
                color: AppColors.onPrimary,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                fontFamily: 'Hanken Grotesk',
              ),
            ),
            SizedBox(height: 4),
            Text(
              'URBAN SAFETY',
              style: TextStyle(
                color: AppColors.onPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 4.0,
              ),
            ),
            Spacer(),
            CircularProgressIndicator(
              color: AppColors.onPrimary,
            ),
            SizedBox(height: 64),
          ],
        ),
      ),
    );
  }
}
