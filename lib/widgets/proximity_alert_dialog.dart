import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../domain/entities/incident.dart';
import '../domain/entities/user.dart';
import '../presentation/providers/providers.dart';
import '../theme/app_colors.dart';

class ProximityAlertDialog extends ConsumerWidget {
  final Incident incident;
  final void Function(bool permanently) onDismiss;

  const ProximityAlertDialog({
    super.key,
    required this.incident,
    required this.onDismiss,
  });

  void _validate(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authProvider);
    if (user == null) return;
    
    // Si ya lo validó, no hacer nada o mostrar mensaje
    if (incident.validatorsIds.contains(user.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya confirmaste este incidente anteriormente.')),
      );
      onDismiss(false);
      return;
    }

    await ref.read(incidentsProvider.notifier).validateIncident(incident.id, user.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incidente confirmado (+5 puntos)'), 
          backgroundColor: AppColors.success
        ),
      );
    }
    onDismiss(true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(currentLocationProvider);
    
    final distance = Geolocator.distanceBetween(
      location.latitude, location.longitude,
      incident.location.latitude, incident.location.longitude,
    );

    Color severityColor;
    String severityText;
    IconData typeIcon;

    // Determinar la severidad basada en el tipo de incidente
    switch (incident.type) {
      case IncidentType.insecurity:
        severityColor = const Color(0xFFD32F2F); // Rojo fuerte
        severityText = 'CRÍTICA';
        typeIcon = Icons.security;
        break;
      case IncidentType.trash:
        severityColor = const Color(0xFFE57373); // Rojo salmón
        severityText = 'ALTA';
        typeIcon = Icons.delete_outline;
        break;
      case IncidentType.weeds:
        severityColor = Colors.orange; // Naranja
        severityText = 'MEDIA';
        typeIcon = Icons.grass;
        break;
      case IncidentType.recycling:
        severityColor = const Color(0xFF4CAF50); // Verde
        severityText = 'BAJA';
        typeIcon = Icons.recycling;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Material(
        color: Colors.transparent,
        child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: severityColor, width: 2.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 2. Cabecera (Header)
            Container(
              color: severityColor,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.security, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'A ${distance.toInt()}m de ti - Severidad $severityText',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => onDismiss(false),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            
            // 3. Cuerpo de la Tarjeta (Body)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // A. Sección de Información
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Columna Izquierda (Icono)
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: severityColor.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(typeIcon, color: severityColor, size: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Columna Derecha (Textos)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              incident.title,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${incident.type.name.toUpperCase()} · ${incident.description}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('👉 ', style: TextStyle(fontSize: 14)),
                                Expanded(
                                  child: Text(
                                    '¿Sigue ahí este problema?',
                                    style: TextStyle(
                                      color: Colors.deepOrange.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
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
                  
                  const SizedBox(height: 16.0),
                  
                  // B. Sección de Botones (Actions)
                  Row(
                    children: [
                      // Botón Izquierdo ("Ya no")
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onDismiss(true),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.grey.shade300),
                            foregroundColor: Colors.grey.shade800,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text(
                            'Ya no',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      // Botón Derecho ("Sí, sigue")
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _validate(context, ref),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: severityColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text(
                            'Sí, sigue',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12.0),
                  
                  // C. Pie de página (Footer)
                  Center(
                    child: Text(
                      '+5 puntos por confirmar · Ayudas a calcular la severidad real',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                      ),
                    ),
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

