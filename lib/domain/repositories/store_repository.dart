import '../entities/redemption.dart';
import '../entities/store_product.dart';

abstract class StoreRepository {
  Future<List<StoreProduct>> getProducts();

  /// Canje atómico en el servidor (descuenta stock y puntos en una sola
  /// transacción) — ver docs/reglas-negocio.md#tienda-de-canje. Devuelve el
  /// código de cupón generado y el nuevo saldo de puntos del usuario.
  Future<({Redemption redemption, int remainingBalance})> redeem(String productId);

  Future<List<Redemption>> getMyRedemptions();
}
