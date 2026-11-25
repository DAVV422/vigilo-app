import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

/// Confirmación para lo que no se deshace.
///
/// Entregar un canje, resolver una disputa y verificar una empresa no tienen
/// vuelta atrás, y todas se disparan con un solo toque en una pantalla
/// chica. El diálogo pide que [consequence] diga **qué va a pasar**, no
/// "¿estás seguro?": lo segundo se contesta que sí sin leer.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String consequence,
  String confirmLabel = 'Confirmar',
  bool isDestructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(consequence),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: isDestructive
              ? ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.onError,
                )
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
