class Validation {
  static String? email(String? value) {
    final s = (value ?? '').trim();
    if (s.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(s)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? password(String? s, {bool register = false}) {
    if (s == null || s.isEmpty) return 'Password is required';
    if (register && s.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? confirm(String? s, String password) {
    if (s == null || s.isEmpty) return 'Confirm password is required';
    return s == password ? null : 'Passwords do not match';
  }

  static String? title(String? s) => _required(s, 'Title', 100);
  static String? author(String? s) => _required(s, 'Author', 60);
  static String? _required(String? s, String label, int limit) {
    if (s == null || s.trim().isEmpty) return '$label is required';
    if (s.runes.length > limit) {
      return '$label must be at most $limit characters';
    }
    return null;
  }

  static String? rating(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final v = int.tryParse(s.trim());
    return RegExp(r'^[0-5]$').hasMatch(s.trim()) && v != null
        ? null
        : 'Rating must be a whole number from 0 to 5';
  }

  static String? notes(String? s) => (s ?? '').runes.length > 300
      ? 'Notes must be at most 300 characters'
      : null;
}
