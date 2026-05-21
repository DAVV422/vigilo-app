import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:latlong2/latlong.dart';
import '../models/user_model.dart';
import '../models/incident_model.dart';
import '../models/company_model.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/incident.dart';

class LocalJsonDatasource {
  final String fileName = 'vigilo_data_v3.json';

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
      return json.decode(contents);
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
    List<CompanyModel> companies,
  ) async {
    final file = await _localFile;
    final data = {
      'users': users.map((u) => u.toJson()).toList(),
      'incidents': incidents.map((i) => i.toJson()).toList(),
      'companies': companies.map((c) => c.toJson()).toList(),
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
    final incidents = [
      IncidentModel(
        id: '1',
        title: 'Zona Peligrosa cerca del 2do Anillo',
        description:
            'Se han reportado asaltos a peatones en horas de la noche.',
        location: const LatLng(-17.783327, -63.182141),
        type: IncidentType.insecurity,
        reportedAt: DateTime.now().subtract(const Duration(hours: 3)),
        reportedByUserId: 'u1',
        validatorsIds: ['u2'],
        status: IncidentStatus.active,
      ),
      IncidentModel(
        id: '2',
        title: 'Basura acumulada en Av. Cañoto',
        description: 'Contenedor desbordado frente al mercado.',
        location: const LatLng(-17.781000, -63.180000),
        type: IncidentType.trash,
        reportedAt: DateTime.now().subtract(const Duration(days: 2)),
        reportedByUserId: 'u2',
        validatorsIds: ['u1'],
        status: IncidentStatus.resolved,
        resolvedByUserId: 'u8',
        resolvedByCompany: 'EcoLimpia Bolivia',
        resolvedAt: DateTime.now().subtract(const Duration(days: 1)),
        resolutionComment: 'Se realizó limpieza completa del área.',
      ),
      IncidentModel(
        id: '3',
        title: 'Maleza crecida en terreno baldío',
        description: 'Hierba alta que cubre la vereda, dificulta el paso.',
        location: const LatLng(-17.785200, -63.178500),
        type: IncidentType.weeds,
        reportedAt: DateTime.now().subtract(const Duration(hours: 12)),
        reportedByUserId: 'u1',
        validatorsIds: [],
        status: IncidentStatus.active,
      ),
      IncidentModel(
        id: '4',
        title: 'Botellas plásticas disponibles',
        description:
            'Aproximadamente 15 kg de PET limpios listos para recoger.',
        location: const LatLng(-17.780500, -63.183200),
        type: IncidentType.recycling,
        reportedAt: DateTime.now().subtract(const Duration(hours: 6)),
        reportedByUserId: 'u2',
        validatorsIds: ['u1'],
        status: IncidentStatus.active,
      ),
    ];

    await writeData(users, incidents, companies);
  }
}
