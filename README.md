# Carajás 360

Marketplace regional de serviços, com carteira, chat, saúde, aluguel, loja e a assistente **Tia Carajás**. O aplicativo é Flutter (pacote Dart `servico_conecta`) e o backend é Firebase: Auth, Firestore, Storage e Cloud Functions. O nome visível no Android e no app é Carajás 360. O identificador nativo continua `br.com.servicoconecta`.

Esta árvore é a versão limpa da branch `cursor/entrega-fluxo-completo-45c4` do repositório de backup [draraiany-source/Carajas360](https://github.com/draraiany-source/Carajas360) (commit `41467b963d376a18fd2b8cabdd3caa27a45b669a`, pull request #5, que já inclui o redesign e a Tia Carajás). O histórico Git antigo não foi copiado. Aquele repositório não foi alterado. O projeto Firebase `carajas360-a17c5` não foi modificado e nada foi publicado a partir daqui.

## Estado real

As telas, a paleta verde e dourada, a logomarca, a Tia, as regras, os índices e as Cloud Functions foram preservados. Há testes automatizados de layout, política de pedido e functions. Pagamento real, provedor de IA, WhatsApp, Mapas e o login dos provedores sociais dependem de credenciais que **não estão** neste repositório.

`lib/firebase_options.dart`, `android/app/google-services.json` e `ios/Runner/GoogleService-Info.plist` continuam placeholders (`projectId` `servicoconecta`, chaves `COLE_SUA_`). O comando que os substitui é `flutterfire configure --project=carajas360-a17c5`. Enquanto isso, não publique.

A classificação de cada área, sem percentual inventado, está em [AUDITORIA_FINAL_CARAJAS360.pdf](AUDITORIA_FINAL_CARAJAS360.pdf). O que ainda falta para publicar está em [PENDENCIAS.md](PENDENCIAS.md).

## Documentos

| Arquivo | Para quê |
| --- | --- |
| [DOCUMENTACAO_TECNICA.md](DOCUMENTACAO_TECNICA.md) | Arquitetura, dados, functions, pagamentos, IA e regras |
| [MANUAL_PROGRAMADOR.md](MANUAL_PROGRAMADOR.md) | Ambiente, testes, build e publicação |
| [PENDENCIAS.md](PENDENCIAS.md) | O que bloqueia produção |
| [AUDITORIA_FINAL_CARAJAS360.pdf](AUDITORIA_FINAL_CARAJAS360.pdf) | Auditoria única desta consolidação |
| [NOTICE](NOTICE) | Feather, Lucide e Plus Jakarta Sans |

## Identidade

Verde floresta `#146B34`, dourado `#F5C400`, fundo `#F3F6F4` e cartões brancos. Definição em `lib/core/theme/app_colors.dart`. Logomarcas em `assets/logos/`. A personagem fica só em `assets/tia_carajas/`. Poses sem referência visual estão em `pending_poses` do manifesto e não foram desenhadas.

Os ícones oficiais de categoria e profissão estão em WebP (`assets/icons/categories/` e `assets/icons/subcategories/`, 512 px e 256 px). O nome já vai dentro da arte: a interface não escreve o mesmo texto por cima. O catálogo único é `functions/data/catalogo_categorias.json` (o app e as Cloud Functions leem o mesmo arquivo). Os PNG originais ficam em `design/icones_originais/` e não entram no bundle. Máquinas e Equipamentos e Ver Todas não têm arquivo individual: o tile é verde com borda dourada e o nome em texto. Relato em [docs/RELATORIO_ICONES_3D.pdf](docs/RELATORIO_ICONES_3D.pdf).

## Ambientes

O app não mistura homologação e produção. Não há chave real no Git.

| Ambiente | Como ligar | Firebase |
| --- | --- | --- |
| Demonstração rotulada | `flutter run -d chrome --dart-define=DEV_BYPASS_LOGIN=true` | Desligado. A faixa amarela avisa que os cartões são demonstração. O define é ignorado em release. |
| Emulador | `flutter run --dart-define=USE_FIREBASE_EMULATOR=true` | Auth 9099, Firestore 8080, Storage 9199, Functions 5001. |
| Homologação | `--dart-define=APP_ENV=homolog` depois do `flutterfire configure` do projeto de homologação | Projeto separado do de produção. Ainda não há arquivo de opções reais. |
| Produção | `--dart-define=APP_ENV=prod` e `flutterfire configure --project=carajas360-a17c5` | Hoje as opções ainda apontam para o placeholder `servicoconecta`. |

A semente de homologação só grava no emulador:

```bash
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node functions/seed/homologacao.js
```

Sem `FIRESTORE_EMULATOR_HOST` o script recusa e sai com erro.

## Prova desta consolidação (26 de novembro de 2026)

Máquina Linux, Flutter 3.50.1, Dart 3.14.0, Node 22.23.4 (o `package.json` das functions pede Node 18; o teste avisou `EBADENGINE` e passou).

| Suíte | Resultado |
| --- | --- |
| `cd functions && npm ci && npm test` | 38 aprovados, 0 falhas |
| `flutter test` | 48 aprovados, 0 falhas, 1 ignorado (emulador de Auth desligado) |
| Semente sem `FIRESTORE_EMULATOR_HOST` | Recusou e saiu com código 1 |
| `flutter build web --release` | Concluiu (`build/web`). Não foi publicado. As opções Firebase continuam placeholder, então esse artefato não sobe em produção |
| Android (`flutter build apk --release`) | Não compilou: Android SDK ausente |
| iOS | Não compilou: Linux sem Xcode, e o Flutter desta máquina não oferece o subcomando `ios`. A fonte também não traz `ios/Runner.xcodeproj` |

## Primeiros comandos

Requer Flutter estável com Dart `>=3.11` (nesta consolidação, Flutter 3.50.1 / Dart 3.14.0) e Node 18 nas functions (os testes unitários também rodaram no Node 22).

```bash
flutter pub get
flutter test
flutter run -d chrome --dart-define=DEV_BYPASS_LOGIN=true
cd functions && npm ci && npm test
flutter build web --release
```

O build web de homologação, quando houver opções reais daquele projeto, usa também `--dart-define=APP_ENV=homolog`. A saída fica em `build/web` e não entra no Git.

## Estrutura

```
lib/                 aplicativo (telas, tema, serviços)
assets/              logo, ícones, fonte, Tia Carajás
android/  ios/  web/ plataformas
functions/           Cloud Functions, pagamentos, IA, semente
test/                testes Flutter
integration_test/    ensaio de Auth no emulador
firestore.rules  storage.rules  firestore.indexes.json  firebase.json
```
