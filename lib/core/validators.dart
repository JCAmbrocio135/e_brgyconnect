class Validators {
  static String? required(String? v, [String field = 'This field']) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';

    final ok = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(v.trim());

    return ok ? null : 'Enter a valid email';
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Contact number is required';
    }

    final ok = RegExp(
      r'^09\d{9}$',
    ).hasMatch(v.trim());

    return ok ? null : 'Use format 09XXXXXXXXX';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'At least 8 characters';

    return null;
  }

  // Required name part (first name, last name): letters only
  static String? name(String? v, String field) {
    if (v == null || v.trim().isEmpty) return '$field is required';

    final ok = RegExp(r"^[A-Za-zÀ-ÿñÑ .'\-]+$").hasMatch(v.trim());

    return ok ? null : 'Letters only';
  }

  // Optional name part (middle name): can be empty, otherwise letters only
  static String? optionalName(String? v) {
    if (v == null || v.trim().isEmpty) return null;

    final ok = RegExp(r"^[A-Za-zÀ-ÿñÑ .'\-]+$").hasMatch(v.trim());

    return ok ? null : 'Letters only';
  }
}