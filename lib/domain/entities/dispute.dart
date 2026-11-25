import '../../core/network/json_parsing.dart';

/// Una de las dos partes de un recojo disputado, con su reputación.
///
/// La reputación no es decorativa acá: un recolector con 3,00 y uno con
/// 4,90 merecen distinta presunción al juzgar un reclamo de pesaje.
class DisputeParty {
  const DisputeParty({
    required this.id,
    required this.name,
    this.trustScore,
    this.ratingsCount = 0,
  });

  final String id;
  final String name;
  final double? trustScore;
  final int ratingsCount;

  factory DisputeParty.fromJson(Map<String, dynamic> json) => DisputeParty(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Usuario',
        trustScore: toDoubleOrNull(json['trustScore']),
        ratingsCount: toIntOrNull(json['ratingsCount']) ?? 0,
      );
}

/// Una línea del pesaje registrado por el recolector.
class DisputeWeighIn {
  const DisputeWeighIn({
    required this.materialTypeId,
    this.materialName,
    required this.actualWeightGrams,
    required this.pointsAwarded,
  });

  final String materialTypeId;
  final String? materialName;
  final double actualWeightGrams;
  final int pointsAwarded;

  factory DisputeWeighIn.fromJson(Map<String, dynamic> json) => DisputeWeighIn(
        materialTypeId: json['materialTypeId'] as String,
        materialName: json['materialName'] as String?,
        // Columna NUMERIC: el backend la normaliza, pero el parseo tolerante
        // es la red de seguridad.
        actualWeightGrams: toDouble(json['actualWeightGrams'], field: 'actualWeightGrams'),
        pointsAwarded: toInt(json['pointsAwarded'], field: 'pointsAwarded'),
      );
}

class DisputeCompensation {
  const DisputeCompensation({
    required this.paymentMethod,
    required this.grossAmount,
    required this.status,
  });

  final String paymentMethod;
  final double grossAmount;
  final String status;

  factory DisputeCompensation.fromJson(Map<String, dynamic> json) =>
      DisputeCompensation(
        paymentMethod: json['paymentMethod'] as String? ?? '',
        grossAmount: toDoubleOrNull(json['grossAmount']) ?? 0,
        status: json['status'] as String? ?? '',
      );
}

class DisputePickup {
  const DisputePickup({
    required this.id,
    required this.status,
    this.address,
    this.completedAt,
    this.citizen,
    this.recycler,
    this.results = const [],
    this.compensation,
  });

  final String id;
  final String status;
  final String? address;
  final DateTime? completedAt;
  final DisputeParty? citizen;
  final DisputeParty? recycler;
  final List<DisputeWeighIn> results;
  final DisputeCompensation? compensation;

  factory DisputePickup.fromJson(Map<String, dynamic> json) => DisputePickup(
        id: json['id'] as String,
        status: json['status'] as String? ?? '',
        address: json['address'] as String?,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        citizen: json['citizen'] != null
            ? DisputeParty.fromJson(json['citizen'] as Map<String, dynamic>)
            : null,
        recycler: json['recycler'] != null
            ? DisputeParty.fromJson(json['recycler'] as Map<String, dynamic>)
            : null,
        results: ((json['results'] as List<dynamic>?) ?? const [])
            .map((r) => DisputeWeighIn.fromJson(r as Map<String, dynamic>))
            .toList(),
        compensation: json['compensation'] != null
            ? DisputeCompensation.fromJson(json['compensation'] as Map<String, dynamic>)
            : null,
      );
}

class DisputeResolution {
  const DisputeResolution({
    this.action,
    this.notes,
    this.resolvedAt,
    this.resolvedBy,
  });

  final String? action;
  final String? notes;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  factory DisputeResolution.fromJson(Map<String, dynamic> json) => DisputeResolution(
        action: json['action'] as String?,
        notes: json['notes'] as String?,
        resolvedAt: json['resolvedAt'] != null
            ? DateTime.parse(json['resolvedAt'] as String)
            : null,
        resolvedBy: json['resolvedBy'] as String?,
      );
}

/// Una disputa sobre el pesaje de un recojo.
///
/// La lista y el detalle devuelven formas distintas: `GET /disputes` no
/// trae el recojo desarmado ni las partes con su reputación, así que
/// [pickup] viene nulo ahí y poblado en el detalle.
class Dispute {
  const Dispute({
    required this.id,
    required this.status,
    required this.reason,
    required this.createdAt,
    this.evidenceMediaUrl,
    this.openedBy,
    this.pickup,
    this.resolution,
  });

  final String id;

  /// `OPEN` · `RESOLVED` · `REJECTED`. Texto y no enum: un estado nuevo del
  /// servidor tiene que mostrarse, no romper la pantalla.
  final String status;
  final String reason;
  final DateTime createdAt;
  final String? evidenceMediaUrl;
  final DisputeParty? openedBy;
  final DisputePickup? pickup;
  final DisputeResolution? resolution;

  bool get isOpen => status == 'OPEN';

  factory Dispute.fromJson(Map<String, dynamic> json) {
    // La lista devuelve la entidad cruda, con `openedByUser` anidado; el
    // detalle devuelve un DTO con `openedBy` ya aplanado.
    final openedByRaw = json['openedBy'] ?? json['openedByUser'];

    return Dispute(
      id: json['id'] as String,
      status: json['status'] as String? ?? 'OPEN',
      reason: json['reason'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      evidenceMediaUrl: json['evidenceMediaUrl'] as String?,
      openedBy: openedByRaw is Map<String, dynamic>
          ? DisputeParty.fromJson({
              'id': openedByRaw['id'],
              'name': openedByRaw['name'] ??
                  '${openedByRaw['firstName'] ?? ''} ${openedByRaw['lastName'] ?? ''}'.trim(),
              'trustScore': openedByRaw['trustScore'],
              'ratingsCount': openedByRaw['ratingsCount'],
            })
          : null,
      pickup: json['pickup'] is Map<String, dynamic> &&
              (json['pickup'] as Map<String, dynamic>).containsKey('results')
          ? DisputePickup.fromJson(json['pickup'] as Map<String, dynamic>)
          : null,
      resolution: json['resolution'] != null
          ? DisputeResolution.fromJson(json['resolution'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Las cuatro acciones que define el backend.
enum DisputeAction { adjustWeight, creditPoints, penalizeRecycler, dismiss }

extension DisputeActionX on DisputeAction {
  String get wire => switch (this) {
        DisputeAction.adjustWeight => 'ADJUST_WEIGHT',
        DisputeAction.creditPoints => 'CREDIT_POINTS',
        DisputeAction.penalizeRecycler => 'PENALIZE_RECYCLER',
        DisputeAction.dismiss => 'DISMISS',
      };

  String get label => switch (this) {
        DisputeAction.adjustWeight => 'Corregir el pesaje',
        DisputeAction.creditPoints => 'Acreditar puntos',
        DisputeAction.penalizeRecycler => 'Penalizar al recolector',
        DisputeAction.dismiss => 'Desestimar el reclamo',
      };

  String get help => switch (this) {
        DisputeAction.adjustWeight =>
          'Recalcula los puntos del recojo con el peso corregido.',
        DisputeAction.creditPoints =>
          'Acredita puntos al ciudadano sin tocar el pesaje registrado.',
        DisputeAction.penalizeRecycler =>
          'Aplica una sanción al recolector según la regla elegida.',
        DisputeAction.dismiss => 'Cierra la disputa sin cambios.',
      };
}
