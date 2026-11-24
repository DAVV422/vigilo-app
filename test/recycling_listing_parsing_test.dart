import 'package:flutter_test/flutter_test.dart';
import 'package:vigilo/domain/entities/recycling_listing.dart';

void main() {
  // Regresion: el backend devolvia citizen.trustScore como string (las columnas
  // NUMERIC de Postgres viajan asi por el driver pg) y el parseo lanzaba
  // 'String is not a subtype of num?'. Como pasaba DESPUES del 201, el registro
  // quedaba creado pero la app mostraba error y el usuario duplicaba la
  // publicacion al reintentar. Se corrigio en el backend con Number(...) y aca
  // tolerando ambos tipos.
  test('parsea trustScore venga como string (contrato historico)', () {
    // Copiado literal de la respuesta del servidor desplegado.
    final json = <String, dynamic>{
      'id': 'a617d211-de0e-4572-abea-18bf825bbad6',
      'status': 'PENDING',
      'address': 'Prueba parser',
      'latitude': -17.7833,
      'longitude': -63.1821,
      'isExactLocation': true,
      'notes': null,
      'photoMediaId': null,
      'citizen': {
        'id': '90606517-7fc6-43b8-af28-e9d69401c380',
        'firstName': 'Emu',
        'lastName': 'Test',
        'phone': '+59171234567',
        'trustScore': '5.00', // <-- el backend lo manda como STRING
      },
      'pickup': null,
      'materials': [
        {
          'materialId': '0b16ef6e-b146-4f91-b180-565bb6131a57',
          'materialName': 'Aluminio y Metales',
          'category': 'METAL',
          'estimatedWeightGrams': 5000,
        }
      ],
      'availabilityWindows': [
        {'dayOfWeek': 2, 'startTime': '08:00:00', 'endTime': '12:00:00'}
      ],
      'createdAt': '2026-11-24T17:15:34.439Z',
    };

    final listing = RecyclingListing.fromJson(json);
    expect(listing.id, 'a617d211-de0e-4572-abea-18bf825bbad6');
    expect(listing.citizen?.trustScore, 5.0);
    expect(listing.materials.single.estimatedWeightGrams, 5000);
  });

  test('parsea trustScore venga como numero (contrato corregido)', () {
    final listing = RecyclingListing.fromJson({
      'id': 'b1',
      'status': 'PENDING',
      'latitude': -17.7833,
      'longitude': -63.1821,
      'isExactLocation': true,
      'citizen': {'id': 'u1', 'trustScore': 4.25},
      'materials': <dynamic>[],
      'availabilityWindows': <dynamic>[],
      'createdAt': '2026-11-24T17:15:34.439Z',
    });
    expect(listing.citizen?.trustScore, 4.25);
  });
}
