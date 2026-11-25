/// Vocabulario de etiquetas de calificación.
///
/// Vive en un solo archivo a propósito: la hoja que las ofrece y la pantalla
/// que las muestra tienen que hablar el mismo idioma. Con dos listas, una se
/// queda atrás y aparecen etiquetas sin traducir en el detalle.
///
/// El identificador se guarda en `snake_case` sin acentos y es lo que viaja
/// al backend en el arreglo `tags`. Son los mismos identificadores que usan
/// los datos sembrados del servidor; inventar un vocabulario nuevo dejaría
/// el histórico inconsistente.
library;

const Map<String, String> _labels = {
  'puntual': 'Puntual',
  'amable': 'Amable',
  'peso_justo': 'Peso justo',
  'material_bien_separado': 'Material bien separado',
  'buena_comunicacion': 'Buena comunicación',
  'llego_tarde': 'Llegó tarde',
  'peso_discutible': 'El peso no coincidía',
};

/// Etiquetas que se le ofrecen a quien califica a un **recolector**.
const List<String> recyclerTags = [
  'puntual',
  'amable',
  'peso_justo',
  'llego_tarde',
  'peso_discutible',
];

/// Etiquetas que se le ofrecen a quien califica a un **ciudadano**.
const List<String> citizenTags = [
  'material_bien_separado',
  'buena_comunicacion',
  'amable',
  'peso_discutible',
];

/// Etiquetas que solo tienen sentido con una nota baja. La hoja las oculta
/// cuando el usuario puso 4 o 5 estrellas, para reducir el ruido.
const Set<String> negativeTags = {'llego_tarde', 'peso_discutible'};

/// Texto legible de una etiqueta.
///
/// Una etiqueta desconocida —porque la escribió una versión más nueva de la
/// app, o porque alguien la insertó a mano— se devuelve tal cual. Nunca debe
/// desaparecer ni romper la pantalla: es información real que el servidor
/// guardó.
String ratingTagLabel(String tag) => _labels[tag] ?? tag;
