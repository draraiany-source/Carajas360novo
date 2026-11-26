'use strict';

const aiTools = require('../ai/tools');
const lifecycle = require('./lifecycle');
const payments = require('../payments/adapter');
const whatsapp = require('../integrations/whatsapp');

const PHOTO_DISCLAIMER =
  'Análise preliminar automática. Não substitui avaliação presencial do profissional.';

function clip(value, max) {
  return String(value || '').trim().slice(0, max);
}

function ok(data, message) {
  return { ok: true, code: 'ok', message: message || 'Concluído.', data: data || {} };
}

function fail(code, message, data) {
  return { ok: false, code, message, data: data || {} };
}

function confirmed(data, ctx) {
  if (ctx.actor === 'model') return false;
  return data && data.confirmed === true;
}

function needConfirm(data, ctx) {
  if (confirmed(data, ctx)) return null;
  return fail(
    'failed-precondition',
    'Esta ação exige confirmação explícita. Nada foi gravado.',
  );
}

async function tx(db, fn) {
  if (typeof db.runTransaction === 'function') return db.runTransaction(fn);
  return fn(db);
}

async function touchOrder(ctx, orderId, patch, note) {
  const current = (await ctx.db.get(`orders/${orderId}`)) || {};
  const next = { ...patch, updatedAt: ctx.now().toISOString() };
  await ctx.db.set(`orders/${orderId}`, next, { merge: true });
  await ctx.db.add('orderEvents', {
    orderId,
    clientId: current.clientId || patch.clientId || null,
    providerId: patch.providerId || current.providerId || null,
    lifecycle: patch.lifecycle || current.lifecycle || null,
    note: clip(note, 180),
    uid: ctx.uid,
    at: ctx.now().toISOString(),
  });
}

async function ownOrder(ctx, orderId) {
  const order = await ctx.db.get(`orders/${clip(orderId, 80)}`);
  if (!order) return { error: fail('not-found', 'Pedido não encontrado.') };
  const provider = order.providerId === ctx.uid;
  const client = order.clientId === ctx.uid;
  if (!client && !provider && !ctx.isAdmin) {
    return { error: fail('permission-denied', 'Pedido de outro usuário.') };
  }
  return { order, role: ctx.isAdmin && !client && !provider ? 'admin' : (client ? 'client' : 'provider') };
}

async function buscarProfissionais(data, ctx) {
  const result = await aiTools.executeTool('search_professionals', {
    query: data.query,
    category: data.category,
    specialty: data.specialty,
    city: data.city || ctx.city,
    healthOnly: data.healthOnly === true,
  }, ctx);
  return ok(result, result.note || 'Busca concluída.');
}

async function consultarCategorias() {
  return ok({ categories: aiTools.CATEGORIES, specialties: aiTools.SPECIALTIES });
}

async function consultarPerfilProfissional(data, ctx) {
  const id = clip(data.providerId, 80);
  if (!id) return fail('invalid-argument', 'providerId obrigatório.');
  const provider = await ctx.db.get(`providers/${id}`);
  if (!provider || provider.active !== true) {
    return fail('not-found', 'Profissional não encontrado.');
  }
  const reviews = await ctx.db.query('reviews', (d) => d.providerId === id);
  return ok({
    provider: aiTools.publicProvider({ id, data: provider }),
    reviews: reviews.slice(0, 20).map((doc) => ({
      id: doc.id,
      stars: Number(doc.data.stars || 0),
      comment: clip(doc.data.comment, 400),
      createdAt: doc.data.createdAt || null,
    })),
  }, reviews.length ? 'Perfil e avaliações gravadas.' : 'Perfil sem avaliações gravadas.');
}

async function consultarDisponibilidade(data, ctx) {
  const result = await aiTools.executeTool('get_availability', data, ctx);
  return ok(result, result.note || 'Agenda consultada.');
}

async function analisarFotografias(data, ctx) {
  const note = clip(data.note, 500);
  if (!data.imageBase64 && !data.storagePath) {
    return fail('invalid-argument', 'Envie a foto para análise.');
  }
  const base = {
    disclaimer: PHOTO_DISCLAIMER,
    replacesOnSiteVisit: false,
  };
  if (typeof ctx.analyzePhoto !== 'function') {
    return fail('ia_indisponivel', 'Análise de foto indisponível neste ambiente. O pedido pode seguir sem ela.', base);
  }
  const insight = await ctx.analyzePhoto(data);
  if (!insight || insight.available === false) {
    return fail('ia_indisponivel', insight?.reason || 'Análise de foto indisponível.', base);
  }
  return ok({ ...base, insight }, PHOTO_DISCLAIMER);
}

async function criarRascunhoSolicitacao(data, ctx) {
  const category = clip(data.category, 40);
  const title = clip(data.title, 120);
  const description = clip(data.description, 2000);
  if (!category || !title || !description) {
    return fail('invalid-argument', 'Categoria, título e descrição são obrigatórios.');
  }
  const id = await ctx.db.add('serviceDrafts', {
    clientId: ctx.uid,
    category,
    title,
    description,
    address: clip(data.address, 200),
    city: clip(data.city || ctx.city, 80),
    providerId: clip(data.providerId, 80) || null,
    photoIds: Array.isArray(data.photoIds) ? data.photoIds.slice(0, 8) : [],
    status: 'rascunho',
    dataset: 'real',
    createdAt: ctx.now().toISOString(),
  });
  return ok({ draftId: id, status: 'rascunho' }, 'Rascunho salvo. Nenhum profissional foi avisado.');
}

async function confirmarSolicitacao(data, ctx) {
  const blocked = needConfirm(data, ctx);
  if (blocked) return blocked;
  const draftId = clip(data.draftId, 80);
  const draft = await ctx.db.get(`serviceDrafts/${draftId}`);
  if (!draft) return fail('not-found', 'Rascunho não encontrado.');
  if (draft.clientId !== ctx.uid && !ctx.isAdmin) return fail('permission-denied', 'Rascunho de outro usuário.');
  if (draft.orderId && draft.requestId) {
    return ok({ already: true, orderId: draft.orderId, requestId: draft.requestId }, 'Solicitação já confirmada.');
  }
  const orderId = await ctx.db.add('orders', {
    clientId: ctx.uid,
    providerId: draft.providerId || null,
    category: draft.category,
    title: draft.title,
    description: draft.description,
    address: draft.address || '',
    city: draft.city || '',
    status: 'pending',
    lifecycle: 'criada',
    paymentStatus: 'unpaid',
    payoutProcessed: false,
    payoutStatus: 'none',
    source: 'plataforma',
    dataset: 'real',
    createdAt: ctx.now().toISOString(),
  });
  const requestId = await ctx.db.add('resolveRequests', {
    clientId: ctx.uid,
    clientName: clip(ctx.userName, 80),
    description: draft.description,
    category: draft.category,
    city: draft.city || '',
    address: draft.address || '',
    title: draft.title,
    status: 'open',
    lifecycle: 'criada',
    proposalCount: 0,
    source: 'plataforma',
    orderId,
    sharedWith: [ctx.uid],
    createdAt: ctx.now().toISOString(),
  });
  await ctx.db.set(`serviceDrafts/${draftId}`, {
    status: 'confirmado',
    orderId,
    requestId,
    confirmedAt: ctx.now().toISOString(),
  }, { merge: true });
  await touchOrder(ctx, orderId, { lifecycle: 'criada' }, 'Solicitação confirmada pelo cliente');
  return ok({ orderId, requestId }, 'Solicitação registrada. Nada foi cobrado.');
}

async function enviarSolicitacao(data, ctx) {
  const blocked = needConfirm(data, ctx);
  if (blocked) return blocked;
  const requestId = clip(data.requestId, 80);
  const request = await ctx.db.get(`resolveRequests/${requestId}`);
  if (!request) return fail('not-found', 'Solicitação não encontrada.');
  if (request.clientId !== ctx.uid && !ctx.isAdmin) return fail('permission-denied', 'Solicitação de outro usuário.');
  if (request.sentAt) {
    return ok({ already: true, requestId, notified: request.notifiedProviderIds || [] }, 'Solicitação já enviada.');
  }
  const city = clip(request.city, 80).toLowerCase();
  const category = clip(request.category, 40).toLowerCase();
  const docs = await ctx.db.query('providers', (d) => d.active === true && d.verified === true);
  const matches = docs.filter((doc) => {
    const d = doc.data || {};
    const cats = (d.categories || []).map((c) => String(c).toLowerCase());
    if (category && !cats.includes(category)) return false;
    if (city && String(d.city || '').toLowerCase() !== city) return false;
    return true;
  }).slice(0, 15);
  const ids = matches.map((d) => d.id);
  for (const doc of matches) {
    const target = doc.data.userId || doc.id;
    if (ctx.notify) await ctx.notify(target, 'Nova solicitação', request.title || request.category, 'order');
  }
  await ctx.db.set(`resolveRequests/${requestId}`, {
    sentAt: ctx.now().toISOString(),
    notifiedProviderIds: ids,
    sharedWith: [request.clientId, ...ids],
    lifecycle: 'aguardando_orcamentos',
    status: 'open',
  }, { merge: true });
  if (request.orderId) {
    await touchOrder(ctx, request.orderId, {
      lifecycle: 'aguardando_orcamentos',
      status: lifecycle.legacyStatus('aguardando_orcamentos'),
    }, `Enviada a ${ids.length} profissional(is)`);
  }
  return ok({
    requestId,
    notified: ids,
    count: ids.length,
  }, ids.length
    ? 'Profissionais compatíveis foram avisados.'
    : 'Nenhum profissional compatível está cadastrado. A solicitação ficou aberta.');
}

async function consultarOrcamentos(data, ctx) {
  const requestId = clip(data.requestId, 80);
  const request = await ctx.db.get(`resolveRequests/${requestId}`);
  if (!request) return fail('not-found', 'Solicitação não encontrada.', { proposals: [] });
  const mine = request.clientId === ctx.uid;
  if (!mine && !ctx.isAdmin) return fail('permission-denied', 'Sem permissão.', { proposals: [] });
  const docs = await ctx.db.query('resolveProposals', (d) => d.requestId === requestId);
  return ok({ proposals: docs.map(publicProposal) }, 'Orçamentos gravados.');
}

function publicProposal(doc) {
  const d = doc.data || {};
  return {
    id: doc.id,
    requestId: d.requestId || null,
    providerId: d.providerId || null,
    providerName: clip(d.providerName, 80),
    verified: d.verified === true,
    rating: typeof d.rating === 'number' ? d.rating : null,
    totalReviews: Number(d.totalReviews || 0),
    labor: typeof d.labor === 'number' ? d.labor : null,
    materials: typeof d.materials === 'number' ? d.materials : null,
    total: typeof d.total === 'number' ? d.total : (typeof d.price === 'number' ? d.price : null),
    deadlineDays: d.deadlineDays || null,
    availability: clip(d.availability, 120) || null,
    paymentTerms: clip(d.paymentTerms, 200) || null,
    warranty: clip(d.warranty, 200) || null,
    validUntil: clip(d.validUntil, 20) || null,
    status: clip(d.status, 40),
    message: clip(d.message, 400),
  };
}

async function compararOrcamentos(data, ctx) {
  const listed = await consultarOrcamentos(data, ctx);
  if (!listed.ok) return listed;
  const rows = listed.data.proposals || [];
  return ok({
    rows,
    note: 'Comparação só com campos gravados. Campo ausente fica nulo. Não há recomendação inventada.',
  }, rows.length ? 'Comparação pronta.' : 'Ainda não há orçamentos para comparar.');
}

async function enviarOrcamento(data, ctx) {
  const requestId = clip(data.requestId, 80);
  const request = await ctx.db.get(`resolveRequests/${requestId}`);
  if (!request) return fail('not-found', 'Solicitação não encontrada.');
  const provider = await ctx.db.get(`providers/${ctx.uid}`);
  if (!provider || provider.active !== true) return fail('permission-denied', 'Apenas prestador ativo envia orçamento.');
  const total = Number(data.total);
  if (!(total > 0)) return fail('invalid-argument', 'Informe o total do orçamento.');
  const labor = data.labor == null ? null : Number(data.labor);
  const materials = data.materials == null ? null : Number(data.materials);
  if (labor != null && materials != null && Math.abs(labor + materials - total) > 0.05) {
    return fail('invalid-argument', 'Mão de obra e materiais não fecham com o total.');
  }
  const id = await ctx.db.add('resolveProposals', {
    requestId,
    providerId: ctx.uid,
    providerName: clip(provider.name, 80),
    verified: provider.verified === true,
    rating: typeof provider.rating === 'number' ? provider.rating : null,
    totalReviews: Number(provider.totalReviews || 0),
    labor,
    materials,
    total,
    price: total,
    deadlineDays: clip(data.deadlineDays, 40) || null,
    availability: clip(data.availability, 120) || null,
    paymentTerms: clip(data.paymentTerms, 200) || null,
    warranty: clip(data.warranty, 200) || null,
    validUntil: clip(data.validUntil, 20) || null,
    message: clip(data.message, 800),
    status: 'sent',
    createdAt: ctx.now().toISOString(),
  });
  const nextLife = request.lifecycle === 'aceito' ? request.lifecycle : 'orcamentos_recebidos';
  await ctx.db.set(`resolveRequests/${requestId}`, {
    lifecycle: nextLife,
    proposalCount: Number(request.proposalCount || 0) + 1,
  }, { merge: true });
  if (request.orderId) {
    await touchOrder(ctx, request.orderId, {
      lifecycle: nextLife,
      status: lifecycle.legacyStatus(nextLife),
    }, 'Orçamento recebido');
  }
  if (ctx.notify) await ctx.notify(request.clientId, 'Novo orçamento', provider.name || 'Profissional', 'quote');
  return ok({ proposalId: id }, 'Orçamento enviado. O cliente ainda não contratou.');
}

async function aceitarOrcamento(data, ctx) {
  const blocked = needConfirm(data, ctx);
  if (blocked) return blocked;
  const proposalId = clip(data.proposalId, 80);
  const requestId = clip(data.requestId, 80);
  try {
    const result = await tx(ctx.db, async (trx) => {
      const proposal = await trx.get(`resolveProposals/${proposalId}`);
      const request = await trx.get(`resolveRequests/${requestId}`);
      if (!proposal || !request) return fail('not-found', 'Proposta ou solicitação não encontrada.');
      if (request.clientId !== ctx.uid && !ctx.isAdmin) return fail('permission-denied', 'Sem permissão.');
      if (proposal.requestId !== requestId) return fail('invalid-argument', 'Proposta não pertence à solicitação.');
      if (request.chosenProposalId && request.chosenProposalId !== proposalId) {
        return fail('already-exists', 'Esta solicitação já tem uma proposta aceita. Nada foi alterado.');
      }
      if (request.chosenProposalId === proposalId) {
        return ok({ already: true, proposalId, orderId: request.orderId || null }, 'Proposta já aceita.');
      }
      trx.set(`resolveProposals/${proposalId}`, { status: 'accepted', acceptedAt: ctx.now().toISOString() }, { merge: true });
      trx.set(`resolveRequests/${requestId}`, {
        status: 'accepted',
        lifecycle: 'aceito',
        chosenProposalId: proposalId,
      }, { merge: true });
      if (request.orderId) {
        trx.set(`orders/${request.orderId}`, {
          providerId: proposal.providerId,
          price: proposal.total || proposal.price,
          status: 'accepted',
          lifecycle: 'aceito',
          paymentStatus: 'unpaid',
          acceptedAt: ctx.now().toISOString(),
        }, { merge: true });
      }
      return ok({
        proposalId,
        orderId: request.orderId || null,
        providerId: proposal.providerId,
        total: proposal.total || proposal.price || null,
        paymentStatus: 'unpaid',
      }, 'Proposta aceita. Nenhum pagamento foi criado.');
    });
    return result;
  } catch (e) {
    return fail('internal', 'Não foi possível aceitar o orçamento.');
  }
}

async function consultarAgenda(data, ctx) {
  const docs = await ctx.db.query('appointments', (d) =>
    d.clientId === ctx.uid || d.providerId === ctx.uid || ctx.isAdmin);
  const date = clip(data.date, 20);
  const items = docs
    .map((d) => ({ id: d.id, ...d.data }))
    .filter((d) => !date || d.date === date)
    .slice(0, 40);
  return ok({ appointments: items });
}

async function confirmarAgendamento(data, ctx) {
  const blocked = needConfirm(data, ctx);
  if (blocked) return blocked;
  const providerId = clip(data.providerId, 80);
  const date = clip(data.date, 20);
  const time = clip(data.time, 8);
  if (!providerId || !date || !time) return fail('invalid-argument', 'Profissional, data e horário são obrigatórios.');
  const provider = await ctx.db.get(`providers/${providerId}`);
  if (!provider || provider.active !== true || provider.verified !== true) {
    return fail('failed-precondition', 'Profissional indisponível para agendamento.');
  }
  const slotId = `${providerId}_${date}_${time}`.replace(/[^\w\-]+/g, '_');
  const existingLock = await ctx.db.get(`scheduleLocks/${slotId}`);
  if (existingLock && existingLock.status === 'held' && existingLock.clientId !== ctx.uid) {
    return fail('failed-precondition', 'Esse horário acabou de ser ocupado. Escolha outro.');
  }
  try {
    const appointmentId = existingLock && existingLock.appointmentId
      ? existingLock.appointmentId
      : await ctx.db.add('appointments', {
        clientId: ctx.uid,
        providerId,
        providerName: clip(provider.name, 80),
        category: clip(data.category, 40),
        date,
        time,
        address: clip(data.address, 200),
        homeVisit: data.homeVisit === true,
        orderId: clip(data.orderId, 80) || null,
        status: 'scheduled',
        source: 'plataforma',
        createdAt: ctx.now().toISOString(),
      });
    await tx(ctx.db, async (trx) => {
      const lock = await trx.get(`scheduleLocks/${slotId}`);
      if (lock && lock.status === 'held' && lock.clientId !== ctx.uid && lock.appointmentId !== appointmentId) {
        throw new Error('conflict');
      }
      trx.set(`scheduleLocks/${slotId}`, {
        status: 'held',
        clientId: ctx.uid,
        providerId,
        date,
        time,
        appointmentId,
      }, { merge: true });
    });
    if (data.orderId) {
      await touchOrder(ctx, clip(data.orderId, 80), {
        lifecycle: 'agendado',
        status: lifecycle.legacyStatus('agendado'),
        scheduleDate: date,
        scheduleTime: time,
      }, `Agendado para ${date} ${time}`);
    }
    if (ctx.notify) await ctx.notify(provider.userId || providerId, 'Agendamento', `${date} às ${time}`, 'agenda');
    return ok({ appointmentId, date, time }, 'Horário reservado. Nada foi cobrado.');
  } catch (err) {
    if (String(err && err.message) === 'conflict') {
      return fail('failed-precondition', 'Esse horário acabou de ser ocupado. Escolha outro.');
    }
    return fail('internal', 'Não foi possível agendar.');
  }
}

async function reagendarServico(data, ctx) {
  const blocked = needConfirm(data, ctx);
  if (blocked) return blocked;
  const appointmentId = clip(data.appointmentId, 80);
  const date = clip(data.date, 20);
  const time = clip(data.time, 8);
  const current = await ctx.db.get(`appointments/${appointmentId}`);
  if (!current) return fail('not-found', 'Agendamento não encontrado.');
  if (current.clientId !== ctx.uid && current.providerId !== ctx.uid && !ctx.isAdmin) {
    return fail('permission-denied', 'Sem permissão.');
  }
  const slotId = `${current.providerId}_${date}_${time}`.replace(/[^\w\-]+/g, '_');
  const lock = await ctx.db.get(`scheduleLocks/${slotId}`);
  if (lock && lock.status === 'held' && lock.appointmentId !== appointmentId) {
    return fail('failed-precondition', 'O novo horário está ocupado.');
  }
  await ctx.db.set(`appointments/${appointmentId}`, {
    date,
    time,
    status: 'scheduled',
    rescheduledAt: ctx.now().toISOString(),
    reminderSentAt: null,
  }, { merge: true });
  await ctx.db.set(`scheduleLocks/${slotId}`, {
    status: 'held',
    clientId: current.clientId,
    providerId: current.providerId,
    appointmentId,
    date,
    time,
  }, { merge: true });
  return ok({ appointmentId, date, time }, 'Horário atualizado.');
}

async function consultarPedido(data, ctx) {
  const found = await ownOrder(ctx, data.orderId);
  if (found.error) return found.error;
  const events = await ctx.db.query('orderEvents', (d) => d.orderId === clip(data.orderId, 80));
  return ok({
    order: {
      id: clip(data.orderId, 80),
      title: found.order.title || null,
      category: found.order.category || null,
      status: found.order.status || null,
      lifecycle: found.order.lifecycle || null,
      paymentStatus: found.order.paymentStatus || 'unpaid',
      price: typeof found.order.price === 'number' ? found.order.price : null,
      providerId: found.order.providerId || null,
      clientId: found.order.clientId || null,
    },
    events: events.map((d) => ({ at: d.data.at, lifecycle: d.data.lifecycle, note: d.data.note, uid: d.data.uid })),
  });
}

async function acompanharPedido(data, ctx) {
  return consultarPedido(data, ctx);
}

async function consultarPagamento(data, ctx) {
  const found = await ownOrder(ctx, data.orderId);
  if (found.error) return found.error;
  const orderId = clip(data.orderId, 80);
  const paymentsDocs = await ctx.db.query('payments', (d) => d.orderId === orderId && (d.userId === ctx.uid || ctx.isAdmin || found.role === 'provider'));
  const intents = await ctx.db.query('paymentIntents', (d) => d.orderId === orderId && d.userId === found.order.clientId);
  const gateway = payments.describe({
    PAYMENT_PROVIDER: ctx.paymentProvider,
    PAYMENTS_ENABLED: ctx.paymentsEnabled,
    MERCADOPAGO_ACCESS_TOKEN: ctx.gatewayConfigured ? 'presente' : '',
    ASAAS_API_KEY: '',
    PAGARME_API_KEY: '',
  });
  return ok({
    paymentStatus: found.order.paymentStatus || 'unpaid',
    payments: paymentsDocs.map((d) => ({
      id: d.id,
      status: d.data.status || null,
      method: d.data.method || null,
      amount: d.data.amount || null,
    })),
    intents: intents.map((d) => ({ id: d.id, status: d.data.status, approved: false })),
    gateway,
    approved: false,
  }, gateway.message);
}

async function consultarHistorico(data, ctx) {
  const docs = await ctx.db.query('orders', (d) => d.clientId === ctx.uid || d.providerId === ctx.uid);
  return ok({
    orders: docs.slice(0, 40).map((d) => ({
      id: d.id,
      title: d.data.title || null,
      lifecycle: d.data.lifecycle || null,
      status: d.data.status || null,
      paymentStatus: d.data.paymentStatus || null,
      createdAt: d.data.createdAt || null,
    })),
  });
}

async function solicitarCancelamento(data, ctx) {
  const blocked = needConfirm(data, ctx);
  if (blocked) return blocked;
  const found = await ownOrder(ctx, data.orderId);
  if (found.error) return found.error;
  const from = found.order.lifecycle || 'criada';
  if (from === 'cancelado' || from === 'avaliado' || from === 'concluido') {
    return fail('failed-precondition', 'Este pedido não pode mais ser cancelado por aqui.');
  }
  if (!lifecycle.canMove(from, 'cancelado') && from !== 'criada') {
    return fail('failed-precondition', 'Transição de cancelamento não permitida.');
  }
  const paid = found.order.paymentStatus === 'paid';
  await touchOrder(ctx, clip(data.orderId, 80), {
    lifecycle: 'cancelado',
    status: 'cancelled',
    cancelReason: clip(data.reason, 200) || 'Cancelado pela pessoa usuária',
    refundRequested: paid,
  }, paid ? 'Cancelado com pedido de reembolso' : 'Cancelado');
  return ok({
    orderId: clip(data.orderId, 80),
    lifecycle: 'cancelado',
    refundRequested: paid,
    refunded: false,
  }, paid
    ? 'Cancelamento registrado. O reembolso depende do gateway e não foi marcado como concluído.'
    : 'Cancelamento registrado. Não havia pagamento aprovado.');
}

async function abrirChamadoSuporte(data, ctx) {
  const message = clip(data.message, 2000);
  if (!message) return fail('invalid-argument', 'Descreva o chamado.');
  const id = await ctx.db.add('support', {
    userId: ctx.uid,
    subject: clip(data.subject, 120) || 'Suporte',
    message,
    orderId: clip(data.orderId, 80) || null,
    status: 'open',
    source: 'plataforma',
    createdAt: ctx.now().toISOString(),
  });
  return ok({ ticketId: id }, 'Chamado aberto.');
}

async function consultarPlanos(data, ctx) {
  const plans = ctx.plans || (await ctx.db.get('config/aiPlans')) || {};
  return ok({ plans: plans.plans || plans });
}

async function cadastrarAvaliacao(data, ctx) {
  const found = await ownOrder(ctx, data.orderId);
  if (found.error) return found.error;
  if (found.role !== 'client' && !ctx.isAdmin) return fail('permission-denied', 'Só o cliente avalia este pedido.');
  const life = found.order.lifecycle;
  const done = life === 'concluido' || life === 'avaliado' || found.order.status === 'completed';
  if (!done) return fail('failed-precondition', 'A avaliação só entra depois da conclusão confirmada.');
  const stars = Number(data.stars);
  if (!(stars >= 1 && stars <= 5)) return fail('invalid-argument', 'A nota vai de 1 a 5.');
  const orderId = clip(data.orderId, 80);
  const existing = await ctx.db.query('reviews', (d) => d.orderId === orderId && d.clientId === ctx.uid);
  if (existing.length) return ok({ already: true, reviewId: existing[0].id }, 'Avaliação já registrada.');
  const id = await ctx.db.add('reviews', {
    orderId,
    clientId: ctx.uid,
    providerId: found.order.providerId,
    stars,
    comment: clip(data.comment, 800),
    createdAt: ctx.now().toISOString(),
  });
  await touchOrder(ctx, orderId, { lifecycle: 'avaliado', reviewed: true }, 'Avaliação registrada');
  return ok({ reviewId: id }, 'Avaliação gravada. A média do profissional é recalculada a partir das avaliações reais.');
}

async function atualizarStatusPedido(data, ctx) {
  const blocked = needConfirm(data, ctx);
  if (blocked) return blocked;
  const to = clip(data.lifecycle, 40);
  if (!lifecycle.STATES.includes(to)) return fail('invalid-argument', 'Estado desconhecido.');
  const found = await ownOrder(ctx, data.orderId);
  if (found.error) return found.error;
  const from = found.order.lifecycle || 'criada';
  if (from === to) return ok({ already: true, lifecycle: to }, 'O pedido já está neste estado.');
  if (!lifecycle.canMove(from, to)) return fail('failed-precondition', 'Transição de status inválida.');
  if (!lifecycle.actorMay(to, found.role)) return fail('permission-denied', 'Seu perfil não pode fazer esta mudança.');
  if (to === 'concluido' && found.order.paymentStatus !== 'paid') {
    return fail('failed-precondition', 'Não é possível concluir sem pagamento confirmado.');
  }
  await touchOrder(ctx, clip(data.orderId, 80), {
    lifecycle: to,
    status: lifecycle.legacyStatus(to),
  }, `Status ${to}`);
  return ok({ orderId: clip(data.orderId, 80), lifecycle: to, paymentStatus: found.order.paymentStatus || 'unpaid' });
}

async function iniciarCobranca(data, ctx) {
  const blocked = needConfirm(data, ctx);
  if (blocked) return blocked;
  const found = await ownOrder(ctx, data.orderId);
  if (found.error) return found.error;
  if (found.role !== 'client' && !ctx.isAdmin) return fail('permission-denied', 'Só o cliente inicia a cobrança.');
  const method = clip(data.method, 20);
  if (!payments.METHODS.includes(method)) return fail('invalid-argument', 'Método inválido. Use pix, cartao ou boleto.');
  const orderId = clip(data.orderId, 80);
  const key = clip(data.idempotencyKey, 80) || `${ctx.uid}:${orderId}:${method}`;
  const prev = await ctx.db.query('paymentIntents', (d) => d.idempotencyKey === key && d.userId === ctx.uid);
  if (prev.length) {
    return ok({ already: true, intentId: prev[0].id, approved: false, status: prev[0].data.status }, 'Cobrança já registrada. Nada foi cobrado de novo.');
  }
  const charge = payments.startCharge({
    PAYMENT_PROVIDER: ctx.paymentProvider || 'mercadopago',
    PAYMENTS_ENABLED: ctx.paymentsEnabled === true,
    MERCADOPAGO_ACCESS_TOKEN: ctx.gatewayConfigured ? 'presente' : '',
  }, { method, orderId });
  const id = await ctx.db.add('paymentIntents', {
    userId: ctx.uid,
    orderId,
    method,
    idempotencyKey: key,
    status: charge.ok ? 'pendente' : 'aguardando_credenciais',
    approved: false,
    amount: found.order.price || null,
    createdAt: ctx.now().toISOString(),
  });
  return {
    ok: false,
    code: charge.code,
    message: charge.message,
    data: { intentId: id, approved: false, status: 'aguardando_credenciais', method, orderId },
  };
}

async function atualizarFeatureFlags(data, ctx) {
  if (!ctx.isAdmin) return fail('permission-denied', 'Apenas admin altera módulos.');
  const flags = data.flags && typeof data.flags === 'object' ? data.flags : null;
  if (!flags) return fail('invalid-argument', 'flags obrigatório.');
  const allowed = ['explorar', 'tia', 'orcamentos', 'agenda', 'pagamentos', 'whatsapp', 'saude', 'chat'];
  const next = {};
  for (const key of allowed) {
    if (typeof flags[key] === 'boolean') next[key] = flags[key];
  }
  await ctx.db.set('config/featureFlags', next, { merge: true });
  return ok({ flags: next }, 'Módulos atualizados.');
}

async function consultarIntegracaoWhatsApp(data, ctx) {
  return ok(whatsapp.describe({
    WHATSAPP_TOKEN: ctx.whatsappConfigured ? 'presente' : '',
    WHATSAPP_PHONE_ID: ctx.whatsappConfigured ? 'presente' : '',
  }));
}

async function excluirMinhaConta(data, ctx) {
  const blocked = needConfirm(data, ctx);
  if (blocked) return blocked;
  const conversations = await ctx.db.query('aiConversations', (d) => d.userId === ctx.uid);
  for (const doc of conversations) await ctx.db.delete(`aiConversations/${doc.id}`);
  const drafts = await ctx.db.query('serviceDrafts', (d) => d.clientId === ctx.uid);
  for (const doc of drafts) await ctx.db.delete(`serviceDrafts/${doc.id}`);
  await ctx.db.set(`users/${ctx.uid}`, {
    deletionRequestedAt: ctx.now().toISOString(),
    status: 'deletion_requested',
  }, { merge: true });
  return ok({
    conversations: conversations.length,
    drafts: drafts.length,
    financialRecordsKept: true,
  }, 'Pedido de exclusão registrado. Conversas e rascunhos foram apagados. Pedidos e pagamentos permanecem pelo prazo legal.');
}

const TOOLS = {
  buscarProfissionais,
  consultarCategorias,
  consultarPerfilProfissional,
  consultarDisponibilidade,
  analisarFotografias,
  criarRascunhoSolicitacao,
  confirmarSolicitacao,
  enviarSolicitacao,
  consultarOrcamentos,
  compararOrcamentos,
  enviarOrcamento,
  aceitarOrcamento,
  consultarAgenda,
  confirmarAgendamento,
  reagendarServico,
  consultarPedido,
  acompanharPedido,
  consultarPagamento,
  consultarHistorico,
  solicitarCancelamento,
  abrirChamadoSuporte,
  consultarPlanos,
  cadastrarAvaliacao,
  atualizarStatusPedido,
  iniciarCobranca,
  atualizarFeatureFlags,
  consultarIntegracaoWhatsApp,
  excluirMinhaConta,
};

const TOOL_NAMES = Object.keys(TOOLS);

async function run(name, data, ctx) {
  if (!ctx || !ctx.uid) return fail('unauthenticated', 'Login obrigatório.');
  if (ctx.enforceRateLimit) {
    try {
      await ctx.enforceRateLimit(ctx.uid, `tool_${name}`, 40, 60 * 1000);
    } catch (_) {
      return fail('resource-exhausted', 'Muitas tentativas. Aguarde um pouco.');
    }
  }
  const fn = TOOLS[name];
  let result;
  if (!fn) result = fail('invalid-argument', 'Ferramenta desconhecida.');
  else {
    try {
      result = await fn(data || {}, ctx);
    } catch (_) {
      result = fail('internal', 'Não foi possível concluir. Tente de novo.');
    }
  }
  if (ctx.db && typeof ctx.db.add === 'function') {
    try {
      await ctx.db.add('platformAudit', {
        uid: ctx.uid,
        tool: name,
        ok: result.ok === true,
        code: result.code,
        at: (ctx.now ? ctx.now() : new Date()).toISOString(),
      });
    } catch (_) {}
  }
  return result;
}

function hasTool(name) {
  return Boolean(TOOLS[name]);
}

module.exports = {
  TOOLS,
  TOOL_NAMES,
  run,
  hasTool,
  PHOTO_DISCLAIMER,
};
