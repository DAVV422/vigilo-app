// lib/presentation/screens/profile/profile_placeholder_screen.dart
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_icons.dart';

class ProfilePlaceholderScreen extends StatelessWidget {
  const ProfilePlaceholderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              AppIcons.person,
              size: 64,
              color: AppColors.onSurfaceVariant,
            ),
            SizedBox(height: 16),
            Text(
              'Módulo Perfil en Construcción',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
