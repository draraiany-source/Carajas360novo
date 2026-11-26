import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servico_conecta/features/tia/tia_models.dart';
import 'package:servico_conecta/features/tia/tia_screen.dart';

void main() {
  test('resposta indisponível não traz texto de assistente', () {
    final reply = TiaReply.unavailable('IA indisponível: provedor sem chave.');
    expect(reply.available, isFalse);
    expect(reply.text, isNull);
    expect(reply.providers, isEmpty);
    expect(reply.actions, isEmpty);
  });

  test('preço e profissionais só entram se vierem no mapa', () {
    final reply = TiaReply.fromMap({
      'available': true,
      'reply': 'Encontrei um cadastro.',
      'providers': [
        {
          'id': 'p1',
          'name': 'André Elétrica',
          'city': 'Canaã dos Carajás',
          'rating': 4.9,
          'totalReviews': 210,
          'minPrice': 180,
          'registrationLabel': 'Registro profissional não informado',
        }
      ],
      'actions': [
        {
          'type': 'request_quote',
          'label': 'Solicitar orçamento',
          'requiresConfirmation': true,
          'payload': {'category': 'eletricista'},
        }
      ],
    });
    expect(reply.providers.single.name, 'André Elétrica');
    expect(reply.actions.single.requiresConfirmation, isTrue);
    expect(reply.actions.single.payload['category'], 'eletricista');
  });

  testWidgets('central mostra a apresentação e o estado honesto sem Firebase', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: TiaCentralScreen()),
    ));
    expect(find.textContaining('Olá! Sou a Tia Carajás'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('tia-input')), 'preciso de eletricista');
    await tester.tap(find.byKey(const Key('tia-send')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.scrollUntilVisible(
      find.textContaining('IA indisponível'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('preciso de eletricista'), findsOneWidget);
    expect(find.textContaining('IA indisponível'), findsWidgets);
    expect(find.textContaining('R\$ 80'), findsNothing);
  });
}
