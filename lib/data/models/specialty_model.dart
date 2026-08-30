/// Represents a medical specialty/category (e.g. Cardiologist, Dentist).
///
/// Used for search filtering and to group doctors on the home screen.
class SpecialtyModel {
  final String id;
  final String name;
  final String? iconName;

  const SpecialtyModel({
    required this.id,
    required this.name,
    this.iconName,
  });

  factory SpecialtyModel.fromJson(Map<String, dynamic> json) {
    return SpecialtyModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      iconName: json['iconName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
    };
  }
}
