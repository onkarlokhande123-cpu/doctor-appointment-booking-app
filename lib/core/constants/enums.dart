/// Shared enums used across data models.
///
/// Keeping these in one place (instead of raw strings scattered across the
/// app) avoids typos and makes status checks type-safe everywhere —
/// required by business rule: "Appointment status must be clearly displayed".

/// Lifecycle status of an appointment.
enum AppointmentStatus {
  upcoming,
  completed,
  cancelled;

  /// Safely parses a status string coming from JSON/Firestore.
  /// Falls back to [AppointmentStatus.upcoming] on unknown/invalid input
  /// instead of throwing — invalid input must never crash the app.
  static AppointmentStatus fromString(String? value) {
    return AppointmentStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => AppointmentStatus.upcoming,
    );
  }
}

/// Access level assigned by trusted account provisioning.
///
/// Patient registration always creates [patient]. Doctor accounts are created
/// separately and link to an existing doctor catalogue document.
enum UserRole {
  patient,
  doctor;

  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.patient,
    );
  }
}

/// Category of a notification, used to pick an icon/action in the UI.
enum NotificationType {
  bookingConfirmed,
  reminder,
  cancelled,
  general;

  static NotificationType fromString(String? value) {
    return NotificationType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => NotificationType.general,
    );
  }
}

/// Patient gender, captured during booking.
enum Gender {
  male,
  female,
  other;

  static Gender fromString(String? value) {
    return Gender.values.firstWhere(
      (gender) => gender.name == value,
      orElse: () => Gender.other,
    );
  }
}
