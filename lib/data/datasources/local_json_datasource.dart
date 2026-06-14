import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:latlong2/latlong.dart';
import '../models/user_model.dart';
import '../models/incident_model.dart';
import '../models/company_model.dart';
import '../models/store_product_model.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/incident.dart';

class LocalJsonDatasource {
  final String fileName = 'vigilo_data_v5.json';

  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$fileName');
  }

  Future<Map<String, dynamic>> readData() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        await _seedData();
      }
      final contents = await file.readAsString();
      final data = json.decode(contents) as Map<String, dynamic>;
      if (data['products'] == null) {
        data['products'] = _defaultProducts().map((p) => p.toJson()).toList();
        await file.writeAsString(json.encode(data));
      }
      return data;
    } catch (e) {
      await _seedData();
      final file = await _localFile;
      final contents = await file.readAsString();
      return json.decode(contents);
    }
  }

  Future<void> writeData(
    List<UserModel> users,
    List<IncidentModel> incidents,
    List<CompanyModel> companies, {
    List<StoreProductModel>? products,
  }) async {
    final file = await _localFile;
    final data = {
      'users': users.map((u) => u.toJson()).toList(),
      'incidents': incidents.map((i) => i.toJson()).toList(),
      'companies': companies.map((c) => c.toJson()).toList(),
      if (products != null)
        'products': products.map((p) => p.toJson()).toList(),
    };
    await file.writeAsString(json.encode(data));
  }

  Future<void> updateCompany(CompanyModel company) async {
    final data = await readData();
    final usersJson = data['users'] as List<dynamic>;
    final incidentsJson = data['incidents'] as List<dynamic>;
    final companiesJson = data['companies'] as List<dynamic>;

    final users = usersJson.map((u) => UserModel.fromJson(u)).toList();
    final incidents = incidentsJson
        .map((i) => IncidentModel.fromJson(i))
        .toList();
    final companies = companiesJson
        .map((c) => CompanyModel.fromJson(c as Map<String, dynamic>))
        .toList();

    final index = companies.indexWhere((c) => c.id == company.id);
    if (index != -1) {
      companies[index] = company;
      await writeData(users, incidents, companies);
    }
  }

  Future<void> _seedData() async {
    // ===================== EMPRESAS =====================
    final companies = [
      CompanyModel(
        id: 'c1',
        name: 'Seguridad Total SCZ',
        logoUrl: 'https://cdn-icons-png.flaticon.com/512/2921/2921222.png',
      ),
      CompanyModel(
        id: 'c2',
        name: 'EcoLimpia Bolivia',
        logoUrl: 'https://cdn-icons-png.flaticon.com/512/2936/2936690.png',
      ),
    ];

    // ===================== USUARIOS =====================
    final users = [
      // --- Ciudadanos normales ---
      UserModel(
        id: 'u1',
        name: 'Ana',
        lastName: 'Gómez',
        username: '@ana_g',
        phone: '70012345',
        email: 'ana@gmail.com',
        password: '12345678',
        avatarUrl: 'A',
        points: 120,
        roles: [UserRole.normal],
      ),
      UserModel(
        id: 'u2',
        name: 'Carlos',
        lastName: 'Pérez',
        username: '@carlosp',
        phone: '70054321',
        email: 'carlos@gmail.com',
        password: '12345678',
        avatarUrl: 'C',
        points: 45,
        roles: [UserRole.normal],
      ),

      // --- Empresa 1: Seguridad Total SCZ ---
      UserModel(
        id: 'u3',
        name: 'Roberto',
        lastName: 'Méndez',
        username: '@roberto_m',
        phone: '76601001',
        email: 'roberto@seguridadtotal.com',
        password: '12345678',
        avatarUrl: 'R',
        points: 510,
        roles: [UserRole.security],
        companyId: 'c1',
        companyRole: CompanyRole.director,
      ),
      UserModel(
        id: 'u4',
        name: 'Luis',
        lastName: 'Salazar',
        username: '@luis_s',
        phone: '76601002',
        email: 'luis@seguridadtotal.com',
        password: '12345678',
        avatarUrl: 'L',
        points: 230,
        roles: [UserRole.security],
        companyId: 'c1',
        companyRole: CompanyRole.employee,
      ),
      UserModel(
        id: 'u5',
        name: 'María',
        lastName: 'Torres',
        username: '@maria_t',
        phone: '76601003',
        email: 'maria@seguridadtotal.com',
        password: '12345678',
        avatarUrl: 'M',
        points: 180,
        roles: [UserRole.security],
        companyId: 'c1',
        companyRole: CompanyRole.employee,
      ),

      // --- Empresa 2: EcoLimpia Bolivia ---
      UserModel(
        id: 'u6',
        name: 'Patricia',
        lastName: 'Vargas',
        username: '@patri_v',
        phone: '76702001',
        email: 'patricia@ecolimpia.com',
        password: '12345678',
        avatarUrl: 'P',
        points: 600,
        roles: [UserRole.cleaning, UserRole.recycling],
        companyId: 'c2',
        companyRole: CompanyRole.director,
      ),
      UserModel(
        id: 'u7',
        name: 'Diego',
        lastName: 'Rojas',
        username: '@diego_r',
        phone: '76702002',
        email: 'diego@ecolimpia.com',
        password: '12345678',
        avatarUrl: 'D',
        points: 320,
        roles: [UserRole.cleaning, UserRole.recycling],
        companyId: 'c2',
        companyRole: CompanyRole.manager,
      ),
      UserModel(
        id: 'u8',
        name: 'Sandra',
        lastName: 'Flores',
        username: '@sandra_f',
        phone: '76702003',
        email: 'sandra@ecolimpia.com',
        password: '12345678',
        avatarUrl: 'S',
        points: 95,
        roles: [UserRole.cleaning],
        companyId: 'c2',
        companyRole: CompanyRole.employee,
      ),
      UserModel(
        id: 'u9',
        name: 'Jorge',
        lastName: 'Mamani',
        username: '@jorge_m',
        phone: '76702004',
        email: 'jorge@ecolimpia.com',
        password: '12345678',
        avatarUrl: 'J',
        points: 70,
        roles: [UserRole.cleaning],
        companyId: 'c2',
        companyRole: CompanyRole.employee,
      ),
    ];

    // ===================== INCIDENTES SEMILLA =====================
    final now = DateTime.now();
    final incidents = [
      // --- INCIDENTES ACTIVOS ---
      IncidentModel(
        id: '1',
        title: 'Zona Peligrosa cerca del 2do Anillo',
        description:
            'Se han reportado asaltos a peatones en horas de la noche.',
        location: const LatLng(-17.783327, -63.182141),
        type: IncidentType.insecurity,
        reportedAt: now.subtract(const Duration(hours: 3)),
        reportedByUserId: 'u1',
        validatorsIds: ['u2'],
        status: IncidentStatus.active,
      ),
      IncidentModel(
        id: '3',
        title: 'Maleza crecida en terreno baldío',
        description:
            'Hierba alta que cubre la vereda, dificulta el paso de los transeúntes.',
        location: const LatLng(-17.785200, -63.178500),
        type: IncidentType.weeds,
        reportedAt: now.subtract(const Duration(hours: 12)),
        reportedByUserId: 'u1',
        validatorsIds: [],
        status: IncidentStatus.active,
      ),
      IncidentModel(
        id: '4',
        title: 'Botellas plásticas disponibles',
        description:
            'Aproximadamente 15 kg de botellas PET limpias listas para recoger.',
        location: const LatLng(-17.780500, -63.183200),
        type: IncidentType.recycling,
        reportedAt: now.subtract(const Duration(hours: 6)),
        reportedByUserId: 'u2',
        validatorsIds: ['u1'],
        status: IncidentStatus.active,
      ),
      IncidentModel(
        id: '5',
        title: 'Basura desbordada en contenedor',
        description: 'Bolsas acumuladas fuera del depósito, atrae plagas.',
        location: const LatLng(-17.784100, -63.185500),
        type: IncidentType.trash,
        reportedAt: now.subtract(const Duration(hours: 24)),
        reportedByUserId: 'u2',
        validatorsIds: [],
        status: IncidentStatus.active,
      ),

      // --- INCIDENTES RESUELTOS (Para Estadísticas de Tiempo Promedio) ---
      // 1. Inseguridad resuelta en 45 minutos (0.75 horas)
      IncidentModel(
        id: 'res_insecurity_1',
        title: 'Presencia sospechosa en rotonda',
        description:
            'Dos sujetos merodeando negocios locales con actitud sospechosa.',
        location: const LatLng(-17.782500, -63.181200),
        type: IncidentType.insecurity,
        reportedAt: now.subtract(const Duration(days: 3, hours: 2)),
        reportedByUserId: 'u1',
        validatorsIds: ['u2'],
        status: IncidentStatus.resolved,
        resolvedByUserId: 'u4',
        resolvedByCompany: 'Seguridad Total SCZ',
        resolvedAt: now.subtract(
          const Duration(days: 3, hours: 1, minutes: 15),
        ),
        resolutionComment:
            'Patrullaje preventivo despachado al lugar. Zona despejada y segura.',
      ),
      // 2. Basura resuelta en 30 horas (1.25 días)
      IncidentModel(
        id: '2',
        title: 'Basura acumulada en Av. Cañoto',
        description: 'Contenedor desbordado frente al mercado público.',
        location: const LatLng(-17.781000, -63.180000),
        type: IncidentType.trash,
        reportedAt: now.subtract(const Duration(days: 5)),
        reportedByUserId: 'u2',
        validatorsIds: ['u1'],
        status: IncidentStatus.resolved,
        resolvedByUserId: 'u8',
        resolvedByCompany: 'EcoLimpia Bolivia',
        resolvedAt: now.subtract(const Duration(days: 3, hours: 18)),
        resolutionComment:
            'Se realizó limpieza completa del área y vaciado del contenedor.',
      ),
      // 3. Basura resuelta en 18 horas (0.75 días)
      IncidentModel(
        id: 'res_trash_2',
        title: 'Microbasural en acera',
        description: 'Restos de escombros y plásticos acumulados ilegalmente.',
        location: const LatLng(-17.779500, -63.184000),
        type: IncidentType.trash,
        reportedAt: now.subtract(const Duration(days: 6)),
        reportedByUserId: 'u1',
        validatorsIds: [],
        status: IncidentStatus.resolved,
        resolvedByUserId: 'u9',
        resolvedByCompany: 'EcoLimpia Bolivia',
        resolvedAt: now.subtract(const Duration(days: 5, hours: 6)),
        resolutionComment:
            'Equipo especial de limpieza recogió los residuos con camión.',
      ),
      // 4. Maleza resuelta en 48 horas (2 días)
      IncidentModel(
        id: 'res_weeds_1',
        title: 'Maleza obstruye paso peatonal',
        description:
            'Hierba silvestre ha crecido demasiado invadiendo la ciclovía.',
        location: const LatLng(-17.786000, -63.181800),
        type: IncidentType.weeds,
        reportedAt: now.subtract(const Duration(days: 8)),
        reportedByUserId: 'u2',
        validatorsIds: ['u1'],
        status: IncidentStatus.resolved,
        resolvedByUserId: 'u8',
        resolvedByCompany: 'EcoLimpia Bolivia',
        resolvedAt: now.subtract(const Duration(days: 6)),
        resolutionComment:
            'Desmalezado completo realizado por la cuadrilla de limpieza.',
      ),
      // 5. Reciclaje recogido en 3 horas
      IncidentModel(
        id: 'res_recycling_1',
        title: 'Cartón compactado listo',
        description:
            'Aproximadamente 40 kg de cartón seco atado para reciclaje.',
        location: const LatLng(-17.782000, -63.184500),
        type: IncidentType.recycling,
        reportedAt: now.subtract(const Duration(days: 1, hours: 5)),
        reportedByUserId: 'u1',
        validatorsIds: [],
        status: IncidentStatus.resolved,
        resolvedByUserId: 'u7',
        resolvedByCompany: 'EcoLimpia Bolivia',
        resolvedAt: now.subtract(const Duration(days: 1, hours: 2)),
        resolutionComment:
            'Recolector asignado pasó a retirar el material de reciclaje.',
      ),
    ];

    // ===================== PRODUCTOS TIENDA =====================
    final products = _defaultProducts();

    await writeData(users, incidents, companies, products: products);
  }

  List<StoreProductModel> _defaultProducts() {
    return [
      StoreProductModel(
        id: 'p1',
        name: 'Bicicleta',
        description: 'Bicicleta eléctrica de alta gama con batería de litio.',
        imageUrl: 'https://cdn-icons-png.flaticon.com/512/3097/3097174.png',
        pointsCost: 5000,
        stock: 20,
      ),
      StoreProductModel(
        id: 'p2',
        name: 'Alimento para Mascotas',
        description: 'Alimento nutritivo para perros y gatos. 1Kg.',
        imageUrl: 'https://cdn-icons-png.flaticon.com/512/3047/3047928.png',
        pointsCost: 50,
        stock: 15,
      ),
      StoreProductModel(
        id: 'p3',
        name: 'Bolsa Reutilizable',
        description: 'Bolsa plegable ecológica para tus compras.',
        imageUrl: 'https://cdn-icons-png.flaticon.com/512/4293/4293035.png',
        pointsCost: 30,
        stock: 30,
      ),
      StoreProductModel(
        id: 'p4',
        name: 'Llavero Reciclado',
        description: 'Llavero artesanal hecho de plástico reciclado.',
        imageUrl:
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSjndazppm_Z0GLpr_K-frkPe-teZSro5dhbw&s',
        pointsCost: 20,
        stock: 50,
      ),
      StoreProductModel(
        id: 'p5',
        name: 'Silla de plástico reciclado',
        description: 'Silla ergonómica hecha de plástico reciclado.',
        imageUrl: 'https://cdn-icons-png.flaticon.com/512/2948/2948107.png',
        pointsCost: 150,
        stock: 10,
      ),
      StoreProductModel(
        id: 'p6',
        name: 'Vale de descuento en gasolinera',
        description:
            'Vale de descuento de 20% en combustible en estaciones asociadas.',
        imageUrl: 'https://cdn-icons-png.flaticon.com/512/4607/4607370.png',
        pointsCost: 200,
        stock: 8,
      ),
      StoreProductModel(
        id: 'p7',
        name: 'Vale de descuento en supermercado',
        description: 'Vale de descuento de 15% en productos seleccionados.',
        imageUrl: 'https://cdn-icons-png.flaticon.com/512/3144/3144456.png',
        pointsCost: 120,
        stock: 12,
      ),
      StoreProductModel(
        id: 'p8',
        name: 'Kit de producto de limpieza del hogar',
        description: 'Set de productos de limpieza ecológicos para el hogar.',
        imageUrl: 'https://cdn-icons-png.flaticon.com/512/4148/4148461.png',
        pointsCost: 300,
        stock: 5,
      ),
    ];
  }
}
