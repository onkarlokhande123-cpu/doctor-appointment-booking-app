import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:appointment_booking_app/core/routes/app_routes.dart';
import 'package:appointment_booking_app/core/routes/auth_state_listenable.dart';
import 'package:appointment_booking_app/core/widgets/placeholder_screen.dart';
import 'package:appointment_booking_app/data/repositories/appointment_repository.dart';
import 'package:appointment_booking_app/data/repositories/auth_repository.dart';
import 'package:appointment_booking_app/data/repositories/doctor_repository.dart';
import 'package:appointment_booking_app/data/repositories/notification_repository.dart';
import 'package:appointment_booking_app/presentation/auth/cubit/auth_cubit.dart';
import 'package:appointment_booking_app/presentation/auth/screens/forgot_password_screen.dart';
import 'package:appointment_booking_app/presentation/auth/screens/login_screen.dart';
import 'package:appointment_booking_app/presentation/auth/screens/register_screen.dart';
import 'package:appointment_booking_app/presentation/appointments/bloc/appointment_list_bloc.dart';
import 'package:appointment_booking_app/presentation/appointments/bloc/appointment_list_event.dart';
import 'package:appointment_booking_app/presentation/appointments/screens/appointments_screen.dart';
import 'package:appointment_booking_app/presentation/doctor_details/cubit/doctor_details_cubit.dart';
import 'package:appointment_booking_app/presentation/doctor_details/screens/doctor_details_screen.dart';
import 'package:appointment_booking_app/presentation/doctor_appointments/cubit/doctor_appointments_cubit.dart';
import 'package:appointment_booking_app/presentation/doctor_appointments/screens/doctor_appointments_screen.dart';
import 'package:appointment_booking_app/presentation/doctor_dashboard/cubit/doctor_dashboard_cubit.dart';
import 'package:appointment_booking_app/presentation/doctor_dashboard/screens/doctor_dashboard_screen.dart';
import 'package:appointment_booking_app/presentation/booking/bloc/booking_bloc.dart';
import 'package:appointment_booking_app/presentation/booking/bloc/booking_event.dart';
import 'package:appointment_booking_app/presentation/booking/screens/booking_screen.dart';
import 'package:appointment_booking_app/presentation/home/cubit/home_cubit.dart';
import 'package:appointment_booking_app/presentation/home/screens/home_screen.dart';
import 'package:appointment_booking_app/presentation/notifications/cubit/notifications_cubit.dart';
import 'package:appointment_booking_app/presentation/notifications/screens/notifications_screen.dart';
import 'package:appointment_booking_app/presentation/profile/cubit/profile_cubit.dart';
import 'package:appointment_booking_app/presentation/profile/screens/profile_screen.dart';

/// Builds and owns the app's [GoRouter] configuration.
///
/// Auth routes render their feature screens. Remaining feature routes keep a
/// [PlaceholderScreen] until their respective implementation steps.
class AppRouter {
  AppRouter({required this.authState});

  final AuthStateListenable authState;

  late final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: authState,
    redirect: _handleRedirect,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRouteNames.splash,
        builder: (context, state) => const PlaceholderScreen(
          title: 'Splash',
          subtitle: 'Startup/auth check will be implemented in a later step.',
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: AppRouteNames.onboarding,
        builder: (context, state) => const PlaceholderScreen(
          title: 'Onboarding',
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: AppRouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: AppRouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: AppRouteNames.home,
        builder: (context, state) => BlocProvider(
          create: (context) => HomeCubit(
            doctorRepository: context.read<DoctorRepository>(),
          ),
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.doctorDetails,
        name: AppRouteNames.doctorDetails,
        builder: (context, state) {
          final doctorId = state.pathParameters['doctorId'] ?? '';
          return BlocProvider(
            create: (context) => DoctorDetailsCubit(
              doctorRepository: context.read<DoctorRepository>(),
              doctorId: doctorId,
            )..load(),
            child: const DoctorDetailsScreen(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.booking,
        name: AppRouteNames.booking,
        builder: (context, state) {
          final doctorId = state.pathParameters['doctorId'] ?? '';
          final user = context.read<AuthCubit>().state.user;
          if (user == null) {
            return const PlaceholderScreen(title: 'Unable to start booking');
          }
          return BlocProvider(
            create: (context) => BookingBloc(
              doctorRepository: context.read<DoctorRepository>(),
              appointmentRepository: context.read<AppointmentRepository>(),
              user: user,
              doctorId: doctorId,
            )..add(const BookingStarted()),
            child: const BookingScreen(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.appointments,
        name: AppRouteNames.appointments,
        builder: (context, state) {
          final user = context.read<AuthCubit>().state.user;
          if (user == null) {
            return const PlaceholderScreen(
                title: 'Unable to load appointments');
          }
          return BlocProvider(
            create: (context) => AppointmentListBloc(
              appointmentRepository: context.read<AppointmentRepository>(),
              user: user,
            )..add(const AppointmentListStarted()),
            child: const AppointmentsScreen(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: AppRouteNames.profile,
        builder: (context, state) {
          final user = context.read<AuthCubit>().state.user;
          if (user == null) {
            return const PlaceholderScreen(title: 'Unable to load profile');
          }
          return BlocProvider(
            create: (context) => ProfileCubit(
              authRepository: context.read<AuthRepository>(),
              user: user,
            ),
            child: const ProfileScreen(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: AppRouteNames.notifications,
        builder: (context, state) {
          final user = context.read<AuthCubit>().state.user;
          if (user == null) {
            return const PlaceholderScreen(
              title: 'Unable to load notifications',
            );
          }
          return BlocProvider(
            create: (context) => NotificationsCubit(
              notificationRepository: context.read<NotificationRepository>(),
              user: user,
            ),
            child: const NotificationsScreen(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.doctorDashboard,
        name: AppRouteNames.doctorDashboard,
        builder: (context, state) {
          final user = context.read<AuthCubit>().state.user;
          if (user == null) {
            return const PlaceholderScreen(
              title: 'Unable to load doctor dashboard',
            );
          }
          return BlocProvider(
            create: (context) => DoctorDashboardCubit(
              doctorRepository: context.read<DoctorRepository>(),
              appointmentRepository: context.read<AppointmentRepository>(),
              user: user,
            ),
            child: const DoctorDashboardScreen(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.doctorAppointments,
        name: AppRouteNames.doctorAppointments,
        builder: (context, state) {
          final user = context.read<AuthCubit>().state.user;
          if (user == null) {
            return const PlaceholderScreen(
              title: 'Unable to load doctor appointments',
            );
          }
          return BlocProvider(
            create: (context) => DoctorAppointmentsCubit(
              appointmentRepository: context.read<AppointmentRepository>(),
              user: user,
            ),
            child: const DoctorAppointmentsScreen(),
          );
        },
      ),
    ],
    errorBuilder: (context, state) => PlaceholderScreen(
      title: 'Page not found',
      subtitle: state.error.toString(),
    ),
  );

  /// Auth-state-based redirect logic.
  ///
  ///  - Unauthenticated users are sent to `/login`, except for the auth
  ///    routes themselves (so they can actually reach login/register).
  ///  - Authenticated users are kept away from the auth routes and sent to
  ///    `/home` instead.
  ///  - Splash enters the matching auth destination until a dedicated startup
  ///    flow is implemented. Onboarding remains available for its future flow.
  ///
  /// [authState] is the only thing this method reads — when Firebase Auth
  /// replaces the placeholder in a later step, only the source feeding
  /// [authState] changes, not this logic.
  String? _handleRedirect(BuildContext context, GoRouterState state) {
    final loggedIn = authState.isLoggedIn;
    final currentPath = state.matchedLocation;

    final isAuthRoute = currentPath == AppRoutes.login ||
        currentPath == AppRoutes.register ||
        currentPath == AppRoutes.forgotPassword;
    final isDoctorRoute = currentPath == AppRoutes.doctorDashboard ||
        currentPath == AppRoutes.doctorAppointments;
    final isSharedAuthenticatedRoute = currentPath == AppRoutes.profile ||
        currentPath == AppRoutes.notifications;
    final landingRoute =
        authState.isDoctor ? AppRoutes.doctorDashboard : AppRoutes.home;

    if (currentPath == AppRoutes.splash) {
      return loggedIn ? landingRoute : AppRoutes.login;
    }
    if (currentPath == AppRoutes.onboarding) return null;

    if (!loggedIn && !isAuthRoute) return AppRoutes.login;
    if (loggedIn && isAuthRoute) return landingRoute;
    if (loggedIn &&
        authState.isDoctor &&
        !isDoctorRoute &&
        !isSharedAuthenticatedRoute) {
      return AppRoutes.doctorDashboard;
    }
    if (loggedIn && !authState.isDoctor && isDoctorRoute) {
      return AppRoutes.home;
    }

    return null;
  }
}
