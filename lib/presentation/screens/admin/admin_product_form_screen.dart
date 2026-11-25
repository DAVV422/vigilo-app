import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/errors/describe_error.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/entities/store_product.dart';
import '../../../domain/repositories/store_repository.dart';
import '../../../theme/app_colors.dart';
import '../../providers/providers.dart';
import 'widgets/admin_scaffold.dart';

const _log = AppLogger('AdminTienda');

/// Categorías ofrecidas como lista cerrada.
///
/// `StoreService.create` hace `category.toUpperCase()`, así que un campo
/// libre terminaría con `CUPONES`, `CUPON` y `CUPONES ` conviviendo en dos
/// semanas. Son las que usa el catálogo sembrado.
const _categories = ['ECOLOGICO', 'MASCOTAS', 'CUPONES', 'HOGAR', 'MOVILIDAD', 'GENERAL'];

/// Alta y edición de un producto, en la misma pantalla: se distinguen por
/// recibir o no un [product].
class AdminProductFormScreen extends ConsumerStatefulWidget {
  const AdminProductFormScreen({super.key, this.product});

  final StoreProduct? product;

  @override
  ConsumerState<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends ConsumerState<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _pointsCost;
  late final TextEditingController _stock;
  late String _category;

  /// Imagen elegida y todavía no subida. La subida ocurre al guardar, no al
  /// elegir: subirla al elegir deja un archivo huérfano en el servidor cada
  /// vez que alguien abre el formulario, prueba una foto y se arrepiente.
  File? _pickedImage;

  bool _saving = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _pointsCost = TextEditingController(text: p?.pointsCost.toString() ?? '');
    _stock = TextEditingController(text: p?.stock.toString() ?? '');
    _category = _categories.contains(p?.category) ? p!.category : 'GENERAL';
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _pointsCost.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() => _pickedImage = File(picked.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    // En el alta la imagen es obligatoria: el DTO exige `imageUrl`.
    if (!_isEdit && _pickedImage == null) {
      _snack('Elegí una imagen para el producto.', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      String? imageUrl;
      if (_pickedImage != null) {
        final uploaded = await ref
            .read(mediaRepositoryProvider)
            .uploadImage(_pickedImage!.path, folder: 'products');
        imageUrl = uploaded.url;
      }

      final input = ProductInput(
        name: _name.text.trim(),
        description: _description.text.trim(),
        imageUrl: imageUrl,
        pointsCost: int.parse(_pointsCost.text.trim()),
        stock: int.parse(_stock.text.trim()),
        category: _category,
      );

      final repo = ref.read(storeRepositoryProvider);
      if (_isEdit) {
        await repo.updateProduct(widget.product!.id, input);
      } else {
        await repo.createProduct(input);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(
        describeError(
          e,
          st,
          log: _log,
          operation: _isEdit ? 'guardar el producto' : 'crear el producto',
          whereToCheck: 'el catálogo',
        ),
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
      title: _isEdit ? 'Editar producto' : 'Nuevo producto',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildImagePicker(),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nombre'),
              // Mismas reglas que el DTO, comprobadas antes de enviar: un
              // 400 después de subir una foto por datos móviles es una mala
              // experiencia perfectamente evitable.
              maxLength: 150,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
            ),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 3,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'La descripción es obligatoria' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pointsCost,
                    decoration: const InputDecoration(labelText: 'Costo', suffixText: 'pts'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      if (n == null) return 'Número inválido';
                      if (n < 1) return 'Debe ser mayor a cero';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stock,
                    decoration: const InputDecoration(labelText: 'Stock'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      if (n == null) return 'Número inválido';
                      if (n < 0) return 'No puede ser negativo';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: [
                for (final c in _categories) DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) => setState(() => _category = v ?? 'GENERAL'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEdit ? 'Guardar cambios' : 'Crear producto'),
            ),
            if (_saving) ...[
              const SizedBox(height: 8),
              const Text(
                'Subiendo la imagen y guardando…',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    final existing = widget.product?.imageUrl;

    return Column(
      children: [
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: _pickedImage != null
              ? Image.file(_pickedImage!, fit: BoxFit.contain)
              : (existing != null && existing.isNotEmpty)
                  ? Image.network(
                      existing,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.image_not_supported_outlined,
                        size: 36,
                        color: AppColors.outline,
                      ),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined,
                      size: 36, color: AppColors.outline),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _saving ? null : () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text('Galería'),
            ),
            TextButton.icon(
              onPressed: _saving ? null : () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: const Text('Cámara'),
            ),
          ],
        ),
      ],
    );
  }
}
