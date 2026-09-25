import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/incident.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../category_badge.dart';

class ProximityAlertOverlay extends StatefulWidget {
  final Incident incident;
  final VoidCallback onDismiss;
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  const ProximityAlertOverlay({
    Key? key,
    required this.incident,
    required this.onDismiss,
    required this.onConfirm,
    required this.onReject,
  }) : super(key: key);

  @override
  State<ProximityAlertOverlay> createState() => _ProximityAlertOverlayState();
}

class _ProximityAlertOverlayState extends State<ProximityAlertOverlay> with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _timerController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    _animController.forward();
    _timerController.forward();

    // Auto-dismiss after 20 seconds
    _timer = Timer(const Duration(seconds: 20), () {
      _dismissWithAnimation();
    });
  }

  void _dismissWithAnimation() {
    _timer?.cancel();
    _animController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedBuilder(
                  animation: _timerController,
                  builder: (context, child) {
                    return LinearProgressIndicator(
                      value: _timerController.value,
                      backgroundColor: AppColors.surfaceVariant,
                      color: AppColors.primary,
                      minHeight: 4,
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CategoryBadge.fromIncidentType(type: widget.incident.type),
                          IconButton(
                            icon: const Icon(AppIcons.close, color: AppColors.onSurfaceVariant),
                            onPressed: _dismissWithAnimation,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.incident.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onBackground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.incident.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '¿Sigue el problema?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onBackground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                widget.onReject();
                                _dismissWithAnimation();
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: const BorderSide(color: AppColors.onBackground),
                                foregroundColor: AppColors.onBackground,
                              ),
                              child: const Text(
                                'YA NO',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                widget.onConfirm();
                                _dismissWithAnimation();
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'SÍ, SIGUE',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }
}
