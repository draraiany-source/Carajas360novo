const test = require('node:test');
const assert = require('node:assert/strict');
const { memoryDb } = require('../ai/firestore');
const { run } = require('./tools');
const { canMove, legacyStatus } = require('./lifecycle');

function ctx(db, extra = {}) {
  const notes = [];
  return {
    db,
    uid: 'u1',
    isAdmin: false,
    city: 'Canaã dos Carajás',
    userName: 'Ana',
    now: () => new Date('2026-11-26T12:00:00Z'),
    notify: async (userId, title) => notes.push({ userId, title }),
    notes,
    paymentsEnabled: false,
    gatewayConfigured: false,
    actor: 'user',
    ...extra,
  };
}

function seed() {
  return memoryDb({
    'users/u1': { name: 'Ana', city: 'Canaã dos Carajás', type: 'client' },
    'users/p1': { name: 'Bruno', type: 'provider' },
    'providers/p1': {
      name: 'Bruno Reformas',
      userId: 'p1',
      categories: ['pedreiro'],
      city: 'Canaã dos Carajás',
      active: true,
      verified: true,
      rating: 4.8,
      totalReviews: 12,
    },
    'providers/p2': {
      name: 'Inativo',
      categories: ['pedreiro'],
      city: 'Canaã dos Carajás',
      active: false,
      verified: true,
    },
  });
}

test('consultarCategorias usa o catálogo e reconhece ar-condicionado', async () => {
  const result = await run('consultarCategorias', {
    query: 'consertar meu ar-condicionado',
  }, ctx(seed()));
  assert.equal(result.ok, true);
  assert.equal(result.data.match.id, 'ar_condicionado');
  assert.equal(result.data.match.kind, 'profissao');
  assert.equal(result.data.match.categoryId, 'maquinas-e-equipamentos');
  const pedreiro = result.data.professions.find((item) => item.id === 'pedreiro');
  assert.equal(pedreiro.categoryId, 'construcao-e-reforma');
  const maquinas = result.data.categories.find((item) => item.id === 'maquinas-e-equipamentos');
  assert.equal(maquinas.pendingArt, false);
  assert.equal(maquinas.asset, 'maquinas_equipamentos');
  const verTodas = result.data.categories.find((item) => item.id === 'ver-todas');
  assert.equal(verTodas.pendingArt, true);
});

test('ferramenta exige login', async () => {
  const result = await run('consultarCategorias', {}, { db: seed() });
  assert.equal(result.ok, false);
  assert.equal(result.code, 'unauthenticated');
});

test('busca não inventa profissional inativo', async () => {
  const db = seed();
  const result = await run('buscarProfissionais', { category: 'pedreiro' }, ctx(db));
  assert.equal(result.ok, true);
  assert.equal(result.data.count, 1);
  assert.equal(result.data.providers[0].name, 'Bruno Reformas');
});

test('rascunho não avisa profissional e confirmação sem toque não grava', async () => {
  const db = seed();
  const c = ctx(db);
  const draft = await run('criarRascunhoSolicitacao', {
    category: 'pedreiro',
    title: 'Reforma do banheiro',
    description: 'Trocar piso e bancada.',
    address: 'Rua A, 10',
  }, c);
  assert.equal(draft.ok, true);
  assert.equal(c.notes.length, 0);
  const denied = await run('confirmarSolicitacao', { draftId: draft.data.draftId }, c);
  assert.equal(denied.ok, false);
  assert.equal((await db.query('orders', () => true)).length, 0);
  const confirmed = await run('confirmarSolicitacao', {
    draftId: draft.data.draftId,
    confirmed: true,
  }, c);
  assert.equal(confirmed.ok, true);
  const order = await db.get(`orders/${confirmed.data.orderId}`);
  assert.equal(order.paymentStatus, 'unpaid');
  assert.equal(order.lifecycle, 'criada');
});

test('envio é idempotente e só notifica compatíveis', async () => {
  const db = seed();
  const c = ctx(db);
  const draft = await run('criarRascunhoSolicitacao', {
    category: 'pedreiro',
    title: 'Reforma do banheiro',
    description: 'Trocar piso.',
    city: 'Canaã dos Carajás',
  }, c);
  const confirmed = await run('confirmarSolicitacao', {
    draftId: draft.data.draftId,
    confirmed: true,
  }, c);
  const sent = await run('enviarSolicitacao', {
    requestId: confirmed.data.requestId,
    confirmed: true,
  }, c);
  assert.equal(sent.ok, true);
  assert.deepEqual(sent.data.notified, ['p1']);
  const again = await run('enviarSolicitacao', {
    requestId: confirmed.data.requestId,
    confirmed: true,
  }, c);
  assert.equal(again.data.already, true);
  assert.equal(c.notes.filter((n) => n.userId === 'p1').length, 1);
});

test('aceite não cobra e impede contratação duplicada', async () => {
  const db = seed();
  const c = ctx(db);
  await db.set('resolveRequests/r1', {
    clientId: 'u1',
    orderId: 'o1',
    status: 'open',
    lifecycle: 'orcamentos_recebidos',
  });
  await db.set('orders/o1', {
    clientId: 'u1',
    status: 'pending',
    lifecycle: 'orcamentos_recebidos',
    paymentStatus: 'unpaid',
  });
  await db.set('resolveProposals/a', {
    requestId: 'r1', providerId: 'p1', total: 800, price: 800, status: 'sent',
  });
  await db.set('resolveProposals/b', {
    requestId: 'r1', providerId: 'p9', total: 900, price: 900, status: 'sent',
  });
  const providerCtx = ctx(db, { uid: 'p1' });
  const first = await run('aceitarOrcamento', {
    requestId: 'r1', proposalId: 'a', confirmed: true,
  }, c);
  assert.equal(first.ok, true);
  assert.equal(first.data.paymentStatus, 'unpaid');
  const order = await db.get('orders/o1');
  assert.equal(order.providerId, 'p1');
  assert.equal(order.price, 800);
  assert.equal(order.paymentStatus, 'unpaid');
  assert.equal(order.status, 'accepted');
  const second = await run('aceitarOrcamento', {
    requestId: 'r1', proposalId: 'b', confirmed: true,
  }, c);
  assert.equal(second.ok, false);
  assert.equal(second.code, 'already-exists');
  assert.equal((await db.get('orders/o1')).providerId, 'p1');
  void providerCtx;
});

test('modelo não consegue confirmar agendamento', async () => {
  const db = seed();
  const result = await run('confirmarAgendamento', {
    providerId: 'p1', date: '2026-12-01', time: '09:00', confirmed: true,
  }, ctx(db, { actor: 'model' }));
  assert.equal(result.ok, false);
  assert.equal((await db.query('appointments', () => true)).length, 0);
});

test('horário ocupado não é duplicado', async () => {
  const db = seed();
  const c = ctx(db);
  const first = await run('confirmarAgendamento', {
    providerId: 'p1', date: '2026-12-01', time: '09:00', confirmed: true,
  }, c);
  assert.equal(first.ok, true);
  const other = await run('confirmarAgendamento', {
    providerId: 'p1', date: '2026-12-01', time: '09:00', confirmed: true,
  }, ctx(db, { uid: 'u2' }));
  assert.equal(other.ok, false);
  assert.match(other.message, /ocupado/);
});

test('conclusão sem pagamento é recusada e avaliação exige conclusão', async () => {
  const db = seed();
  await db.set('orders/o1', {
    clientId: 'u1', providerId: 'p1', status: 'inProgress',
    lifecycle: 'aguardando_confirmacao_conclusao', paymentStatus: 'unpaid',
  });
  const c = ctx(db);
  const done = await run('atualizarStatusPedido', {
    orderId: 'o1', lifecycle: 'concluido', confirmed: true,
  }, c);
  assert.equal(done.ok, false);
  assert.match(done.message, /pagamento/);
  const review = await run('cadastrarAvaliacao', { orderId: 'o1', stars: 5, confirmed: true }, c);
  assert.equal(review.ok, false);
});

test('cobrança sem credencial não aprova pagamento', async () => {
  const db = seed();
  await db.set('orders/o1', {
    clientId: 'u1', status: 'accepted', lifecycle: 'aceito', paymentStatus: 'unpaid', price: 100,
  });
  const result = await run('iniciarCobranca', {
    orderId: 'o1', method: 'pix', confirmed: true, idempotencyKey: 'k1',
  }, ctx(db));
  assert.equal(result.ok, false);
  assert.equal(result.code, 'aguardando_credenciais');
  assert.equal(result.data.approved, false);
  const order = await db.get('orders/o1');
  assert.equal(order.paymentStatus, 'unpaid');
  const again = await run('iniciarCobranca', {
    orderId: 'o1', method: 'pix', confirmed: true, idempotencyKey: 'k1',
  }, ctx(db));
  assert.equal(again.data.already, true);
  assert.equal((await db.query('paymentIntents', () => true)).length, 1);
});

test('pedido de outro usuário é negado', async () => {
  const db = seed();
  await db.set('orders/o1', { clientId: 'outra', status: 'pending', lifecycle: 'criada' });
  const result = await run('consultarPedido', { orderId: 'o1' }, ctx(db));
  assert.equal(result.code, 'permission-denied');
});

test('máquina de estados bloqueia salto inválido', () => {
  assert.equal(canMove('criada', 'concluido'), false);
  assert.equal(canMove('em_execucao', 'aguardando_confirmacao_conclusao'), true);
  assert.equal(legacyStatus('agendado'), 'accepted');
  assert.equal(legacyStatus('concluido'), 'completed');
});

test('whatsapp e suporte não inventam envio', async () => {
  const db = seed();
  const w = await run('consultarIntegracaoWhatsApp', {}, ctx(db));
  assert.equal(w.data.status, 'aguardando_credenciais');
  assert.equal(w.data.sends, false);
  const ticket = await run('abrirChamadoSuporte', { message: 'Preciso de ajuda no pedido.' }, ctx(db));
  assert.equal(ticket.ok, true);
});
