import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../presentation/providers/providers.dart';

class MainAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;

  const MainAppBar({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final userName = user?.name ?? 'Carlos Mendoza';
    final userInitials = userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'C';

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 12, bottom: 12),
        child: Image.asset('assets/app_icon.jpg'),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: GestureDetector(
            onTap: () {
              ref.read(currentNavIndexProvider.notifier).setIndex(3);
            },
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surfaceVariant,
              backgroundImage: user != null && user.avatarUrl.startsWith('http') 
                  ? NetworkImage(user.avatarUrl) 
                  : null,
              child: user != null && user.avatarUrl.startsWith('http')
                  ? null
                  : Text(
                      userInitials,
                      style: const TextStyle(
                        color: AppColors.primary, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 14
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
