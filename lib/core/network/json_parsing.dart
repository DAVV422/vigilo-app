/// Convierte a `double` un valor numérico que llega del backend, tolerando que
/// venga como número o como texto.
///
/// Hace falta porque las columnas `NUMERIC` de Postgres viajan como *string*:
/// el driver `pg` las serializa así a propósito, para no perder precisión al
/// pasarlas por el `double` de JavaScript. El backend normaliza la mayoría con
/// `Number(...)` antes de responder, pero basta que un endpoint se lo olvide
/// para que un `as num` acá lance en medio del parseo.
///
/// Ese fallo es especialmente traicionero en una escritura: la petición ya
/// devolvió 201 y el servidor ya guardó el registro, así que la excepción
/// convierte una operación exitosa en un error visible, y el usuario reintenta
/// y duplica el dato. Pasó exactamente eso con `citizen.trustScore` al publicar
/// material reciclable.
double? toDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
