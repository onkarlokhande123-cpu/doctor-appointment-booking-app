import 'package:flutter_test/flutter_test.dart';

import 'package:appointment_booking_app/data/mock/mock_booking_store.dart';
import 'package:appointment_booking_app/data/repositories/mock_doctor_repository.dart';
import 'package:appointment_booking_app/presentation/home/cubit/home_cubit.dart';
import 'package:appointment_booking_app/presentation/home/cubit/home_state.dart';

void main() {
  test('search and filters update the displayed doctor results', () async {
    final cubit = HomeCubit(
      doctorRepository: MockDoctorRepository(bookingStore: MockBookingStore()),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(cubit.state.status, HomeStatus.success);
    expect(cubit.state.filteredDoctors, isNotEmpty);

    cubit.search('dermatologist');
    expect(cubit.state.filteredDoctors, hasLength(1));
    expect(cubit.state.filteredDoctors.single.specialtyId, 'dermatology');

    cubit.setMinimumRating(4.9);
    expect(cubit.state.filteredDoctors, isEmpty);

    cubit.setMinimumRating(null);
    cubit.search('');
    cubit.selectSpecialty('cardiology');
    cubit.setAvailableOnly(true);
    expect(cubit.state.filteredDoctors, hasLength(1));
    expect(cubit.state.filteredDoctors.single.id, 'dr-meera-shah');

    await cubit.close();
  });
}
