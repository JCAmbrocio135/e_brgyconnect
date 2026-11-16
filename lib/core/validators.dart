
class Validators {
  static String? required(String? v, [String field = 'This field']) {
    if (v == null || v.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

 
static String? email(String? v) {
  if (v == null || v.trim().isEmpty) {
    return 'Email is required';
  }

  final value = v.trim();

  // Accept Gmail addresses only.
  final emailRegex = RegExp(
    r'^[A-Za-z0-9](?:[A-Za-z0-9._%+-]*[A-Za-z0-9])?@gmail\.com$',
    caseSensitive: false,
  );

  if (!emailRegex.hasMatch(value)) {
    return 'Enter a valid Gmail address';
  }

  // Gmail does not allow consecutive dots.
  final username = value.split('@').first;

  if (username.contains('..')) {
    return 'Enter a valid Gmail address';
  }

  return null;
}


  static String? phone(String? v) {
  if (v == null || v.trim().isEmpty) {
    return 'Contact number is required';
  }

  // Remove spaces, hyphens, and parentheses.
  final value = v.trim().replaceAll(RegExp(r'[\s()-]'), '');

  final isPhilippine = RegExp(r'^09\d{9}$').hasMatch(value);
  final isInternational = RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(value);

  return (isPhilippine || isInternational)
      ? null
      : 'Use 09XXXXXXXXX or international format (+country code)';
}

  static String? password(String? v) {
    if (v == null || v.isEmpty) {
      return 'Password is required';
    }

    if (v.length < 8) {
      return 'At least 8 characters';
    }

    return null;
  }

  // Required name part (first name, last name): letters only
  static String? name(String? v, String field) {
    if (v == null || v.trim().isEmpty) {
      return '$field is required';
    }

    final ok = RegExp(
      r"^[A-Za-zÀ-ÿñÑ .'\-]+$",
    ).hasMatch(v.trim());

    return ok ? null : 'Letters only';
  }

  // Optional name part (middle name): can be empty
  static String? optionalName(String? v) {
    if (v == null || v.trim().isEmpty) {
      return null;
    }

    final ok = RegExp(
      r"^[A-Za-zÀ-ÿñÑ .'\-]+$",
    ).hasMatch(v.trim());

    return ok ? null : 'Letters only';
  }
}
