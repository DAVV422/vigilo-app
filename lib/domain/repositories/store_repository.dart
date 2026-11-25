import '../entities/redemption.dart';
import '../entities/store_product.dart';

abstract class StoreRepository {
  Future<List<StoreProduct>> getProducts();

  /// Canje atómico en el servidor (descuenta stock y puntos en una sola
  /// transacción) — ver docs/reglas-negocio.md#tienda-de-canje. Devuelve el
  /// código de cupón generado y el nuevo saldo de puntos del usuario.
  Future<({Redemption redemption, int remainingBalance})> redeem(String productId);

  Future<List<Redemption>> getMyRedemptions();

  // --- Administración (ADMIN) ---

  /// Catálogo completo, **incluidos los productos desactivados**.
  ///
  /// `getProducts()` no sirve para administrar: el backend filtra por
  /// `active = true` salvo que se pase `activeOnly=false`, así que un
  /// producto desactivado desaparecería de la pantalla y nadie podría
  /// volver a activarlo.
  Future<List<StoreProduct>> getAllProducts();

  Future<StoreProduct> createProduct(ProductInput input);

  /// Edición parcial: solo viaja lo que no sea nulo. Activar y desactivar
  /// no necesitan método propio, son un `active` acá.
  Future<StoreProduct> updateProduct(String id, ProductInput input);

  // --- Mostrador (ADMIN, MODERATOR) ---

  /// Busca un canje por el código que presenta la persona. Lanza
  /// `ApiException` 404 si no existe.
  Future<Redemption> findRedemptionByCode(String code);

  /// Marca el canje como entregado. No se deshace.
  Future<void> fulfillRedemption(String id);
}

/// Datos de un producto para crear o editar.
///
/// Todos opcionales porque `PATCH` manda solo lo que cambió; en el alta la
/// pantalla se encarga de exigir los obligatorios antes de llamar.
class ProductInput {
  const ProductInput({
    this.name,
    this.description,
    this.imageUrl,
    this.pointsCost,
    this.stock,
    this.category,
    this.active,
  });

  final String? name;
  final String? description;
  final String? imageUrl;
  final int? pointsCost;
  final int? stock;
  final String? category;
  final bool? active;

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (pointsCost != null) 'pointsCost': pointsCost,
        if (stock != null) 'stock': stock,
        if (category != null) 'category': category,
        if (active != null) 'active': active,
      };
}
