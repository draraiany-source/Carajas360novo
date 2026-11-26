/**
 * Confirmação explícita. O modelo só propõe; esta função grava depois do toque.
 */

const { SPECIALTIES, HEALTH_CATEGORIES } = require('./tools');

const HEALTH_IDS = new Set([
  ...HEALTH_CATEGORIES,
  ...SPECIALTIES.map((s) => s.id),
  ...SPECIALTIES.map((s) => s.category),
]);

function clip(value, max) {
  return String(value || '').trim().slice(0, max);
}

function isHealthCategory(category, specialty) {
  return HEALTH_IDS.has(String(category || '')) || HEALTH_IDS.has(String(specialty || ''));
}

async function confirmAction(ctx, action) {
  const type = clip(action?.type, 40);
  const payload = action?.payload && typeof action.payload === 'object' ? action.payload : {};
  const actionId = clip(action?.actionId, 80);
  if (!type) return { ok: false, error: 'Ação inválida' };

  if (actionId) {
    const prev = await ctx.db.query('aiAudit', (d) => d.actionId === actionId && d.uid === ctx.uid, { limit: 5 });
    const done = prev.find((d) => d.data && d.data.ok === true);
    if (done) return { ok: true, already: true, result: done.data.result || null };
  }

  let result;
  if (type === 'request_quote') result = await requestQuote(ctx, payload);
  else if (type === 'schedule') result = await schedule(ctx, payload);
  else if (type === 'reschedule') result = await reschedule(ctx, payload);
  else if (type === 'choose_proposal') result = await chooseProposal(ctx, payload);
  else if (type === 'handoff_support') result = await handoff(ctx, payload);
  else if (type === 'open_chat') result = await openChat(ctx, payload);
  else if (type === 'update_profile_draft') result = await updateProfile(ctx, payload);
  else return { ok: false, error: 'Tipo de ação não permitido' };

  await ctx.db.add('aiAudit', {
    uid: ctx.uid,
    actionId: actionId || null,
    type,
    ok: result.ok === true,
    result: result.ok ? { id: result.id || null, kind: result.kind || type } : { error: result.error },
    at: ctx.now().toISOString(),
  });
  return result;
}

async function requestQuote(ctx, payload) {
  const category = clip(payload.category, 40);
  const title = clip(payload.title, 120);
  const description = clip(payload.description, 2000);
  const address = clip(payload.address, 200);
  if (!category || !title || !description) {
    return { ok: false, error: 'Categoria, título e descrição são obrigatórios' };
  }
  const providerId = clip(payload.providerId, 80);
  const orderId = await ctx.db.add('orders', {
    clientId: ctx.uid,
    providerId: providerId || null,
    category,
    title,
    description,
    address,
    urgent: payload.urgent === true,
    whatsappOptIn: payload.whatsappOptIn === true,
    preferredDate: clip(payload.preferredDate, 20) || null,
    preferredTime: clip(payload.preferredTime, 10) || null,
    status: 'pending',
    lifecycle: 'aguardando_orcamentos',
    paymentStatus: 'unpaid',
    payoutProcessed: false,
    payoutStatus: 'none',
    source: 'tia',
    createdAt: ctx.now().toISOString(),
  });
  const requestId = await ctx.db.add('resolveRequests', {
    clientId: ctx.uid,
    clientName: clip(ctx.userName, 80),
    description,
    category,
    city: clip(payload.city || ctx.city, 80),
    address,
    status: 'open',
    proposalCount: 0,
    source: 'tia',
    orderId,
    createdAt: ctx.now().toISOString(),
  });
  if (providerId && ctx.notify) {
    await ctx.notify(providerId, 'Nova solicitação', title, 'order');
  }
  return {
    ok: true,
    kind: 'request_quote',
    id: orderId,
    requestId,
    message: 'Solicitação registrada. Você será avisado quando houver proposta. Nada foi cobrado.',
  };
}

async function schedule(ctx, payload) {
  const providerId = clip(payload.providerId, 80);
  const date = clip(payload.date, 20);
  const time = clip(payload.time, 10);
  const category = clip(payload.category, 40);
  if (!providerId || !date || !time) {
    return { ok: false, error: 'Profissional, data e horário são obrigatórios' };
  }
  const provider = await ctx.db.get(`providers/${providerId}`);
  if (!provider || provider.active !== true || provider.verified !== true) {
    return { ok: false, error: 'Profissional indisponível para agendamento' };
  }
  const specialty = clip(payload.specialty, 40);
  if (isHealthCategory(category, specialty) && provider.registrationVerified !== true) {
    return {
      ok: false,
      error: 'Agendamento de saúde bloqueado: o registro profissional ainda não foi verificado pelo admin.',
    };
  }
  const id = await ctx.db.add('appointments', {
    clientId: ctx.uid,
    providerId,
    providerName: clip(provider.name, 80),
    category,
    specialty: specialty || null,
    date,
    time,
    homeVisit: payload.homeVisit === true,
    notes: clip(payload.notes, 500),
    status: 'requested',
    source: 'tia',
    createdAt: ctx.now().toISOString(),
  });
  if (ctx.notify) {
    await ctx.notify(provider.userId || providerId, 'Pedido de agendamento', `${date} às ${time}`, 'agenda');
  }
  return {
    ok: true,
    kind: 'schedule',
    id,
    message: 'Pedido de horário enviado. Ele só fica confirmado quando o profissional aceitar.',
  };
}

async function reschedule(ctx, payload) {
  const appointmentId = clip(payload.appointmentId, 80);
  const date = clip(payload.date, 20);
  const time = clip(payload.time, 10);
  if (!appointmentId || !date || !time) return { ok: false, error: 'Dados incompletos' };
  const current = await ctx.db.get(`appointments/${appointmentId}`);
  if (!current) return { ok: false, error: 'Agendamento não encontrado' };
  if (current.clientId !== ctx.uid && current.providerId !== ctx.uid && !ctx.isAdmin) {
    return { ok: false, error: 'Sem permissão' };
  }
  await ctx.db.set(`appointments/${appointmentId}`, {
    status: 'reschedule_requested',
    proposedDate: date,
    proposedTime: time,
    updatedAt: ctx.now().toISOString(),
  }, { merge: true });
  return {
    ok: true,
    kind: 'reschedule',
    id: appointmentId,
    message: 'Pedido de reagendamento registrado. O horário anterior permanece até a outra parte aceitar.',
  };
}

async function chooseProposal(ctx, payload) {
  const proposalId = clip(payload.proposalId, 80);
  const requestId = clip(payload.requestId, 80);
  const proposal = await ctx.db.get(`resolveProposals/${proposalId}`);
  const request = await ctx.db.get(`resolveRequests/${requestId}`);
  if (!proposal || !request) return { ok: false, error: 'Proposta ou solicitação não encontrada' };
  if (request.clientId !== ctx.uid && !ctx.isAdmin) return { ok: false, error: 'Sem permissão' };
  if (proposal.requestId !== requestId) return { ok: false, error: 'Proposta não pertence à solicitação' };
  if (request.chosenProposalId && request.chosenProposalId !== proposalId) {
    return { ok: false, error: 'Esta solicitação já tem uma proposta aceita. Nada foi alterado.' };
  }
  if (request.chosenProposalId === proposalId) {
    return { ok: true, already: true, kind: 'choose_proposal', id: proposalId, message: 'Proposta já escolhida.' };
  }
  await ctx.db.set(`resolveProposals/${proposalId}`, { status: 'accepted' }, { merge: true });
  await ctx.db.set(`resolveRequests/${requestId}`, {
    status: 'accepted',
    chosenProposalId: proposalId,
  }, { merge: true });
  return {
    ok: true,
    kind: 'choose_proposal',
    id: proposalId,
    message: 'Proposta marcada como escolhida. Combine o horário na confirmação de agendamento. Nenhum pagamento foi criado.',
  };
}

async function handoff(ctx, payload) {
  if (ctx.handoffEnabled === false) return { ok: false, error: 'Encaminhamento humano desativado pelo admin' };
  const subject = clip(payload.subject, 120) || 'Atendimento da Tia Carajás IA';
  const message = clip(payload.message, 2000);
  if (!message) return { ok: false, error: 'Descreva o que deve ser encaminhado' };
  const id = await ctx.db.add('support', {
    userId: ctx.uid,
    subject,
    message,
    source: 'tia',
    status: 'open',
    createdAt: ctx.now().toISOString(),
  });
  return { ok: true, kind: 'handoff_support', id, message: 'Chamado aberto para uma pessoa do suporte.' };
}

async function openChat(ctx, payload) {
  const providerId = clip(payload.providerId, 80);
  if (!providerId) return { ok: false, error: 'Profissional obrigatório' };
  const ids = [ctx.uid, providerId].sort();
  const roomId = ids.join('_');
  await ctx.db.set(`chatRooms/${roomId}`, {
    participants: ids,
    createdAt: ctx.now().toISOString(),
  }, { merge: true });
  return { ok: true, kind: 'open_chat', id: roomId, message: 'Conversa pronta. A mensagem ainda não foi enviada.' };
}

async function updateProfile(ctx, payload) {
  const provider = await ctx.db.get(`providers/${ctx.uid}`);
  if (!provider) return { ok: false, error: 'Cadastro de prestador não encontrado' };
  const bio = clip(payload.bio, 800);
  const categories = Array.isArray(payload.categories)
    ? payload.categories.map((c) => clip(c, 40)).filter(Boolean).slice(0, 8)
    : null;
  const patch = {};
  if (bio) patch.bio = bio;
  if (categories && categories.length) patch.categories = categories;
  if (!Object.keys(patch).length) return { ok: false, error: 'Nada para atualizar' };
  patch.updatedAt = ctx.now().toISOString();
  await ctx.db.set(`providers/${ctx.uid}`, patch, { merge: true });
  return { ok: true, kind: 'update_profile_draft', id: ctx.uid, message: 'Perfil atualizado com o texto que você confirmou.' };
}

module.exports = { confirmAction, isHealthCategory };
