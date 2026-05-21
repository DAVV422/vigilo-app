class Company {
  final String id;
  final String name;
  final String? logoUrl;

  Company({
    required this.id,
    required this.name,
    this.logoUrl,
  });

  Company copyWith({
    String? id,
    String? name,
    String? logoUrl,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }
}
