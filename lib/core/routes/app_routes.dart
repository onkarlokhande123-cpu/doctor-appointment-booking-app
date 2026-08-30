/// Centralized route *path* constants. Screens must never hardcode a path
/// string — always reference these constants so a path can be changed in
/// exactly one place.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';

  /// Path pattern with a required `doctorId` path parameter.
  static const String doctorDetails = '/doctor/:doctorId';
  static const String booking = '/booking/:doctorId';
  static const String appointments = '/appointments';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String doctorDashboard = '/doctor-dashboard';
  static const String doctorAppointments = '/doctor-appointments';

  /// Builds a concrete `/doctor/<id>` path for navigation calls, e.g.
  /// `context.go(AppRoutes.doctorDetailsPath(doctor.id))`.
  static String doctorDetailsPath(String doctorId) => '/doctor/$doctorId';

  /// Builds a concrete booking path for the selected doctor.
  static String bookingPath(String doctorId) => '/booking/$doctorId';
}

/// Centralized route *names*, for use with `context.goNamed(...)`, which
/// is safer than building path strings by hand once path parameters are
/// involved.
class AppRouteNames {
  AppRouteNames._();

  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgotPassword';
  static const String home = 'home';
  static const String doctorDetails = 'doctorDetails';
  static const String booking = 'booking';
  static const String appointments = 'appointments';
  static const String profile = 'profile';
  static const String notifications = 'notifications';
  static const String doctorDashboard = 'doctorDashboard';
  static const String doctorAppointments = 'doctorAppointments';
}
