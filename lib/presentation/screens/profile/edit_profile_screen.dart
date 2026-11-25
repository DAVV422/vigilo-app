import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/describe_error.dart';
import '../../../core/format/phone.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/entities/user.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';

const _log = AppLogger('EditarPerfil');

/// Editar el perfil propio.
///
/// Es el único endpoint de usuario que no tenía vista. El dato que más
/// importa es el teléfono: es por donde un recolector coordina un recojo, y
/// hasta ahora un dígito de más al registrarse no se podía corregir.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final User _original = ref.read(authProvider)!;

  late final _firstName = TextEditingController(text: _original.name);
  late final _lastName = TextEditingController(text: _original.lastName);
  late final _phone = TextEditingController(text: _original.phone);

  File? _pickedImage;
  bool _removePhoto = false;
  bool _saving = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool get _hasPhoto =>
      _pickedImage != null ||
      (!_removePhoto && _original.avatarUrl.startsWith('http'));

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() {
      _pickedImage = File(picked.path);
      _removePhoto = false;
    });
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar una foto'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Quitar la foto',
                    style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() {
                    _pickedImage = null;
                    _removePhoto = true;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final nombre = _firstName.text.trim();
    final apellido = _lastName.text.trim();

    // El DTO no exige que no estén vacíos, así que `""` se guardaría y el
    // perfil quedaría sin nombre.
    if (nombre.isEmpty) {
      _snack('El nombre no puede quedar vacío.', isError: true);
      return;
    }
    if (apellido.isEmpty) {
      _snack('El apellido no puede quedar vacío.', isError: true);
      return;
    }

    final telefonoCrudo = _phone.text.trim();
    final telefono = normalizePhone(telefonoCrudo);
    if (telefono.isNotEmpty && !isValidPhone(telefono)) {
      _snack(
        'El teléfono tiene que tener entre 7 y 15 dígitos.',
        isError: true,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      String? avatarUrl;
      if (_pickedImage != null) {
        // Se sube al guardar y no al elegirla: subirla al elegir deja un
        // archivo huérfano cada vez que alguien prueba una foto y se
        // arrepiente.
        final subida = await ref
            .read(mediaRepositoryProvider)
            .uploadImage(_pickedImage!.path, folder: 'avatars');
        avatarUrl = subida.url;
      } else if (_removePhoto) {
        // Cadena vacía y no `null`: el modo demo usa `avatarUrl` como
        // inicial y el perfil distingue una URL real por el prefijo `http`.
        avatarUrl = '';
      }

      await ref.read(authProvider.notifier).updateProfile(
            firstName: nombre != _original.name ? nombre : null,
            lastName: apellido != _original.lastName ? apellido : null,
            // Vacío no se manda: el DTO lo rechazaría por no cumplir la
            // expresión, aunque el campo sea opcional.
            phone: telefono.isNotEmpty && telefono != _original.phone
                ? telefono
                : null,
            avatarUrl: avatarUrl,
          );

      if (!mounted) return;
      Navigator.pop(context);
      _snack(
        telefono != telefonoCrudo && telefono.isNotEmpty
            ? 'Perfil actualizado. El teléfono se guardó como $telefono.'
            : 'Perfil actualizado.',
      );
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(
        describeError(e, st,
            log: _log,
            operation: 'guardar el perfil',
            whereToCheck: 'tu perfil'),
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
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Editar perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // La foto va arriba porque es lo que la mitad de las veces se
          // vino a cambiar, y es lo único que se ve de un vistazo.
          Center(child: _buildAvatar()),
          const SizedBox(height: 24),
          TextField(
            controller: _firstName,
            enabled: !_saving,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              counterText: '',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _lastName,
            enabled: !_saving,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Apellido',
              counterText: '',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _phone,
            enabled: !_saving,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Teléfono',
              helperText: 'Es por donde te contactan para coordinar un '
                  'recojo. Se guarda sin espacios ni guiones.',
              helperMaxLines: 3,
            ),
          ),
          const SizedBox(height: 18),
          _buildReadOnly('Correo electrónico', _original.email),
          _buildReadOnly('Nombre de usuario', '@${_original.username}'),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _saving ? null : _showPhotoOptions,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(child: _buildAvatarContent()),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_camera,
                    size: 16, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _hasPhoto ? 'Tocá para cambiarla' : 'Tocá para agregar una foto',
            style: const TextStyle(
                fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    if (_pickedImage != null) {
      return Image.file(_pickedImage!, fit: BoxFit.cover);
    }
    if (!_removePhoto && _original.avatarUrl.startsWith('http')) {
      return Image.network(
        _original.avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(Icons.person,
            size: 48, color: AppColors.onSurfaceVariant),
      );
    }
    return const Icon(Icons.person, size: 48, color: AppColors.onSurfaceVariant);
  }

  /// El correo y el usuario se muestran porque la gente los busca acá, y no
  /// se editan porque el DTO no los acepta: el correo es la credencial de
  /// acceso y cambiarlo necesita verificación, no un campo de texto.
  Widget _buildReadOnly(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
          const Icon(Icons.lock_outline,
              size: 14, color: AppColors.onSurfaceVariant),
        ],
      ),
    );
  }
}
