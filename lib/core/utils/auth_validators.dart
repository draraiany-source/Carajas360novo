/// Validadores de autenticação/cadastro (testáveis, sem dependência de UI).
abstract final class AuthValidators {
  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static bool isValidEmail(String email) => _emailRe.hasMatch(email.trim());

  static String? emailError(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Campo obrigatório';
    if (!isValidEmail(email)) return 'E-mail inválido';
    return null;
  }

  static String? passwordError(String? value, {int minLength = 6}) {
    final pass = value ?? '';
    if (pass.isEmpty) return 'Campo obrigatório';
    if (pass.length < minLength) return 'Mínimo de $minLength caracteres';
    return null;
  }

  static String? confirmPasswordError(String? value, String password) {
    if ((value ?? '').isEmpty) return 'Confirme a senha';
    if (value != password) return 'As senhas não coincidem';
    return null;
  }

  static String? cpfError(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 11) return 'CPF inválido';
    return null;
  }

  static String? phoneError(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Telefone inválido';
    return null;
  }
}
