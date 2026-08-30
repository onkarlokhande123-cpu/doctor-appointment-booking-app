sealed class BookingEvent {
  const BookingEvent();
}

class BookingStarted extends BookingEvent {
  const BookingStarted();
}

class BookingDateSelected extends BookingEvent {
  const BookingDateSelected(this.date);

  final DateTime date;
}

class BookingSlotSelected extends BookingEvent {
  const BookingSlotSelected(this.slotId);

  final String slotId;
}

class BookingPatientDetailsUpdated extends BookingEvent {
  const BookingPatientDetailsUpdated({
    this.name,
    this.email,
    this.phone,
    this.reason,
  });

  final String? name;
  final String? email;
  final String? phone;
  final String? reason;
}

class BookingContinueRequested extends BookingEvent {
  const BookingContinueRequested();
}

class BookingBackRequested extends BookingEvent {
  const BookingBackRequested();
}

class BookingConfirmationRequested extends BookingEvent {
  const BookingConfirmationRequested();
}
