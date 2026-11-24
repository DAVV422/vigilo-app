/// Conversión tolerante de los valores numéricos que llegan del backend.
///
/// Hace falta porque las columnas `NUMERIC` de Postgres viajan como *texto*:
/// el driver `pg` las serializa así a propósito, para no perder precisión al
/// pasarlas por el `double` de JavaScript. El backend normaliza con
/// `Number(...)` antes de responder, pero basta que un endpoint se lo olvide
/// para que un `as num` lance en medio del parseo.
///
/// Ese fallo es especialmente traicionero en una escritura: la petición ya
/// devolvió 201 y el servidor ya guardó el registro, así que la excepción
/// convierte una operación exitosa en un error visible, y el usuario reintenta
/// y duplica el dato. Pasó exactamente eso con `citizen.trustScore` al publicar
/// material reciclable: llegaba como `"5.00"`.
///
/// Estas funciones aceptan `num` o `String` numérico. Lo que **no** hacen es
/// inventar valores: si un campo obligatorio falta, [toDouble] y [toInt] lanzan
/// igual que antes, pero con un mensaje que nombra el campo en vez del opaco
/// "String is not a subtype of num". Un campo ausente es un contrato roto y
/// debe verse; un campo con el tipo equivocado es ruido de serialización y no
/// debería tumbar la pantalla.
library;

/// Error de contrato: el backend no mandó un campo numérico obligatorio, o
/// mandó algo que no es un número.
class JsonFieldFormatException implements Exception {
  JsonFieldFormatException(this.field, this.value);

  final String field;
  final Object? value;

  @override
  String toString() =>
      'Campo numérico inválido "$field": se esperaba un número y llegó '
      '${value == null ? 'null' : '${value.runtimeType} ($value)'}';
}

num? _asNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) return num.tryParse(value.trim());
  return null;
}

/// `double` obligatorio. Lanza [JsonFieldFormatException] si falta o no es
/// numérico. [field] solo se usa para el mensaje de error.
double toDouble(dynamic value, {String field = 'desconocido'}) {
  final parsed = _asNum(value);
  if (parsed == null) throw JsonFieldFormatException(field, value);
  return parsed.toDouble();
}

/// `int` obligatorio. Lanza [JsonFieldFormatException] si falta o no es
/// numérico. [field] solo se usa para el mensaje de error.
int toInt(dynamic value, {String field = 'desconocido'}) {
  final parsed = _asNum(value);
  if (parsed == null) throw JsonFieldFormatException(field, value);
  return parsed.toInt();
}

/// `double` opcional: devuelve `null` si el campo falta o no es numérico.
double? toDoubleOrNull(dynamic value) => _asNum(value)?.toDouble();

/// `int` opcional: devuelve `null` si el campo falta o no es numérico.
int? toIntOrNull(dynamic value) => _asNum(value)?.toInt();
