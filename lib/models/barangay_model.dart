// lib/models/barangay_model.dart

class BarangayModel {
  final String id;  // UUID from Supabase
  final String name;
  final String? code;

  BarangayModel({
    required this.id,
    required this.name,
    this.code,
  });

  factory BarangayModel.fromJson(Map<String, dynamic> json) {
    return BarangayModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      code: json['code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
    };
  }

  @override
  String toString() => name;
}
