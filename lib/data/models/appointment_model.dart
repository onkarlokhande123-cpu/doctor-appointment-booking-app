import 'package:appointment_booking_app/core/constants/enums.dart';

/// Represents a confirmed (or cancelled/completed) appointment booking.
///
/// [timeSlotId]/[startTime]/[endTime] and [doctorName]/[doctorImageUrl] are
/// denormalized onto the appointment at booking time. This keeps a booking's
/// record stable and historically accurate (e.g. appointment history still
/// shows correctly even if the doctor's profile changes later) and avoids
/// extra lookups when rendering appointment lists.
class AppointmentModel {
  /// Unique, human-shareable booking reference (business rule: every
  /// booking must have a unique booking ID). This is null while the model is
  /// a booking request; [AppointmentRepository.createAppointment] assigns it
  /// before returning the confirmed appointment.
  final String? bookingId;

  final String userId;

  final String doctorId;
  final String doctorName;
  final String? doctorImageUrl;

  /// Appointment date (year/month/day is what matters here).
  final DateTime date;

  final String timeSlotId;
  final String startTime;
  final String endTime;

  // Patient details captured on the booking form.
  final String patientName;
  final String patientEmail;
  final int patientAge;
  final Gender patientGender;
  final String patientPhone;

  final String reason;
  final double fee;
  final AppointmentStatus status;
  final DateTime createdAt;

  const AppointmentModel({
    this.bookingId,
    required this.userId,
    required this.doctorId,
    required this.doctorName,
    this.doctorImageUrl,
    required this.date,
    required this.timeSlotId,
    required this.startTime,
    required this.endTime,
    required this.patientName,
    required this.patientEmail,
    required this.patientAge,
    required this.patientGender,
    required this.patientPhone,
    required this.reason,
    required this.fee,
    required this.status,
    required this.createdAt,
  });

  AppointmentModel copyWith({
    AppointmentStatus? status,
  }) {
    return AppointmentModel(
      bookingId: bookingId,
      userId: userId,
      doctorId: doctorId,
      doctorName: doctorName,
      doctorImageUrl: doctorImageUrl,
      date: date,
      timeSlotId: timeSlotId,
      startTime: startTime,
      endTime: endTime,
      patientName: patientName,
      patientEmail: patientEmail,
      patientAge: patientAge,
      patientGender: patientGender,
      patientPhone: patientPhone,
      reason: reason,
      fee: fee,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      bookingId: json['bookingId'] as String?,
      userId: json['userId'] as String? ?? '',
      doctorId: json['doctorId'] as String? ?? '',
      doctorName: json['doctorName'] as String? ?? '',
      doctorImageUrl: json['doctorImageUrl'] as String?,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      timeSlotId: json['timeSlotId'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      patientName: json['patientName'] as String? ?? '',
      patientEmail: json['patientEmail'] as String? ?? '',
      patientAge: (json['patientAge'] as num?)?.toInt() ?? 0,
      patientGender: Gender.fromString(json['patientGender'] as String?),
      patientPhone: json['patientPhone'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      fee: (json['fee'] as num?)?.toDouble() ?? 0.0,
      status: AppointmentStatus.fromString(json['status'] as String?),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'userId': userId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorImageUrl': doctorImageUrl,
      'date': date.toIso8601String(),
      'timeSlotId': timeSlotId,
      'startTime': startTime,
      'endTime': endTime,
      'patientName': patientName,
      'patientEmail': patientEmail,
      'patientAge': patientAge,
      'patientGender': patientGender.name,
      'patientPhone': patientPhone,
      'reason': reason,
      'fee': fee,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
