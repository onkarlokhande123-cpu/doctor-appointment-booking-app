import 'package:flutter/foundation.dart';

import 'package:appointment_booking_app/core/constants/enums.dart';
import 'package:appointment_booking_app/data/models/user_model.dart';

/// Temporary, minimal "is a user logged in" holder used only to drive
/// `go_router`'s redirect logic in this step.
///
/// This is intentionally NOT a real auth implementation — no credentials,
/// no persistence, no repository calls. In a later step this will be
/// replaced by an `AuthCubit`/`AuthBloc` that listens to
/// `AuthRepository.authStateChanges()` (mock now, Firebase later) and
/// updates a value here — the router itself will not need to change.
///
/// `go_router`'s `redirect` callback only re-runs on navigation events by
/// default; passing this as `refreshListenable` makes it re-run
/// immediately whenever [isLoggedIn] changes too (e.g. right after a
/// future login/logout action).
class AuthStateListenable extends ChangeNotifier {
  AuthStateListenable({bool isLoggedIn = false}) : _isLoggedIn = isLoggedIn;

  bool _isLoggedIn;
  bool get isLoggedIn => _isLoggedIn;
  UserRole _role = UserRole.patient;
  UserRole get role => _role;
  String? _doctorId;
  String? get doctorId => _doctorId;
  bool get isDoctor => _role == UserRole.doctor && _doctorId != null;

  void setLoggedIn(bool value) {
    if (_isLoggedIn == value) return;
    _isLoggedIn = value;
    notifyListeners();
  }

  void setUser(UserModel? user) {
    final isLoggedIn = user != null;
    final role = user?.role ?? UserRole.patient;
    final doctorId = user?.doctorId;
    if (_isLoggedIn == isLoggedIn && _role == role && _doctorId == doctorId) {
      return;
    }
    _isLoggedIn = isLoggedIn;
    _role = role;
    _doctorId = doctorId;
    notifyListeners();
  }
}
