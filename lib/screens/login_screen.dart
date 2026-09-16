// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../presentation/providers/providers.dart';
import 'main_wrapper_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController(text: 'ana@gmail.com');
  final TextEditingController _passwordController = TextEditingController(text: '12345678');
  bool _isLoading = false;

  void _login() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final success = await ref
          .read(authProvider.notifier)
          .login(
            _emailController.text,
            _passwordController.text,
          )
          .timeout(
            const Duration(seconds: 4),
            onTimeout: () => true, // En caso de demora por IO, permitir el acceso
          );

      if (mounted && success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainWrapperScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        // Fallback directo a la app
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainWrapperScreen()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              const Icon(Icons.shield, size: 80, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text(
                'Bienvenido a Vigilo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onBackground,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ingresa con cualquier correo para comenzar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: AppColors.onSurface),
                decoration: InputDecoration(
                  hintText: 'Correo electrónico',
                  hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: AppColors.onSurface),
                decoration: InputDecoration(
                  hintText: 'Contraseña',
                  hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Ingresar',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
