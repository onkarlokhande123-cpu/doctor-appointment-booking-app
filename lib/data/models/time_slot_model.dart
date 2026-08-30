/// Represents a single bookable time slot for a doctor on a specific date.
///
/// Times are stored as display strings (e.g. "10:00 AM") rather than
/// Flutter's `TimeOfDay` on purpose — the data layer stays pure Dart with
/// no Flutter framework dependency, and the strings serialize to/from
/// JSON/Firestore without extra conversion helpers.
class TimeSlotModel {
  static const Object _unset = Object();

  final String id;
  final String doctorId;

  /// Date this slot belongs to (time-of-day component should be ignored;
  /// only year/month/day are meaningful).
  final DateTime date;

  final String startTime;
  final String endTime;
  final bool isBooked;

  /// Set when [isBooked] is true. Used to enforce that users only manage
  /// their own bookings.
  final String? bookedByUserId;

  const TimeSlotModel({
    required this.id,
    required this.doctorId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.isBooked = false,
    this.bookedByUserId,
  });

  TimeSlotModel copyWith({
    bool? isBooked,
    Object? bookedByUserId = _unset,
  }) {
    return TimeSlotModel(
      id: id,
      doctorId: doctorId,
      date: date,
      startTime: startTime,
      endTime: endTime,
      isBooked: isBooked ?? this.isBooked,
      bookedByUserId: identical(bookedByUserId, _unset)
          ? this.bookedByUserId
          : bookedByUserId as String?,
    );
  }

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      id: json['id'] as String? ?? '',
      doctorId: json['doctorId'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      isBooked: json['isBooked'] as bool? ?? false,
      bookedByUserId: json['bookedByUserId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorId': doctorId,
      'date': date.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'isBooked': isBooked,
      'bookedByUserId': bookedByUserId,
    };
  }
}
