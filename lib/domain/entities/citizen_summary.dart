class CitizenSummary {
  final int incidentsReported;
  final int incidentsResolved;
  final int incidentsValidated;
  final int listingsPublished;
  final int listingsCompleted;
  final double recycledAsCitizenKg;
  final int pickupsCompletedAsRecycler;
  final double recycledAsRecyclerKg;
  final int pointsBalance;
  final int pointsEarned;
  final int pointsRedeemed;

  CitizenSummary({
    required this.incidentsReported,
    required this.incidentsResolved,
    required this.incidentsValidated,
    required this.listingsPublished,
    required this.listingsCompleted,
    required this.recycledAsCitizenKg,
    required this.pickupsCompletedAsRecycler,
    required this.recycledAsRecyclerKg,
    required this.pointsBalance,
    required this.pointsEarned,
    required this.pointsRedeemed,
  });

  factory CitizenSummary.fromJson(Map<String, dynamic> json) {
    final incidents = json['incidents'] as Map<String, dynamic>;
    final recycling = json['recycling'] as Map<String, dynamic>;
    final asCitizen = recycling['asCitizen'] as Map<String, dynamic>;
    final asRecycler = recycling['asRecycler'] as Map<String, dynamic>;
    final points = json['points'] as Map<String, dynamic>;

    return CitizenSummary(
      incidentsReported: incidents['reported'] as int,
      incidentsResolved: incidents['resolved'] as int,
      incidentsValidated: incidents['validated'] as int,
      listingsPublished: asCitizen['listingsPublished'] as int,
      listingsCompleted: asCitizen['listingsCompleted'] as int,
      recycledAsCitizenKg: (asCitizen['totalWeightKg'] as num).toDouble(),
      pickupsCompletedAsRecycler: asRecycler['pickupsCompleted'] as int,
      recycledAsRecyclerKg: (asRecycler['totalWeightKg'] as num).toDouble(),
      pointsBalance: points['balance'] as int,
      pointsEarned: points['totalEarned'] as int,
      pointsRedeemed: points['totalRedeemed'] as int,
    );
  }
}
