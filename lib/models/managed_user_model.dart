class ManagedUserModel {
  final int id;
  final String name;
  final String role;
  final bool isActive;

  const ManagedUserModel({
    required this.id,
    required this.name,
    required this.role,
    required this.isActive,
  });

  factory ManagedUserModel.fromJson(Map<String, dynamic> json) {
    return ManagedUserModel(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
