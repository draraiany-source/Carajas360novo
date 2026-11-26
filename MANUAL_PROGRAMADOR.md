# Manual do programador — Carajás 360

Como subir, testar e preparar publicação desta árvore. Não há credencial pronta. Não faça deploy no projeto `carajas360-a17c5` até as pendências de [PENDENCIAS.md](PENDENCIAS.md) estarem resolvidas de propósito.

## 1. Ferramentas

| Ferramenta | Versão usada nesta consolidação | Observação |
| --- | --- | --- |
| Flutter | 3.50.1 (estável) | O `pubspec.lock` puxa `sign_in_with_apple` 8.1.0, que exige Dart `>=3.11`. Flutter 3.38 não resolve. |
| Dart | 3.14.0 | Vem com o Flutter acima |
| Node | 18 no `functions/package.json` | Testes unitários também passaram no Node 22, com aviso `EBADENGINE`. O runtime de deploy continua 18 até alguém mudar isso com teste no emulador |
| Java | 17 no módulo Android (`build.gradle`) | JDK 21 da máquina de consolidação não substitui o SDK Android, que não estava instalado |
| Xcode | — | Só em macOS. Esta consolidação rodou em Linux |

```bash
flutter --version
node --version
```

Na raiz:

```bash
flutter pub get
```

Nas functions, o lockfile `functions/package-lock.json` foi gerado a partir do `package.json` da fonte (a branch antiga não trazia lock):

```bash
cd functions
npm ci
npm test
```

Não rode `npm install` solto se quiser repetir exatamente o lock.

## 2. Rodar o app sem Firebase real

Demonstração rotulada, só em debug, com faixa amarela:

```bash
flutter run -d chrome --dart-define=DEV_BYPASS_LOGIN=true
```

`DEV_BYPASS_LOGIN` é ignorado em profile/release (`kReleaseMode`). Sem o define, e com as opções ainda placeholder, o debug tenta o emulador (`FirebaseBootstrap.shouldUseEmulator`). Suba os emuladores antes, na raiz:

```bash
firebase emulators:start
```

Portas em `firebase.json`: Auth 9099, Firestore 8080, Storage 9199, Functions 5001, UI 4000. No Android emulador o host usado pelo app é `10.0.2.2`. Na web é `localhost`.

Forçar emulador mesmo depois de trocar as chaves (nunca em release):

```bash
flutter run --dart-define=USE_FIREBASE_EMULATOR=true
```

## 3. Semente de homologação

Só no emulador. Sem a variável, o script recusa:

```bash
node functions/seed/homologacao.js
# Recusado: defina FIRESTORE_EMULATOR_HOST. Esta semente não grava em produção.

FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node functions/seed/homologacao.js
```

Documentos gravados: `users/hml_cliente`, `users/hml_prestador`, `users/hml_empresa`, `users/hml_admin`, `providers/hml_prestador`, `config/featureFlags`. Todos com `dataset=homologacao`. Pagamentos e WhatsApp nascem desligados.

Isso não cria usuários no Auth. O teste de login no emulador continua sendo um passo à parte (`integration_test/auth_service_e2e_test.dart` e `test/auth_flow_emulator_test.dart`).

## 4. Ligar o projeto Firebase certo

Os arquivos atuais são placeholder de propósito. Não preencha `apiKey` à mão e não troque o `projectId` “no olho”.

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=carajas360-a17c5
```

Isso deve substituir `lib/firebase_options.dart` e os arquivos nativos do app que o CLI gerencia. Confira no diff que o `projectId` deixou de ser `servicoconecta` e que nenhuma chave foi parar em commit se a política do time passar a tratá-la como segredo.

Homologação: repita o comando apontando para o projeto Firebase de homologação, não para o de produção. O binário de homologação leva `--dart-define=APP_ENV=homolog`. Produção leva `--dart-define=APP_ENV=prod`. `APP_ENV` não escolhe o projeto sozinho.

Depois, no console do projeto (não feito nesta migração):

- Auth: e-mail, Google, Apple e telefone, mais os domínios da web
- App Check nas três plataformas, e só então `ENFORCE_APP_CHECK=true` nas functions
- Publicar `firestore.rules`, `storage.rules` e `firestore.indexes.json` quando houver revisão
- Secret Manager das functions (nomes, sem valores aqui): `GEMINI_API_KEY` ou `OPENAI_API_KEY` ou `ANTHROPIC_API_KEY`; `MERCADOPAGO_ACCESS_TOKEN` com `PAYMENTS_ENABLED=true`; opcional `ASAAS_API_KEY` ou `PAGARME_API_KEY` e `PAYMENT_PROVIDER`; `WHATSAPP_TOKEN` e `WHATSAPP_PHONE_ID` se um dia o envio for implementado

`OPENAI_BASE_URL` só se o endpoint não for `https://api.openai.com`.

As functions leem `process.env`. No deploy, confira no console se o segredo entrou no ambiente da função. O padrão antigo `firebase functions:config:set` com token na linha de comando não é o caminho desta versão.

Google Sign-In no iOS: copie `REVERSED_CLIENT_ID` do plist real para `ios/Runner/Info.plist`, no lugar de `COLE_SEU_REVERSED_CLIENT_ID_AQUI`.

## 5. Mapas e chave pública do Mercado Pago

Não cole segredo em arquivo Dart.

```bash
flutter run --dart-define=GOOGLE_MAPS_API_KEY=... --dart-define=MERCADOPAGO_PUBLIC_KEY=...
```

Android, além do define: `MAPS_API_KEY=...` em `android/local.properties` (não versionar). iOS: o placeholder ainda está em `ios/Runner/AppDelegate.swift`. Troque por mecanismo que não commita a chave (xcconfig local ignorado, ou o mesmo cuidado do Android) antes de publicar.

A public key do Mercado Pago pode ir no app. O access token, não.

## 6. Testes

```bash
flutter test
cd functions && npm test
```

`flutter test` não sobe emulador. O teste de fluxo de Auth é ignorado quando `127.0.0.1:9099` não responde. Para rodá-lo: emuladores no ar e `flutter test test/auth_flow_emulator_test.dart`.

Ensaio de integração (também depende do emulador):

```bash
flutter test integration_test/auth_service_e2e_test.dart
```

Análise estática:

```bash
flutter analyze
```

Não existe, hoje, suíte de regras. Quando for criar, use o emulador e contas de cliente, prestador, empresa e admin. Não marque `registrationVerified` fora do admin.

## 7. Builds

Web, comando de release pedido para esta consolidação:

```bash
flutter build web --release
```

Homologação, quando as opções forem as do projeto de homologação:

```bash
flutter build web --release --dart-define=APP_ENV=homolog
```

A pasta `build/` fica de fora do Git. `firebase.json` não declara Hosting. Publicar a pasta é um passo separado, no projeto de homologação, nunca no de produção enquanto as opções forem placeholder.

Android (máquina com SDK). Debug não exige keystore. Release sim:

```bash
flutter build apk
flutter build appbundle
```

O modelo de assinatura é `android/key.properties.example`. Copie para `android/key.properties` e gere o keystore fora do repositório. Sem esse arquivo, o release não assina com a chave de debug.

iOS (somente macOS, com Xcode). A fonte não traz `ios/Runner.xcodeproj`. Antes do primeiro build, recupere o projeto Xcode sem apagar `AppDelegate.swift`, `Info.plist` e os ícones já versionados — por exemplo `flutter create --platforms=ios .` revisando o diff — e então:

```bash
flutter build ios --release --no-codesign
flutter build ipa
```

O nome exibido no `Info.plist` ainda é ServiçoConecta. O Android já mostra Carajás 360. Alinhe os dois antes da loja, se a ficha da Apple deve usar a marca nova.

## 8. O que não fazer

- Não commitar `.env`, keystore, `key.properties`, `local.properties` nem JSON de conta de serviço.
- Não inventar `apiKey` em `firebase_options.dart`.
- Não rodar a semente sem `FIRESTORE_EMULATOR_HOST`.
- Não marcar pagamento como aprovado em código de teste contra produção. O adapter recusa isso de propósito.
- Não declarar o produto como 100% pronto. A auditoria lista o que foi provado e o que não foi.
- Não fazer deploy daqui sem decisão explícita. Esta migração não publica rules, functions nem Hosting.

## 9. Onde mexer

| Assunto | Onde |
| --- | --- |
| Rota nova | `Routes` em `app_constants.dart` e o `switch` de `main.dart` |
| Cor, tipo, componente | `lib/core/theme/`, `lib/shared/widgets/c360_ui.dart`, `c360_shell.dart` |
| Caminho de asset | `lib/core/constants/app_assets.dart` |
| Pedido e comissão | `lib/core/security/order_policy.dart`, `functions/orderPolicy.js` |
| Fluxo da Tia no servidor | `functions/platform/tools.js` e `functions/ai/` |
| Regra de dados | `firestore.rules` / `storage.rules`, e um teste de emulador que ainda não existe |
| Placeholder de ambiente | `lib/core/constants/runtime_config.dart` e `functions/.env.example` |

Ferramentas locais que permaneceram porque servem a desenvolvimento, não a relatório antigo: `tool/auth_smoke.dart`, `tool/ui_preview.dart`, `lib/auth_smoke_main.dart`.
