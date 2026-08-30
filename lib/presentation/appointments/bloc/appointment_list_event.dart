sealed class AppointmentListEvent {
  const AppointmentListEvent();
}

class AppointmentListStarted extends AppointmentListEvent {
  const AppointmentListStarted();
}

class AppointmentListRefreshRequested extends AppointmentListEvent {
  const AppointmentListRefreshRequested();
}

class AppointmentCancellationRequested extends AppointmentListEvent {
  const AppointmentCancellationRequested(this.bookingId);

  final String bookingId;
}
