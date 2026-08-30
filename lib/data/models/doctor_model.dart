/// Represents a doctor that can be browsed, searched, and booked.
///
/// [specialtyName] is stored alongside [specialtyId] as a denormalized
/// field — a deliberate, common Firestore pattern that lets list/search
/// screens display the specialty without a second lookup. When we swap in
/// the Firebase repository later, this shape stays the same.
class DoctorModel {
  final String id;
  final String name;
  final String specialtyId;
  final String specialtyName;
  final String? imageUrl;
  final double rating;
  final int experienceYears;
  final String bio;
  final double consultationFee;
  final String clinicAddress;

  /// Weekday names the doctor is available on, e.g. ['Monday', 'Wednesday'].
  /// Used to decide which dates to enable on the date picker.
  final List<String> availableDays;

  const DoctorModel({
    required this.id,
    required this.name,
    required this.specialtyId,
    required this.specialtyName,
    this.imageUrl,
    required this.rating,
    required this.experienceYears,
    required this.bio,
    required this.consultationFee,
    required this.clinicAddress,
    required this.availableDays,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      specialtyId: json['specialtyId'] as String? ?? '',
      specialtyName: json['specialtyName'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      experienceYears: (json['experienceYears'] as num?)?.toInt() ?? 0,
      bio: json['bio'] as String? ?? '',
      consultationFee: (json['consultationFee'] as num?)?.toDouble() ?? 0.0,
      clinicAddress: json['clinicAddress'] as String? ?? '',
      availableDays: (json['availableDays'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialtyId': specialtyId,
      'specialtyName': specialtyName,
      'imageUrl': imageUrl,
      'rating': rating,
      'experienceYears': experienceYears,
      'bio': bio,
      'consultationFee': consultationFee,
      'clinicAddress': clinicAddress,
      'availableDays': availableDays,
    };
  }
}
