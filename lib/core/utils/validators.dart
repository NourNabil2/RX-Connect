class Validators {
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Age is required';
    }
    final age = int.tryParse(value);
    if (age == null || age < 1 || age > 100) {
      return 'Please enter a valid age';
    }
    return null;
  }

  static String? validateTeamName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Team name is required';
    }
    if (value.length < 3) {
      return 'Team name must be at least 3 characters';
    }
    return null;
  }
}