import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/entities/audit_entry.dart';
import '../../../theme/app_colors.dart';
import 'widgets/admin_scaffold.dart';

/// El detalle de un registro de la bitácora.
///
/// Lo legible arriba y lo técnico abajo: quien abre esto viene con una
/// pregunta concreta («¿quién tocó esto y cuándo?») y la ruta HTTP, la IP y
/// el navegador son para el caso raro en que esa respuesta no alcanza.
class AdminAuditEntryScreen extends StatelessWidget {
  const AdminAuditEntryScreen({super.key, required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Registro',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildResumen(context),
          const SizedBox(height: 16),
          _buildTecnico(context),
          const SizedBox(height: 16),
          _buildEstado(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildResumen(BuildContext context) {
    return _card(
      title: 'QUÉ PASÓ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: entry.failed ? AppColors.error : AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          _fila(
            'Quién',
            entry.actor?.fullName ?? 'Sin sesión',
            // No es «desconocido»: en un inicio de sesión todavía no hay
            // actor, y eso es una afirmación distinta.
            hint: entry.actor == null
                ? 'La operación se hizo sin sesión iniciada.'
                : '@${entry.actor!.username}',
          ),
          _fila('Cuándo', _fechaHora(entry.createdAt)),
          _fila('Resultado', '${entry.statusCode}'),
        ],
      ),
    );
  }

  Widget _buildTecnico(BuildContext context) {
    return _card(
      title: 'DETALLE TÉCNICO',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fila('Petición', '${entry.httpMethod} ${entry.httpPath}'),
          if (entry.entityId != null)
            _copiable(context, 'Recurso', entry.entityId!),
          if (entry.ipAddress != null) _fila('IP', entry.ipAddress!),
          if (entry.userAgent != null)
            _fila('Dispositivo', entry.userAgent!, maxLines: 3),
        ],
      ),
    );
  }

  Widget _buildEstado() {
    // Una de las dos cosas, nunca un panel vacío: las entradas de error no
    // traen estado posterior, traen el mensaje en los metadatos.
    if (entry.failed && entry.errorMessage != null) {
      return _card(
        title: 'ERROR',
        child: Text(
          entry.errorMessage!,
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
      );
    }

    final estado = entry.newState;
    if (estado == null || estado.isEmpty) {
      return _card(
        title: 'ESTADO POSTERIOR',
        child: const Text(
          'Esta operación no registró el estado del recurso.',
          style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
        ),
      );
    }

    return _card(
      title: 'ESTADO POSTERIOR',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              const JsonEncoder.withIndent('  ').convert(estado),
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Las credenciales se guardan redactadas.',
            style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _fila(String label, String value, {String? hint, int maxLines = 2}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                if (hint != null)
                  Text(
                    hint,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// El identificador del recurso es lo que alguien va a querer pegar en
  /// otra consulta, y no se puede escribir a mano desde un teléfono.
  Widget _copiable(BuildContext context, String label, String value) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Identificador copiado.')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 92,
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
            ),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
            const Icon(Icons.copy_outlined,
                size: 15, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  String _fechaHora(DateTime d) {
    final l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/'
        '${l.month.toString().padLeft(2, '0')}/${l.year} '
        '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }
}
