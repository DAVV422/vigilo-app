import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/app_colors.dart';
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

  _checkSession() async {
    // Retraso de 2.5 segundos como requiere UT-601
    await Future.delayed(const Duration(milliseconds: 2500));
    
    final prefs = await SharedPreferences.getInstance();
    final hasSession = prefs.getString('userEmail') != null;

    if (mounted) {
      if (hasSession) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
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
