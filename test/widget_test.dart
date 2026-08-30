import 'package:flutter_test/flutter_test.dart';

import 'package:appointment_booking_app/data/repositories/mock_auth_repository.dart';
import 'package:appointment_booking_app/main.dart';

void main() {
  testWidgets('unauthenticated app starts on the login screen', (
    WidgetTester tester,
  ) async {
    final authRepository = MockAuthRepository();
    await tester
        .pumpWidget(AppointmentBookingApp(authRepository: authRepository));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    authRepository.dispose();
  });
}
