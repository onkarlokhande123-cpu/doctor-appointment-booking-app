/// Pure input validation shared by AuthCubit and the authentication screens.
class AuthValidators {
  AuthValidators._();

  static String? name(String value) {
    if (value.trim().isEmpty) {
      return 'Full name is required.';
    }
    if (value.trim().length < 2) {
      return 'Enter at least 2 characters.';
    }
    return null;
  }

  static String? email(String value) {
    if (value.trim().isEmpty) {
      return 'Email is required.';
    }
    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailPattern.hasMatch(value.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? mobileNumber(String value) {
    if (value.trim().isEmpty) {
      return 'Mobile number is required.';
    }
    if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) {
      return 'Enter a valid 10-digit mobile number.';
    }
    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 6) {
      return 'Use at least 6 characters.';
    }
    return null;
  }

  static String? confirmPassword({
    required String password,
    required String confirmation,
  }) {
    if (confirmation.isEmpty) {
      return 'Please confirm your password.';
    }
    if (password != confirmation) {
      return 'Passwords do not match.';
    }
    return null;
  }
}
