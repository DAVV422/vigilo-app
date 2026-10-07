import '../../domain/entities/app_notification.dart';
import '../../domain/entities/material_type.dart';
import '../../domain/entities/points_transaction.dart';
import '../../domain/entities/recycling_listing.dart';
import '../../domain/entities/recycling_pickup.dart';
import '../../domain/entities/redemption.dart';
import '../../domain/entities/user.dart';

/// Estado compartido en memoria para el modo demo (ver [AppConfig.demoMode]).
/// Juega el rol que normalmente juega el backend: es la única fuente de
/// verdad mientras la app corre, y cada `Demo*RepositoryImpl` lee/escribe
/// acá en vez de llamar a la red. Se reinicia en cada arranque de la app —
/// para una presentación rápida eso es una ventaja, no un defecto.
class DemoState {
  /// Usuario con sesión activa. `null` hasta que se llama a login/register;
  /// volver a `null` en logout. Los repos de puntos/tienda/reciclaje
  /// mutan directamente los puntos de este objeto para que
  /// `AuthNotifier.reloadUser()` (que llama a `restoreSession`) siempre
  /// refleje el saldo actualizado sin necesitar un backend real.
  User? currentUser;

  final List<MaterialType> materials = [
    MaterialType(
      id: 'demo-mat-pet',
      name: 'Plástico PET',
      category: 'PLASTIC',
      unitOfMeasure: 'GRAMS',
      pointsPerKg: 10.0,
      minPayoutThreshold: 5.0,
      co2FactorPerKg: 1.5,
    ),
    MaterialType(
      id: 'demo-mat-paper',
      name: 'Cartón y Papel',
      category: 'PAPER_CARDBOARD',
      unitOfMeasure: 'GRAMS',
      pointsPerKg: 8.0,
      minPayoutThreshold: 5.0,
      co2FactorPerKg: 0.9,
    ),
    MaterialType(
      id: 'demo-mat-glass',
      name: 'Vidrio',
      category: 'GLASS',
      unitOfMeasure: 'GRAMS',
      pointsPerKg: 5.0,
      minPayoutThreshold: 3.0,
      co2FactorPerKg: 0.3,
    ),
    MaterialType(
      id: 'demo-mat-metal',
      name: 'Aluminio y Metales',
      category: 'METAL',
      unitOfMeasure: 'GRAMS',
      pointsPerKg: 25.0,
      minPayoutThreshold: 10.0,
      co2FactorPerKg: 8.0,
    ),
    MaterialType(
      id: 'demo-mat-tetrapak',
      name: 'Tetra Pak',
      category: 'TETRAPAK',
      unitOfMeasure: 'GRAMS',
      pointsPerKg: 12.0,
      minPayoutThreshold: 5.0,
      co2FactorPerKg: 1.2,
    ),
  ];

  late final List<RecyclingListing> listings = [
    RecyclingListing(
      id: 'demo-listing-1',
      status: 'PENDING',
      address: 'Av. San Martín 450, Barrio Equipetrol',
      latitude: -17.7810,
      longitude: -63.1790,
      isExactLocation: true,
      notes: 'Bolsas separadas en portería, tocar timbre 2.',
      citizen: RecyclingListingCitizen(
        id: 'u1',
        firstName: 'Ana',
        lastName: 'Gómez',
        phone: '70012345',
        trustScore: 4.8,
      ),
      materials: [
        RecyclingListingMaterial(
          materialId: 'demo-mat-pet',
          materialName: 'Plástico PET',
          category: 'PLASTIC',
          estimatedWeightGrams: 3000,
        ),
      ],
      availabilityWindows: [
        RecyclingAvailabilityWindow(dayOfWeek: DateTime.now().weekday % 7, startTime: '09:00:00', endTime: '13:00:00'),
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    RecyclingListing(
      id: 'demo-listing-2',
      status: 'PENDING',
      address: 'Calle Warnes 120, Barrio Las Palmas',
      latitude: -17.7860,
      longitude: -63.1850,
      isExactLocation: true,
      notes: 'Cartón compactado y amarrado.',
      citizen: RecyclingListingCitizen(
        id: 'u2',
        firstName: 'Carlos',
        lastName: 'Pérez',
        phone: '70054321',
        trustScore: 4.5,
      ),
      materials: [
        RecyclingListingMaterial(
          materialId: 'demo-mat-paper',
          materialName: 'Cartón y Papel',
          category: 'PAPER_CARDBOARD',
          estimatedWeightGrams: 5000,
        ),
      ],
      availabilityWindows: [
        RecyclingAvailabilityWindow(dayOfWeek: DateTime.now().weekday % 7, startTime: '15:00:00', endTime: '18:00:00'),
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 10)),
    ),
  ];

  final Map<String, RecyclingPickup> pickups = {};

  final List<Redemption> redemptions = [];

  late final List<PointsTransactionEntry> pointsHistory = [
    PointsTransactionEntry(
      id: 'demo-tx-1',
      delta: 50,
      reason: 'Bono de bienvenida a Vigilo',
      referenceType: 'WELCOME_BONUS',
      referenceId: 'welcome',
      balanceAfter: 50,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  late final List<AppNotification> notifications = [
    AppNotification(
      id: 'demo-notif-1',
      type: 'INCIDENT_VALIDATED',
      title: 'Alguien validó tu reporte',
      body: 'Tu reporte de "Zona Peligrosa cerca del 2do Anillo" recibió un nuevo voto.',
      data: const {},
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
  ];

  String newId(String prefix) => '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  /// Acredita puntos al usuario con sesión activa y deja constancia en el
  /// historial, igual que haría el ledger `points_transactions` real.
  void creditPoints({required int delta, required String reason, required String referenceType, required String referenceId}) {
    final user = currentUser;
    if (user == null) return;
    final newBalance = user.points + delta;
    currentUser = user.copyWith(points: newBalance);
    pointsHistory.insert(
      0,
      PointsTransactionEntry(
        id: newId('demo-tx'),
        delta: delta,
        reason: reason,
        referenceType: referenceType,
        referenceId: referenceId,
        balanceAfter: newBalance,
        createdAt: DateTime.now(),
      ),
    );
  }
}
