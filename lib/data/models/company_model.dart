import '../../domain/entities/company.dart';

class CompanyModel extends Company {
  CompanyModel({
    required super.id,
    required super.name,
    super.logoUrl,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'],
      name: json['name'],
      logoUrl: json['logoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
    };
  }

  factory CompanyModel.fromEntity(Company entity) {
    return CompanyModel(
      id: entity.id,
      name: entity.name,
      logoUrl: entity.logoUrl,
    );
  }
}
