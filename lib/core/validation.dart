class Validation {
  static final ascii = RegExp(r'^[\x20-\x7E\r\n]*$');
  static final aluEmail = RegExp(
    r'^[a-z0-9.!#$%&\x27*+/=?^_`{|}~-]+@(alustudent\.com|alueducation\.com)$',
  );

  static String? email(String? value) {
    final email = (value ?? '').trim().toLowerCase();
    return aluEmail.hasMatch(email) ? null : 'Use your ALU email address.';
  }

  static String? text(String? value, String label, int min, int max) {
    final text = (value ?? '').trim();
    if (text.length < min || text.length > max) {
      return '$label must be $min-$max characters.';
    }
    if (!ascii.hasMatch(text)) return 'Use standard ASCII characters only.';
    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';
    if (password.length < 8 || password.length > 128) {
      return 'Use 8-128 characters.';
    }
    if (!ascii.hasMatch(password) ||
        password.contains('\n') ||
        password.contains('\r')) {
      return 'Use standard keyboard characters.';
    }
    return null;
  }
}
