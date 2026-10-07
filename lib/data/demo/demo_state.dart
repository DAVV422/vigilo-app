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
    RecyclingListing(
      id: 'demo-listing-5',
      status: 'PENDING',
      address: 'Barrio Urbarí, Av. Beni 230',
      latitude: -17.7750,
      longitude: -63.1700,
      isExactLocation: true,
      notes: 'Botellas de vidrio separadas por color.',
      citizen: RecyclingListingCitizen(
        id: 'u2',
        firstName: 'Carlos',
        lastName: 'Pérez',
        phone: '70054321',
        trustScore: 4.5,
      ),
      materials: [
        RecyclingListingMaterial(
          materialId: 'demo-mat-glass',
          materialName: 'Vidrio',
          category: 'GLASS',
          estimatedWeightGrams: 4000,
        ),
      ],
      availabilityWindows: [
        RecyclingAvailabilityWindow(dayOfWeek: DateTime.now().weekday % 7, startTime: '10:00:00', endTime: '14:00:00'),
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    // Las siguientes dos ya están COMPLETED (recojo confirmado) para que los
    // paneles de impacto/KPIs no arranquen en cero en la demo — ver también
    // `pickups` y `pointsHistory` más abajo, que reflejan el mismo recojo.
    RecyclingListing(
      id: 'demo-listing-3',
      status: 'COMPLETED',
      address: 'Av. San Martín 450, Barrio Equipetrol',
      latitude: -17.7810,
      longitude: -63.1790,
      isExactLocation: true,
      notes: 'Botellas PET limpias y compactadas.',
      citizen: RecyclingListingCitizen(
        id: 'u1',
        firstName: 'Ana',
        lastName: 'Gómez',
        phone: '70012345',
        trustScore: 4.8,
      ),
      pickupId: 'demo-pickup-1',
      pickupRecyclerId: 'u7',
      pickupStatus: 'COMPLETED',
      pickupCompensationStatus: 'CONFIRMED',
      materials: [
        RecyclingListingMaterial(
          materialId: 'demo-mat-pet',
          materialName: 'Plástico PET',
          category: 'PLASTIC',
          estimatedWeightGrams: 2500,
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    RecyclingListing(
      id: 'demo-listing-4',
      status: 'COMPLETED',
      address: 'Barrio Urbarí, Calle Los Lirios 88',
      latitude: -17.7735,
      longitude: -63.1680,
      isExactLocation: true,
      notes: 'Latas de aluminio y chatarra liviana.',
      citizen: RecyclingListingCitizen(
        id: 'u2',
        firstName: 'Carlos',
        lastName: 'Pérez',
        phone: '70054321',
        trustScore: 4.5,
      ),
      pickupId: 'demo-pickup-2',
      pickupRecyclerId: 'u6',
      pickupStatus: 'COMPLETED',
      pickupCompensationStatus: 'CONFIRMED',
      materials: [
        RecyclingListingMaterial(
          materialId: 'demo-mat-metal',
          materialName: 'Aluminio y Metales',
          category: 'METAL',
          estimatedWeightGrams: 1200,
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
  ];

  late final Map<String, RecyclingPickup> pickups = {
    'demo-pickup-1': RecyclingPickup(
      id: 'demo-pickup-1',
      status: 'COMPLETED',
      claimedAt: DateTime.now().subtract(const Duration(days: 4, hours: 3)),
      arrivedAt: DateTime.now().subtract(const Duration(days: 4, hours: 1)),
      completedAt: DateTime.now().subtract(const Duration(days: 4)),
      listingId: 'demo-listing-3',
      listingAddress: 'Av. San Martín 450, Barrio Equipetrol',
      citizenId: 'u1',
      citizenName: 'Ana Gómez',
      citizenPhone: '70012345',
      citizenTrustScore: 4.8,
      results: [
        RecyclingPickupResult(
          materialId: 'demo-mat-pet',
          materialName: 'Plástico PET',
          actualWeightGrams: 2500,
          pointsAwarded: 25,
        ),
      ],
      compensation: PickupCompensation(
        id: 'demo-compensation-1',
        paymentMethod: 'CASH',
        grossAmount: 3.0,
        status: 'CONFIRMED',
      ),
      listingMaterials: [
        RecyclingListingMaterial(
          materialId: 'demo-mat-pet',
          materialName: 'Plástico PET',
          category: 'PLASTIC',
          estimatedWeightGrams: 2500,
        ),
      ],
    ),
    'demo-pickup-2': RecyclingPickup(
      id: 'demo-pickup-2',
      status: 'COMPLETED',
      claimedAt: DateTime.now().subtract(const Duration(days: 6, hours: 3)),
      arrivedAt: DateTime.now().subtract(const Duration(days: 6, hours: 1)),
      completedAt: DateTime.now().subtract(const Duration(days: 6)),
      listingId: 'demo-listing-4',
      listingAddress: 'Barrio Urbarí, Calle Los Lirios 88',
      citizenId: 'u2',
      citizenName: 'Carlos Pérez',
      citizenPhone: '70054321',
      citizenTrustScore: 4.5,
      results: [
        RecyclingPickupResult(
          materialId: 'demo-mat-metal',
          materialName: 'Aluminio y Metales',
          actualWeightGrams: 1200,
          pointsAwarded: 30,
        ),
      ],
      compensation: PickupCompensation(
        id: 'demo-compensation-2',
        paymentMethod: 'CASH',
        grossAmount: 5.4,
        status: 'CONFIRMED',
      ),
      listingMaterials: [
        RecyclingListingMaterial(
          materialId: 'demo-mat-metal',
          materialName: 'Aluminio y Metales',
          category: 'METAL',
          estimatedWeightGrams: 1200,
        ),
      ],
    ),
  };

  late final List<Redemption> redemptions = [
    Redemption(
      id: 'demo-redemption-1',
      productId: 'p3',
      productName: 'Bolsa Reutilizable',
      productImageUrl: 'https://cdn-icons-png.flaticon.com/512/4293/4293035.png',
      pointsSpent: 30,
      code: 'ECO3K9',
      status: 'FULFILLED',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      fulfilledAt: DateTime.now().subtract(const Duration(hours: 20)),
    ),
  ];

  /// Historial de la cuenta demo principal (Ana, u1 — ver el acceso rápido
  /// en la pantalla de login). Coincide con su saldo semilla (45 pts en
  /// `LocalJsonDatasource`): +50 bono, +25 por el recojo PET de arriba,
  /// -30 por el canje de la bolsa reutilizable.
  late final List<PointsTransactionEntry> pointsHistory = [
    PointsTransactionEntry(
      id: 'demo-tx-3',
      delta: -30,
      reason: 'Canje: Bolsa Reutilizable',
      referenceType: 'STORE_REDEMPTION',
      referenceId: 'p3',
      balanceAfter: 45,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    PointsTransactionEntry(
      id: 'demo-tx-2',
      delta: 25,
      reason: 'Recojo de reciclaje confirmado',
      referenceType: 'RECYCLING_PICKUP',
      referenceId: 'demo-pickup-1',
      balanceAfter: 75,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    PointsTransactionEntry(
      id: 'demo-tx-1',
      delta: 50,
      reason: 'Bono de bienvenida a Vigilo',
      referenceType: 'WELCOME_BONUS',
      referenceId: 'welcome',
      balanceAfter: 50,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
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
