# Pendências reais — Carajás 360

Lista do que impede tratar esta árvore como produção. Nada aqui foi “quase feito” com valor inventado. Data da consolidação: 26 de novembro de 2026. Fonte: commit `41467b9` da branch `cursor/entrega-fluxo-completo-45c4`, com o catálogo de ícones 3D acrescentado depois.

## Ícones oficiais — aguardando arte oficial

- **Máquinas e Equipamentos**: a categoria funciona e aparece na home, no lugar do painel de referência. Não há PNG individual. O tile é verde-esmeralda com borda dourada e o nome em texto. Não foi gerada ilustração nem recorte do painel.
- **Ver Todas**: mesmo caso. Abre o quadro com todas as categorias de serviço. Sem arte individual.
- Saúde e Bem-estar e Educação e Cursos têm arte oficial e aparecem em Mais Categorias e em Ver Todas. O painel de referência não reserva um dos dez lugares da home para elas.
- Grupos sem arte nesta entrega (Pets, Jurídico, Eventos, Tecnologia, Transporte, Drones, Cuidados, Segurança e Portaria, e as profissões fora dos dez arquivos) usam o mesmo tile neutro. Não são ilustrações inventadas.
- Os PNG originais somam cerca de 42 MB em `design/icones_originais/` e ficam fora do bundle. Não foi usado Git LFS: nenhum arquivo passa de 3 MB. O WebP de produção é que entra no `pubspec`.
- Jardineiro permanece em Agro e Rural (a home já usava esse id; o grupo legado é Jardim). Técnico em ar-condicionado mantém o id Firestore `ar_condicionado` e a arte `tecnico-ar-condicionado`, sob Máquinas e Equipamentos (grupo legado Equipamentos).
- Nenhum campo novo foi gravado em `providers` ou `orders`. O id da profissão continua o mesmo. `serralheiro` é id novo, sem documentos antigos. A coleção Firestore `categories` não é a fonte dos ícones.

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
