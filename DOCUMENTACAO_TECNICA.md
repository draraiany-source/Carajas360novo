# Documentação técnica — Carajás 360

Versão consolidada a partir da branch `cursor/entrega-fluxo-completo-45c4` (commit `41467b9`). Descreve o código que está neste repositório. Onde a prova automatizada não existe, a seção diz isso.

## 1. Arquitetura

Cliente Flutter (SDK Dart `>=3.2.0 <4.0.0`, pacote `servico_conecta`) e backend Firebase no projeto de destino `carajas360-a17c5`. Os arquivos de opções ainda descrevem o placeholder `servicoconecta`. Trocar o projeto é um passo de configuração local (`flutterfire configure`), não um deploy.

```
App Flutter
  main.dart                rotas e bootstrap
  core/                    tema, regras de acesso, política de pedido, runtime
  features/                telas por domínio
  shared/                  modelos, widgets, Firebase e pagamentos no cliente
Cloud Functions (Node, engines 18)
  functions/index.js       callables legadas, gatilhos e registro da plataforma
  functions/platform/      fluxo de solicitação, agenda, cobrança e conta
  functions/ai/            Tia Carajás (provedores, guardrails, ferramentas)
  functions/payments/      adapter Mercado Pago / Asaas / Pagar.me
  functions/seed/          semente exclusiva do emulador
Firestore + Storage
  firestore.rules, firestore.indexes.json, storage.rules
```

A região das callables usadas pelo cliente é `us-central1` (`FirebaseBootstrap` e `functions/index.js`).

`APP_ENV` (`local`, `homolog` ou `prod`) vem de `--dart-define`. Ele não troca chaves sozinho. Cada ambiente precisa do próprio `flutterfire configure`.

## 2. Telas e rotas

O mapa está em `lib/core/constants/app_constants.dart` (`Routes`) e o `switch` em `lib/main.dart`.

| Rota | Tela | Quem entra |
| --- | --- | --- |
| `/` | Splash | Público |
| `/onboarding`, `/login`, `/register` | Entrada | Público |
| `/main` | Shell (home) | Explorar sem conta |
| `/search`, `/services-hub`, `/provider-profile` | Busca e perfil público | Explorar sem conta |
| `/ai` | Central da Tia | Explorar; gravar exige conta |
| `/tia-request`, `/tia-schedule` | Solicitação e agenda | Conta |
| `/chat`, `/chat-inbox` | Chat | Conta para gravar |
| `/wallet` | Carteira | Conta |
| `/my-orders`, `/request-service` | Pedidos | Conta no fluxo que grava |
| `/health` | Saúde | Tela existente; agenda de saúde exige registro verificado no backend |
| `/marketplace`, `/store`, `/stores` | Loja | Código presente |
| `/rental`, `/bookings` | Aluguel | Código presente |
| `/gps` | Mapa / rastreio | Chave de Maps ainda placeholder |
| `/company` | Empresa | Conta |
| `/provider-home`, `/provider-onboarding` | Prestador | Conta |
| `/resolve` e variantes | Resolve (pedidos abertos) | Código presente |
| `/profile`, `/favorites`, `/notifications`, `/reviews`, `/coupons`, `/support` | Conta e suporte | Parte exige conta |
| `/admin` | Painel administrativo | `AdminGate` |
| `/delivery` | Entregas | Código presente |

A rota antiga `/ai` aponta direto para `TiaCentralScreen`. O arquivo `lib/features/ai_assistant/ai_screen.dart` só redirecionava para essa mesma tela, não era importado por ninguém e não foi trazido.

Explorar a home, a busca e o perfil público não exige conta. Orçamento, chat que grava e favorito pedem conta. Isso foi ligado nos pontos de entrada principais. Não houve varredura manual de cada botão em aparelho físico.

A grade de categorias da home segue o painel de referência: 5 colunas no desktop quando o tile fica com pelo menos 140 px (`HomeLayout.columnsFor`). No celular estreito são 2 colunas; numa largura intermediária, 3. Abaixo de 720 px o banner empilha os botões e tira o retrato da Tia de cima do texto. O toque abre a subcategoria e, em seguida, a lista de profissionais filtrada pelo id da profissão já usado no Firestore.

## 3. Identidade e assets

Cores em `lib/core/theme/app_colors.dart`: primário `#146B34`, dourado `#F5C400`, destaque `#F6C445`, sidebar `#0C3D24`, fundo `#F3F6F4`. Tema claro e escuro em `app_theme.dart`.

| Pasta | Uso |
| --- | --- |
| `assets/logos/` | Logomarca horizontal, vertical, mark e wordmark |
| `assets/tia_carajas/` | Poses oficiais e `manifest.json` |
| `assets/icons/categories/` e `assets/icons/subcategories/` | WebP oficial 512 e 256. O bundle de produção não leva os PNG |
| `functions/data/catalogo_categorias.json` | Catálogo único: id, nome, asset, profissão e categoria pai |
| `design/icones_originais/` | PNG 1254×1254 fora do pubspec (~42 MB) |
| `assets/fonts/PlusJakartaSans.ttf` | Fonte empacotada (OFL 1.1), sem CDN em runtime |
| `assets/banners/`, `empty_states/`, `lottie/`, `backgrounds/` | Estados e campanhas referenciados em `AppAssets` |
| `android/`, `ios/`, `web/` | Ícones de publicação. Cópias idênticas em `assets/icons/png/` não foram repetidas |

Onde não há WebP oficial, o tile é verde com borda dourada e o nome em texto. A ferramenta `consultarCategorias` devolve esse mesmo catálogo. O id gravado no profissional continua o da profissão (`pedreiro`, `ar_condicionado`, e os demais já existentes).

A Tia tem seis poses recortadas (`recepcionando`, `apresentando`, `escutando_voz`, `suporte`, `confirmando`, `orientando`) e um avatar. `pending_poses` pede corpo inteiro, analisando fotos, processando, apresentando orçamentos e comemorando. Os fallbacks estão no manifesto. Não foram criadas artes novas.

Licenças: [NOTICE](NOTICE).

## 4. Autenticação e modos de execução

Provedores previstos no cliente: e-mail e senha, Google, Apple e telefone. O código está em `lib/features/auth/` e `lib/shared/services/`. Sem o `flutterfire configure` e sem os provedores habilitados no console, esses logins não concluem contra o projeto real.

`DEV_BYPASS_LOGIN` (`--dart-define=DEV_BYPASS_LOGIN=true`):

- só tem efeito fora de release e com Firebase desligado;
- mostra faixa de demonstração;
- não deve ser usado para gravar dado real.

`USE_FIREBASE_EMULATOR=true`, ou chaves placeholder em debug/profile, apontam Auth, Firestore, Storage e Functions para o emulador (`firebase.json`: portas 9099, 8080, 9199, 5001). Em release o emulador não é usado. Release com placeholder lança erro na inicialização do Firebase; o `main` captura, deixa o Firebase desligado e não injeta demonstração (porque o bypass não vale em release).

Build web de release compilado com placeholder, portanto, não é um build publicável.

## 5. Firebase

### 5.1 O que o Git contém

| Arquivo | Conteúdo atual |
| --- | --- |
| `.firebaserc` | `default`: `servicoconecta` (placeholder) |
| `lib/firebase_options.dart` | `apiKey` `COLE_SUA_*`, `projectId` `servicoconecta` |
| `android/app/google-services.json` | `project_number` `000000000000`, chave `COLE_SUA_ANDROID_API_KEY_AQUI` |
| `ios/Runner/GoogleService-Info.plist` | mesma natureza de placeholder |
| `firebase.json` | rules, indexes, functions e emuladores. Não há bloco `hosting` |

Nenhum desses arquivos recebeu valor inventado. O projeto real continua sendo configurado com:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=carajas360-a17c5
```

Homologação deve usar outro projeto Firebase, não o de produção. `APP_ENV` só etiqueta o binário.

### 5.2 Firestore

Coleções com regra própria em `firestore.rules`:

`users`, `providers`, `companies`, `employees`, `branches`, `stores`, `products`, `rentals`, `bookings`, `contracts`, `orders`, `chatRooms` (+ `messages`), `wallets`, `transactions`, `payments`, `financialAudits`, `rateLimits`, `deliveries`, `appointments`, `favorites`, `reviews`, `notifications`, `reports`, `coupons`, `banners`, `categories`, `support`, `auditLogs`, `config`, `aiConversations`, `aiUsage`, `aiAudit`, `aiKnowledge`, `resolveRequests`, `resolveProposals`, `serviceDrafts`, `orderEvents`, `paymentIntents`, `platformAudit`, `scheduleLocks`.

O catch-all final nega o que não foi listado. `registrationVerified` e `verified` não são campos que o cliente grava. `serviceDrafts`, `orderEvents`, `paymentIntents` e `platformAudit` não aceitam escrita direta do cliente. Fotos de solicitação em Storage (`service-requests`) ficam com o cliente, a lista `sharedWith` ou admin.

Índices compostos estão em `firestore.indexes.json`. As regras e os índices **não foram executados no emulador** nesta consolidação. A classificação é: escritas no arquivo, sem prova de emulador.

### 5.3 Storage

Caminhos em `storage.rules`: `users`, `providers` (foto e documentos), `orders`, `stores`, `rentals`, `service-requests`, `chat_media`.

### 5.4 Semente de homologação

`functions/seed/homologacao.js` grava usuários de cliente, prestador, empresa e admin, um prestador ativo e `config/featureFlags`, todos com `dataset=homologacao`. Se `FIRESTORE_EMULATOR_HOST` não estiver definido, o processo termina com erro e não chama o Firestore de produção. Conferido nesta consolidação: saída `Recusado: defina FIRESTORE_EMULATOR_HOST` e código 1.

Flags da semente: explorar, tia, orçamentos, agenda, saúde e chat ligados; pagamentos e WhatsApp desligados.

## 6. Cloud Functions

`functions/package.json` pede Node 18. Os testes unitários desta consolidação rodaram com Node 22 (aviso `EBADENGINE`) e não sobem o emulador. Deploy deve continuar no runtime declarado, depois de revisão humana. Não houve deploy.

### 6.1 Callables e gatilhos já existentes

Exportados em `functions/index.js`:

- Pedido e dinheiro: `transitionOrder`, `processPayout`, `payOrderWithWallet`, `generatePix`, `checkPayment`, `processCardPayment`, `walletOp`
- Tia: `aiAssistant`, `tiaChat`, `tiaEstimate`, `tiaConfirm`, `tiaStatus`, `tiaHistory`, `tiaDeleteMyData`, `tiaAdminGet`, `tiaAdminUpdate`, `tiaAdminDeleteUser`, `tiaAnalyzePhoto`
- Agenda: `lembretesAgenda` (a cada 60 minutos)
- Conta e sistema: `createNotification`, `switchProfileType`, `sendPushNotification`, `updateProviderRating`, `onUserCreateGrantXp`, `cleanupOldOrders` (pedidos `pending` com mais de 7 dias)
- HTTP público antigo (`generatePixHttp`, `checkPaymentHttp`, `processCardPaymentHttp`, `aiAssistantHttp`): respondem 410 e mandam usar a callable autenticada

Comissão de repasse: 15% (`AppInfo.commission` e `processPayout`). O teste cobre o cálculo e a idempotência. Split configurável pelo admin na UI não foi refeito.

Conclusão de pedido com `paymentStatus` diferente de pago é recusada, no cliente da política e nas tools.

### 6.2 Plataforma (PR #5)

`functions/platform/registry.js` publica uma callable por nome em `TOOL_NAMES`. Todas exigem autenticação. Ação que grava exige `confirmed === true`, e o ator `model` (a IA) não consegue confirmar.

Nomes: `buscarProfissionais`, `consultarCategorias`, `consultarPerfilProfissional`, `consultarDisponibilidade`, `analisarFotografias`, `criarRascunhoSolicitacao`, `confirmarSolicitacao`, `enviarSolicitacao`, `consultarOrcamentos`, `compararOrcamentos`, `enviarOrcamento`, `aceitarOrcamento`, `consultarAgenda`, `confirmarAgendamento`, `reagendarServico`, `consultarPedido`, `acompanharPedido`, `consultarPagamento`, `consultarHistorico`, `solicitarCancelamento`, `abrirChamadoSuporte`, `consultarPlanos`, `cadastrarAvaliacao`, `atualizarStatusPedido`, `iniciarCobranca`, `atualizarFeatureFlags`, `consultarIntegracaoWhatsApp`, `excluirMinhaConta`.

`consultarPedido` recusa pedido de outra pessoa (teste). `excluirMinhaConta` apaga conversas e rascunhos da própria pessoa e marca `deletionRequestedAt`. Pedidos e pagamentos são mantidos pelo prazo legal. O usuário do Auth não é apagado automaticamente.

`atualizarFeatureFlags` é restrita a admin. Flags previstas: explorar, tia, orçamentos, agenda, pagamentos, WhatsApp, saúde, chat. O painel admin ainda não tem formulário para todas elas.

## 7. Pagamentos

Três camadas, de propósito separadas:

1. Cliente (`lib/shared/services/payment_gateway.dart` e `PaySvc` em `firebase_service.dart`). Pix e cartão chamam callables. Boleto no cliente devolve erro de credencial e não marca sucesso (teste de widget/unidade).
2. Adapter (`functions/payments/adapter.js`). Provedores nomeados: Mercado Pago (`MERCADOPAGO_ACCESS_TOKEN`), Asaas (`ASAAS_API_KEY`), Pagar.me (`PAGARME_API_KEY`). A escolha é `PAYMENT_PROVIDER` (padrão `mercadopago`). Sem token ou com `PAYMENTS_ENABLED` diferente de `true`, o status é `aguardando_credenciais` e `approved` fica `false`. Com token, o adapter ainda não aprova: a aprovação continua nas callables antigas e no webhook. O adapter não marca pagamento aprovado.
3. `iniciarCobranca` grava intenção com `approved=false`, não altera `paymentStatus` do pedido e é idempotente pela chave.

Estorno: cancelar um pedido já pago marca `refundRequested` e não marca `refunded`. O webhook de estorno do gateway não está ligado.

A public key do Mercado Pago, usada só para tokenizar cartão no cliente, entra por `--dart-define=MERCADOPAGO_PUBLIC_KEY=...`. O access token nunca vai para o app. `functions/.env.example` deixa `PAYMENTS_ENABLED=false` e `ENFORCE_APP_CHECK=false`, sem segredos.

Não use `firebase functions:config:set` com token na linha de comando. O caminho atual é variável de ambiente / Secret Manager, fora do Git.

## 8. Tia Carajás IA

Código em `functions/ai/` e telas em `lib/features/tia/`.

Sem `GEMINI_API_KEY`, `OPENAI_API_KEY` ou `ANTHROPIC_API_KEY` (valor `disabled` conta como ausente), o provedor fica indisponível e o teste garante que a rede do modelo não é chamada. Não há fallback que invente profissional, preço ou diagnóstico.

Guardrails cobertos por teste: resposta médica insegura é substituída; agendamento de saúde sem registro profissional verificado é recusado; estimativa exige amostra real; foto sem provedor não inventa elementos; limite do plano gratuito bloqueia a mensagem; kill switch impede a chamada.

Histórico vai para o Firestore e a Central recarrega quando há sessão. Uso do mês aparece na barra quando o backend responde. Planos e teto (`monthlyTokenCap`, `monthlyUsdBudget`) já existem no código. Preço cobrado do plano não deve ser anunciado enquanto `priceCents` for nulo. Artigos de `aiKnowledge` vazios fazem a ferramenta dizer que não há texto publicado.

Voz: na web, `tia_voice_web.dart` e um polyfill de `speechSynthesis` em `web/index.html` (para o `flutter_tts` não quebrar quando a API falta). No celular, o plugin é criado sob demanda. O erro de console em navegador real não foi reproduzido nesta máquina.

`consultarIntegracaoWhatsApp` (`functions/integrations/whatsapp.js`) devolve `aguardando_credenciais` sem `WHATSAPP_TOKEN` e `WHATSAPP_PHONE_ID`. `sends` permanece `false` mesmo com as variáveis preenchidas: o envio não está ligado.

## 9. Mapas

Android lê `MAPS_API_KEY` de `android/local.properties` (arquivo local, no `.gitignore`). Sem o arquivo, o manifest recebe o placeholder `COLE_SUA_GOOGLE_MAPS_API_KEY_AQUI`.

O cliente Dart lê `--dart-define=GOOGLE_MAPS_API_KEY`. O padrão também é placeholder.

iOS ainda tem a string placeholder em `ios/Runner/AppDelegate.swift` (`GMSServices.provideAPIKey`). Não foi substituída por valor nenhum.

Se a Directions API falhar, a tela de rastreio usa reta como alternativa. Isso é comportamento do código, não uma rota validada em campo.

## 10. Plataformas

| Alvo | O que há no Git | Limite |
| --- | --- | --- |
| Web | `web/` (manifest, ícones, `index.html` com polyfill) | Build de release é possível sem chave. Publicar exige opções reais e Hosting, que não está no `firebase.json` |
| Android | Gradle, `applicationId` `br.com.servicoconecta`, rótulo Carajás 360, ProGuard, `key.properties.example` | Release assinado exige keystore fora do Git. SDK Android não estava nesta máquina |
| iOS | `Podfile`, `AppDelegate.swift`, `Info.plist`, ícones, plist placeholder | Não há `Runner.xcodeproj` nem `xcworkspace` na fonte. Nome visível no `Info.plist` ainda é ServiçoConecta. Sem Xcode nesta máquina (Linux) |

Login Google no iOS, depois do `flutterfire configure`, precisa do `REVERSED_CLIENT_ID` real no `Info.plist` no lugar de `COLE_SEU_REVERSED_CLIENT_ID_AQUI`.

## 11. Testes que o repositório traz

Flutter (`flutter test`):

- `test/home_layout_test.dart` — largura do tile, banner, rótulos do ciclo de vida, boleto sem aprovação
- `test/home_visual_test.dart` — grade e golden `test/goldens/categorias_desktop.png`
- `test/order_policy_test.dart`, `test/models_test.dart`, `test/auth_validators_test.dart`, `test/tia_assistant_test.dart`
- `test/auth_flow_emulator_test.dart` — ignorado se o Auth emulator não responde em `127.0.0.1:9099`
- `test/widget_test.dart` — sanidade

Functions (`cd functions && npm test`): política de pedido, payout 15%, adapter de pagamento, Tia, ferramentas da plataforma e lembretes. Meta da suíte: 38 testes.

`integration_test/auth_service_e2e_test.dart` fala com o emulador. Não faz parte de `flutter test` padrão.

Não há teste de regras do Firestore/Storage. Não há ensaio com quatro contas reais.

## 12. O que não entra no Git

Definido em `.gitignore`: `build/`, `.dart_tool/`, `node_modules/`, `android/.gradle/`, `ios/Pods/`, `.env` (exceto os `.env.example`), keystores, `key.properties`, `android/local.properties`, contas de serviço e logs de emulador.

A varredura da fonte não achou chave privada, token de provedor nem API key `AIza` real. Os únicos segredos aparentes são senhas falsas de teste (`Senha123`) e `fake-api-key` / `test-token` dentro de testes.
