import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/describe_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/entities/company.dart';
import '../../../domain/repositories/companies_repository.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';
import 'widgets/admin_scaffold.dart';

const _log = AppLogger('AdminEmpresas');

/// Alta de una empresa.
///
/// Hasta que se relajó la validación del identificador tributario, esta
/// pantalla no habría podido existir: el servidor exigía la forma de un RUC
/// peruano y ningún NIT boliviano la cumple.
class AdminCompanyFormScreen extends ConsumerStatefulWidget {
  const AdminCompanyFormScreen({super.key});

  @override
  ConsumerState<AdminCompanyFormScreen> createState() =>
      _AdminCompanyFormScreenState();
}

class _AdminCompanyFormScreenState
    extends ConsumerState<AdminCompanyFormScreen> {
  final _legalName = TextEditingController();
  final _displayName = TextEditingController();
  final _taxId = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();

  CompanyType _type = CompanyType.security;
  bool _saving = false;
  String? _taxIdError;

  @override
  void dispose() {
    _legalName.dispose();
    _displayName.dispose();
    _taxId.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_legalName.text.trim().isEmpty) return 'Falta la razón social.';
    if (_displayName.text.trim().isEmpty) return 'Falta el nombre comercial.';

    final taxId = _taxId.text.trim();
    if (taxId.isEmpty) return 'Falta el identificador tributario.';
    // Mismo criterio que el servidor: solo dígitos, entre 5 y 15.
    if (!RegExp(r'^\d{5,15}$').hasMatch(taxId)) {
      return 'El identificador tributario tiene que ser de 5 a 15 dígitos, '
          'sin guiones ni espacios.';
    }

    if (_phone.text.trim().isEmpty) return 'Falta el teléfono de contacto.';

    final email = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'El correo de contacto no es válido.';
    }
    return null;
  }

  Future<void> _save() async {
    final problema = _validate();
    if (problema != null) {
      _snack(problema, isError: true);
      return;
    }

    setState(() {
      _saving = true;
      _taxIdError = null;
    });

    try {
      await ref.read(companiesRepositoryProvider).create(
            CompanyInput(
              legalName: _legalName.text.trim(),
              displayName: _displayName.text.trim(),
              type: _type,
              taxId: _taxId.text.trim(),
              contactPhone: _phone.text.trim(),
              contactEmail: _email.text.trim(),
            ),
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        // El 409 es el error esperable acá —la columna es única— y merece
        // señalar el campo, no un mensaje genérico al pie.
        _taxIdError = e.statusCode == 409
            ? 'Ya existe una empresa con este identificador.'
            : null;
      });
      _snack(e.message, isError: true);
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(
        describeError(e, st,
            log: _log,
            operation: 'crear la empresa',
            whereToCheck: 'la lista de empresas'),
        isError: true,
      );
    }
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Nueva empresa',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field(
            controller: _displayName,
            label: 'Nombre comercial',
            help: 'Es el que ve la gente en la app.',
            maxLength: 150,
          ),
          const SizedBox(height: 14),
          _field(
            controller: _legalName,
            label: 'Razón social',
            help: 'El nombre legal completo.',
            maxLength: 200,
          ),
          const SizedBox(height: 18),
          const Text(
            'TIPO DE EMPRESA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          // El tipo no es una etiqueta: decide qué incidentes se le asignan
          // automáticamente cuando caen dentro de su zona.
          RadioGroup<CompanyType>(
            groupValue: _type,
            onChanged: (v) {
              if (_saving || v == null) return;
              setState(() => _type = v);
            },
            child: Column(
              children: [
                for (final t in CompanyType.values)
                  RadioListTile<CompanyType>(
                    value: t,
                    title: Text(t.label, style: const TextStyle(fontSize: 14)),
                    subtitle:
                        Text(t.help, style: const TextStyle(fontSize: 12)),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _taxId,
            enabled: !_saving,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Identificador tributario (NIT)',
              helperText: 'Solo dígitos, de 5 a 15. Sin guiones ni espacios.',
              helperMaxLines: 2,
              errorText: _taxIdError,
            ),
            onChanged: (_) {
              if (_taxIdError != null) setState(() => _taxIdError = null);
            },
          ),
          const SizedBox(height: 14),
          _field(
            controller: _phone,
            label: 'Teléfono de contacto',
            help: 'A quién llamar por un incidente asignado.',
            keyboardType: TextInputType.phone,
            maxLength: 30,
          ),
          const SizedBox(height: 14),
          _field(
            controller: _email,
            label: 'Correo de contacto',
            help: null,
            keyboardType: TextInputType.emailAddress,
            maxLength: 255,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Crear empresa'),
          ),
          const SizedBox(height: 10),
          const Text(
            'La empresa queda pendiente de verificación. Hasta verificarla '
            'no recibe incidentes asignados.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String? help,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      enabled: !_saving,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        helperText: help,
        helperMaxLines: 2,
        counterText: '',
      ),
    );
  }
}
