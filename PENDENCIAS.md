# Pendências reais — Carajás 360

Lista do que impede tratar esta árvore como produção. Nada aqui foi “quase feito” com valor inventado. Data da consolidação: 26 de novembro de 2026. Fonte: commit `41467b9` da branch `cursor/entrega-fluxo-completo-45c4`, com o catálogo de ícones 3D acrescentado depois.

## Ícones oficiais — aguardando arte oficial

A coleção de 1024 px é o master em `design/icones_originais/webp1024/`. Os PNG de 1254 px da rodada anterior saíram para não duplicar peso. Máquinas e Equipamentos e Mais Categorias já têm arquivo.

Ainda sem arte, com cartão discreto e o nome em texto. Não foram inventadas:

- Serviços gerais (`aux_servicos_gerais`)
- Assistência técnica (`assistencia_tecnica`)
- Costureira (`costureira`)
- Cozinheira (`cozinheira`)
- **Ver Todas**: não há arte própria. A grade usa `mais_categorias.webp` só no atalho Mais Categorias. O texto "Ver todas" do cabeçalho abre o quadro completo, sem um segundo ícone.

Grupos extras sem ilustração de categoria (Pets, Jurídico, Eventos, Tecnologia, Transporte, Drones, Cuidados, Segurança e Portaria) usam o mesmo cartão. Profissões desses grupos que têm WebP mostram a arte.

Nenhum campo novo foi gravado em `providers` ou `orders`. Ids já usados foram preservados. `firebase.json` continua sem bloco `hosting`, então não há header de cache de `/assets` para publicar. iOS segue sem projeto Xcode, como na lista abaixo.

Legenda usada também no PDF: implementada e testada, implementada parcialmente, não implementada, bloqueada por integração externa, aguardando credenciais, reprovada nos testes.

## Credenciais e configuração

Aguardando credenciais. Nenhum valor real está no Git.

- `flutterfire configure --project=carajas360-a17c5` e o equivalente num projeto Firebase só de homologação. `firebase_options.dart`, `google-services.json` e `GoogleService-Info.plist` seguem placeholder `servicoconecta`.
- `.firebaserc` ainda aponta para `servicoconecta`. Não foi redirecionado para não simular uma ligação que o CLI ainda não fez.
- Auth do projeto real: e-mail, Google, Apple, telefone e domínios web.
- `REVERSED_CLIENT_ID` no `Info.plist` do iOS, depois do plist real.
- App Check nas três plataformas antes de `ENFORCE_APP_CHECK=true`.
- `MERCADOPAGO_ACCESS_TOKEN` e `PAYMENTS_ENABLED=true`. Opcional: `ASAAS_API_KEY` ou `PAGARME_API_KEY` com `PAYMENT_PROVIDER`.
- Uma chave de IA no Secret Manager: `GEMINI_API_KEY`, `OPENAI_API_KEY` ou `ANTHROPIC_API_KEY`. Sem ela a Tia fica indisponível de propósito.
- `WHATSAPP_TOKEN` e `WHATSAPP_PHONE_ID` não bastam: `sends` continua `false`. O envio em si não está implementado.
- Google Maps: `MAPS_API_KEY` em `android/local.properties`, `--dart-define=GOOGLE_MAPS_API_KEY` e o placeholder ainda literal em `ios/Runner/AppDelegate.swift`.
- `MERCADOPAGO_PUBLIC_KEY` por `--dart-define` para tokenizar cartão no cliente.
- Keystore de upload Android (`android/key.properties` fora do Git).
- Hosting: `firebase.json` não tem bloco `hosting`.

## Produto e prova

- Ensaio de ponta a ponta com cliente, prestador, empresa e admin no emulador. Não foi feito.
- Testes das regras Firestore e Storage no emulador. Não há suíte. Classificação: não implementada.
- Formulário admin para todas as feature flags (`explorar`, `tia`, `orcamentos`, `agenda`, `pagamentos`, `whatsapp`, `saude`, `chat`). A callable existe; a tela não cobre todas. Classificação: implementada parcialmente.
- Webhook de estorno do gateway. Hoje o cancelamento de pedido pago só marca `refundRequested`.
- Split de comissão editável pelo admin. A comissão fixa de 15% está testada.
- Poses da Tia em `assets/tia_carajas/manifest.json` → `pending_poses`: corpo inteiro, analisando fotos, processando, apresentando orçamentos, comemorando. Não foram inventadas.
- Varredura manual de botões que esta consolidação não clicou. Os cobertos por teste ou pela rodada anterior (grade, banner, busca, explorar sem entrar, solicitar, chat, favorito) não representam o app inteiro.
- Artigos da base `aiKnowledge` e preços em `config/aiPlans` (`priceCents` nulo não deve virar anúncio de valor).
- `registrationVerified` / conselho profissional (CRM, CRP, CRN, CREFITO, CRO) só pelo admin, com checagem humana. Não foi exercitado no emulador.
- Exclusão de conta não remove o usuário do Auth. Pedidos e pagamentos ficam pelo prazo legal. Isso é comportamento atual, não um bug silencioso, mas a operação completa de LGPD ainda é parcial.
- Nome visível do iOS em `Info.plist` ainda é ServiçoConecta. Android e `AppInfo.name` já são Carajás 360.
- Projeto Xcode ausente: a fonte não contém `ios/Runner.xcodeproj` nem workspace. iOS não compila até isso ser recuperado num Mac.
- SDK Android e Xcode não estavam na máquina desta consolidação. APK, AAB e IPA não foram gerados.
- Build web de release com placeholder compila, e em runtime o Firebase não sobe. Não publicar esse artefato.
- `functions/package.json` declara Node 18. Os testes unitários passaram no Node 22. Falta repetir no runtime 18 de deploy.
- Polyfill de `speechSynthesis` está no `index.html`. O TypeError do `flutter_tts` em navegador real não foi reproduzido aqui.

## Fora desta migração, de propósito

- Nenhum deploy de rules, índices, functions ou Hosting.
- Nenhum valor novo em `firebase_options.dart`.
- O repositório antigo permanece como backup, sem push e sem alteração.
