import '../../domain/entities/incident.dart';
import '../../domain/repositories/incident_repository.dart';
import '../datasources/local_json_datasource.dart';
import '../models/incident_model.dart';
import '../models/user_model.dart';
import '../models/company_model.dart';

class IncidentRepositoryImpl implements IncidentRepository {
  final LocalJsonDatasource datasource;

  IncidentRepositoryImpl(this.datasource);

  @override
  Future<List<Incident>> getIncidents() async {
    final data = await datasource.readData();
    final incidentsJson = data['incidents'] as List<dynamic>;
    return incidentsJson.map<Incident>((i) => IncidentModel.fromJson(i)).toList();
  }

  @override
  Future<void> addIncident(Incident incident) async {
    final data = await datasource.readData();
    
    final usersJson = data['users'] as List<dynamic>;
    final incidentsJson = data['incidents'] as List<dynamic>;
    final companiesJson = data['companies'] as List<dynamic>;
    
    final users = usersJson.map((u) => UserModel.fromJson(u)).toList();
    final incidents = incidentsJson.map((i) => IncidentModel.fromJson(i)).toList();
    final companies = companiesJson.map((c) => CompanyModel.fromJson(c as Map<String, dynamic>)).toList();

    incidents.add(IncidentModel.fromEntity(incident));
    
    await datasource.writeData(users, incidents, companies);
  }

  @override
  Future<void> validateIncident(String incidentId, String userId) async {
    final data = await datasource.readData();
    
    final usersJson = data['users'] as List<dynamic>;
    final incidentsJson = data['incidents'] as List<dynamic>;
    final companiesJson = data['companies'] as List<dynamic>;
    
    final users = usersJson.map((u) => UserModel.fromJson(u)).toList();
    final incidents = incidentsJson.map((i) => IncidentModel.fromJson(i)).toList();
    final companies = companiesJson.map((c) => CompanyModel.fromJson(c as Map<String, dynamic>)).toList();

    final index = incidents.indexWhere((i) => i.id == incidentId);
    if (index != -1) {
      if (!incidents[index].validatorsIds.contains(userId)) {
        incidents[index].validatorsIds.add(userId);
        await datasource.writeData(users, incidents, companies);
      }
    }
  }

  @override
  Future<void> resolveIncident({
    required String incidentId,
    required String userId,
    required String companyId,
    required String companyName,
    required String comment,
  }) async {
    final data = await datasource.readData();
    
    final usersJson = data['users'] as List<dynamic>;
    final incidentsJson = data['incidents'] as List<dynamic>;
    final companiesJson = data['companies'] as List<dynamic>;
    
    final users = usersJson.map((u) => UserModel.fromJson(u)).toList();
    final incidents = incidentsJson.map((i) => IncidentModel.fromJson(i)).toList();
    final companies = companiesJson.map((c) => CompanyModel.fromJson(c as Map<String, dynamic>)).toList();

    final companyNameResolved = companies.firstWhere(
      (c) => c.id == companyId,
      orElse: () => CompanyModel(id: '', name: companyName),
    ).name;

    final index = incidents.indexWhere((i) => i.id == incidentId);
    if (index != -1) {
      incidents[index] = IncidentModel(
        id: incidents[index].id,
        title: incidents[index].title,
        description: incidents[index].description,
        location: incidents[index].location,
        type: incidents[index].type,
        reportedAt: incidents[index].reportedAt,
        reportedByUserId: incidents[index].reportedByUserId,
        validatorsIds: incidents[index].validatorsIds,
        imageUrl: incidents[index].imageUrl,
        status: IncidentStatus.resolved,
        resolvedByUserId: userId,
        resolvedByCompany: companyNameResolved,
        resolvedAt: DateTime.now(),
        resolutionComment: comment,
      );
      await datasource.writeData(users, incidents, companies);
    }
  }
}
