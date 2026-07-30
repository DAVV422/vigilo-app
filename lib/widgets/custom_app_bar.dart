import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../presentation/providers/providers.dart';
import '../screens/points_screen.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final userPoints = user?.points ?? 350;

    return Container(
      color: const Color(0xFF0F172A), // Azul marino oscuro
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Lado Izquierdo
              Expanded(
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E293B), // Gris/Azul claro
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chevron_left, color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Lado Derecho
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Campana de notificaciones
                  InkWell(
                    onTap: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                      ref.read(currentNavIndexProvider.notifier).setIndex(1); // Alertas/Notificaciones
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E293B),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '2',
                              style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Píldora de puntos
                  InkWell(
                    onTap: () {
                      // Solo navega si no estamos ya en PointsScreen
                      if (title != 'Mis Puntos') {
                        Navigator.popUntil(context, (route) => route.isFirst);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PointsScreen()));
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF004D20), // Verde oscuro
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_border, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$userPoints',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize {
    // Return a default height. SafeArea padding will be handled automatically by Scaffold
    return const Size.fromHeight(72.0);
  }
}
