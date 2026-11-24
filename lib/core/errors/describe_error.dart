import '../logging/app_logger.dart';
import '../network/api_exception.dart';

/// Traduce una excepción al mensaje que ve el usuario, y deja constancia en
/// el log de las que no venían del backend.
///
/// Antes cada pantalla hacía `e is ApiException ? e.message : '<genérico>'`,
/// con dos problemas:
///
/// 1. **La rama genérica se tragaba el error.** Una excepción de parseo o de
///    estado no quedaba registrada en ningún lado, así que lo único que había
///    para diagnosticar era el mensaje que veía el usuario. Acá se registra
///    siempre, con stack trace.
///
/// 2. **Invitaba a reintentar a ciegas.** El mensaje "revisa tu conexión e
///    intenta de nuevo" también aparecía cuando la petición había salido bien
///    y lo que falló fue interpretar la respuesta. En una escritura eso
///    duplica datos: pasó al publicar material reciclable, donde el servidor
///    respondía 201, la app mostraba error y el usuario publicaba dos veces.
///    Por eso [whereToCheck] existe: en operaciones que escriben, el mensaje
///    dice dónde comprobar antes de repetir.
///
/// [operation] es para el log, en infinitivo y en minúscula ("publicar
/// material reciclable"). [whereToCheck] es el nombre de la pantalla donde el
/// usuario puede verificar si la operación se completó; dejarlo en `null`
/// significa que la operación solo lee y repetirla es inofensivo.
String describeError(
  Object error,
  StackTrace stackTrace, {
  required AppLogger log,
  required String operation,
  String? whereToCheck,
}) {
  if (error is ApiException) {
    // El backend ya dijo qué pasó y con qué status; no hace falta stack.
    log.warning('Fallo al $operation: $error');
    return error.message;
  }

  log.error('Error inesperado al $operation', error, stackTrace);

  if (whereToCheck != null) {
    return 'Ocurrió un error inesperado. Es posible que la operación sí se '
        'haya completado: revisa "$whereToCheck" antes de volver a intentar, '
        'para no duplicarla.';
  }

  return 'Ocurrió un error inesperado al $operation. Intenta de nuevo.';
}
