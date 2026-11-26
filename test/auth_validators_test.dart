import 'package:flutter_test/flutter_test.dart';
import 'package:servico_conecta/core/utils/auth_validators.dart';

void main() {
  group('AuthValidators', () {
    test('valida emails corretos e rejeita invalidos', () {
      expect(AuthValidators.isValidEmail('user@teste.com'), isTrue);
      expect(AuthValidators.isValidEmail('a@b.co'), isTrue);
      expect(AuthValidators.isValidEmail(''), isFalse);
      expect(AuthValidators.isValidEmail('sem-arroba'), isFalse);
      expect(AuthValidators.isValidEmail('a@b'), isFalse);
      expect(AuthValidators.emailError(null), 'Campo obrigatório');
      expect(AuthValidators.emailError('x'), 'E-mail inválido');
      expect(AuthValidators.emailError('ok@mail.com'), isNull);
    });

    test('valida senha com minimo de 6 caracteres', () {
      expect(AuthValidators.passwordError(''), 'Campo obrigatório');
      expect(AuthValidators.passwordError('123'), 'Mínimo de 6 caracteres');
      expect(AuthValidators.passwordError('123456'), isNull);
    });

    test('confirmacao de senha deve coincidir', () {
      expect(AuthValidators.confirmPasswordError('', 'abc123'),
          'Confirme a senha');
      expect(AuthValidators.confirmPasswordError('abc12', 'abc123'),
          'As senhas não coincidem');
      expect(AuthValidators.confirmPasswordError('abc123', 'abc123'), isNull);
    });

    test('CPF e telefone exigem quantidade minima de digitos', () {
      expect(AuthValidators.cpfError('123'), 'CPF inválido');
      expect(AuthValidators.cpfError('12345678901'), isNull);
      expect(AuthValidators.phoneError('11999'), 'Telefone inválido');
      expect(AuthValidators.phoneError('11999999999'), isNull);
    });
  });
}