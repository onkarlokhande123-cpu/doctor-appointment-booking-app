import 'package:flutter/material.dart';

/// Central color palette for the app. Screens should reference these
/// constants (or `Theme.of(context).colorScheme` for Material-aware
/// widgets) rather than hardcoding colors inline.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF1D6FA5); // calm medical blue
  static const Color primaryDark = Color(0xFF124D77);
  static const Color primaryLight = Color(0xFF5FA1D0);
  static const Color secondary =
      Color(0xFFFF7A59); // warm coral accent for CTAs

  // Surfaces
  static const Color background = Color(0xFFF6F8FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE1E6EC);

  // Text
  static const Color textPrimary = Color(0xFF1A1D1F);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  // Semantic status colors — business rule requires appointment status to
  // always be clearly displayed, so these are named by meaning, not hue.
  static const Color success = Color(0xFF2E9E5B); // completed
  static const Color warning = Color(0xFFE6A400); // upcoming / pending
  static const Color error = Color(0xFFE0453D); // cancelled / errors
  static const Color info = Color(0xFF3E8FE0);

  static const Color upcomingStatus = warning;
  static const Color completedStatus = success;
  static const Color cancelledStatus = error;
}
