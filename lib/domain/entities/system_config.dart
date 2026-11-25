/// Un parámetro que gobierna el comportamiento del sistema.
///
/// El valor se guarda siempre como texto —la columna es `varchar` y el DTO
/// solo exige que no esté vacío—, aunque el código que lo lee espere un
/// entero. El servidor **no valida el tipo**: `PATCH` con `"muchas"` sobre
/// las horas de auto-confirmación devuelve 200. La única defensa es el
/// cliente, y por eso existe [SystemConfigSpec].
class SystemConfig {
  const SystemConfig({
    required this.key,
    required this.value,
    this.description,
    this.updatedAt,
  });

  final String key;
  final String value;
  final String? description;
  final DateTime? updatedAt;

  int? get asInt => int.tryParse(value.trim());

  factory SystemConfig.fromJson(Map<String, dynamic> json) => SystemConfig(
        key: json['configKey'] as String,
        value: json['configValue'] as String? ?? '',
        description: json['description'] as String?,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );
}

/// Qué espera el código detrás de cada clave.
///
/// Vive en el cliente porque la base no declara el tipo de una
/// configuración: guarda texto. Mientras eso siga así, esta tabla es el
/// único lugar donde está escrito que las horas son un entero.
///
/// Una clave desconocida no tiene entrada acá y se edita como texto libre,
/// sin validar: es preferible a esconderla.
class SystemConfigSpec {
  const SystemConfigSpec({
    required this.label,
    required this.unit,
    required this.consequence,
    required this.min,
    required this.max,
    this.confirmBelow,
  });

  /// Nombre legible. La clave es en inglés y con guiones bajos.
  final String label;

  /// Se escribe al lado del campo. Un número sin unidad se malinterpreta.
  final String unit;

  /// **Qué pasa** si se cambia, no qué significa. La descripción que manda
  /// el servidor está escrita para quien programó el sistema.
  final String consequence;

  final int min;
  final int max;

  /// Por debajo de esto se pide confirmación: no es inválido, es raro.
  final int? confirmBelow;

  static const Map<String, SystemConfigSpec> known = {
    'max_active_pickups_default': SystemConfigSpec(
      label: 'Recojos activos por recolector',
      unit: 'recojos',
      consequence:
          'Un recolector con este número de recojos en curso no puede '
          'reclamar otro hasta cerrar uno.',
      min: 1,
      max: 50,
    ),
    'pickup_auto_confirm_hours': SystemConfigSpec(
      label: 'Plazo de auto-confirmación',
      unit: 'horas',
      consequence:
          'Pasado este plazo sin que el ciudadano responda, el recojo se da '
          'por confirmado y se liquidan los puntos.',
      min: 1,
      max: 720,
      // Bajarlo de un día significa pagar sin confirmación humana mucho
      // antes de lo que nadie espera.
      confirmBelow: 24,
    ),
  };

  static SystemConfigSpec? of(String key) => known[key];
}
