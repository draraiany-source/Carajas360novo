/**
 * Ferramentas executadas só no backend, sobre o Firestore.
 * Nenhuma delas grava contratação. propose_action apenas descreve o botão.
 */

const HEALTH_CATEGORIES = new Set([
  'medico', 'enfermeiro', 'fisioterapeuta', 'psicologo', 'nutricionista', 'home_care', 'odontologia',
]);

const SPECIALTIES = [
  { id: 'pediatria', name: 'Pediatria', category: 'medico' },
  { id: 'clinica_geral', name: 'Clínica Geral', category: 'medico' },
  { id: 'ginecologia', name: 'Ginecologia', category: 'medico' },
  { id: 'cardiologia', name: 'Cardiologia', category: 'medico' },
  { id: 'neurologia', name: 'Neurologia', category: 'medico' },
  { id: 'psicologia', name: 'Psicologia', category: 'psicologo' },
  { id: 'nutricao', name: 'Nutrição', category: 'nutricionista' },
  { id: 'fisioterapia', name: 'Fisioterapia', category: 'fisioterapeuta' },
  { id: 'odontologia', name: 'Odontologia', category: 'odontologia' },
  { id: 'exames', name: 'Exames e Laboratórios', category: 'medico' },
];

const { publicProfessions } = require('../platform/catalogo');

const CATEGORIES = publicProfessions();

const ACTION_TYPES = new Set([
  'request_quote',
  'schedule',
  'reschedule',
  'choose_proposal',
  'handoff_support',
  'open_chat',
  'update_profile_draft',
]);

function clip(value, max) {
  const text = String(value || '').trim();
  return text.length > max ? text.slice(0, max) : text;
}

function publicProvider(doc) {
  const d = doc.data || {};
  const council = clip(d.council, 20);
  const registrationNumber = clip(d.registrationNumber, 40);
  const verified = d.registrationVerified === true;
  return {
    id: doc.id,
    name: clip(d.name, 80),
    categories: Array.isArray(d.categories) ? d.categories.map((c) => clip(c, 40)).slice(0, 8) : [],
    specialties: Array.isArray(d.specialties) ? d.specialties.map((c) => clip(c, 40)).slice(0, 8) : [],
    city: clip(d.city, 80),
    rating: typeof d.rating === 'number' ? d.rating : 0,
    totalReviews: Number(d.totalReviews || 0),
    verified: d.verified === true,
    active: d.active === true,
    minPrice: typeof d.minPrice === 'number' ? d.minPrice : null,
    modalities: Array.isArray(d.modalities) ? d.modalities.slice(0, 4) : [],
    council: council || null,
    registrationNumber: registrationNumber || null,
    registrationVerified: verified,
    registrationLabel: registrationNumber
      ? (verified
        ? `${council || 'Registro'} ${registrationNumber} (verificado)`
        : `${council || 'Registro'} informado, aguardando verificação do admin`)
      : 'Registro profissional não informado',
    availabilityPublished: Array.isArray(d.availabilitySlots) && d.availabilitySlots.length > 0,
    availableToday: d.availableToday === true,
  };
}

function toolSchemas() {
  const platform = require('../platform/tools');
  const extras = platform.TOOL_NAMES.map((name) => ({
    name,
    description: 'Operação real da plataforma. O modelo não confirma contratação, cobrança nem agendamento: isso só acontece com o toque da pessoa.',
    parameters: { type: 'object', properties: { confirmed: { type: 'boolean' } } },
  }));
  return [
    {
      name: 'search_professionals',
      description: 'Busca profissionais cadastrados, ativos e verificados. Não inventa resultados.',
      parameters: {
        type: 'object',
        properties: {
          query: { type: 'string' },
          category: { type: 'string' },
          specialty: { type: 'string' },
          city: { type: 'string' },
          healthOnly: { type: 'boolean' },
        },
      },
    },
    {
      name: 'get_availability',
      description: 'Lê a agenda publicada e os horários já ocupados. Não cria horários.',
      parameters: {
        type: 'object',
        properties: { providerId: { type: 'string' }, date: { type: 'string' } },
        required: ['providerId'],
      },
    },
    {
      name: 'get_my_orders',
      description: 'Lista pedidos do usuário autenticado (como cliente ou prestador).',
      parameters: {
        type: 'object',
        properties: { role: { type: 'string', enum: ['client', 'provider'] } },
      },
    },
    {
      name: 'get_order',
      description: 'Detalhe de um pedido do próprio usuário, inclusive pagamento se estiver gravado.',
      parameters: {
        type: 'object',
        properties: { orderId: { type: 'string' } },
        required: ['orderId'],
      },
    },
    {
      name: 'list_proposals',
      description: 'Propostas reais de uma solicitação do cliente.',
      parameters: {
        type: 'object',
        properties: { requestId: { type: 'string' } },
        required: ['requestId'],
      },
    },
    {
      name: 'list_categories',
      description: 'Categorias e especialidades reconhecidas pela plataforma.',
      parameters: { type: 'object', properties: {} },
    },
    {
      name: 'get_plans',
      description: 'Planos e tetos configurados pelo admin. Preço nulo significa não publicado.',
      parameters: { type: 'object', properties: {} },
    },
    {
      name: 'search_knowledge',
      description: 'Artigos da base de conhecimento publicados pelo admin.',
      parameters: {
        type: 'object',
        properties: { query: { type: 'string' } },
        required: ['query'],
      },
    },
    {
      name: 'estimate_price',
      description: 'Faixa de preço só com pedidos concluídos reais da categoria. Sem amostra suficiente, recusa.',
      parameters: {
        type: 'object',
        properties: { category: { type: 'string' } },
        required: ['category'],
      },
    },
    {
      name: 'propose_action',
      description: 'Propõe uma ação para o usuário confirmar na tela. Não grava nada.',
      parameters: {
        type: 'object',
        properties: {
          type: { type: 'string' },
          label: { type: 'string' },
          payload: { type: 'object' },
        },
        required: ['type', 'label'],
      },
    },
  ].concat(extras);
}

function orderView(doc) {
  const d = doc.data || {};
  return {
    id: doc.id,
    title: clip(d.title, 120),
    category: clip(d.category, 40),
    status: clip(d.status, 40),
    paymentStatus: clip(d.paymentStatus, 40) || null,
    price: typeof d.price === 'number' ? d.price : null,
    address: clip(d.address, 160),
    providerId: d.providerId || null,
    clientId: d.clientId || null,
    description: clip(d.description, 400),
  };
}

async function executeTool(name, args, ctx) {
  const a = args && typeof args === 'object' ? args : {};
  switch (name) {
    case 'search_professionals':
      return searchProfessionals(a, ctx);
    case 'get_availability':
      return getAvailability(a, ctx);
    case 'get_my_orders':
      return getMyOrders(a, ctx);
    case 'get_order':
      return getOrder(a, ctx);
    case 'list_proposals':
      return listProposals(a, ctx);
    case 'list_categories':
      return { categories: CATEGORIES, specialties: SPECIALTIES };
    case 'get_plans':
      return { plans: ctx.plans };
    case 'search_knowledge':
      return searchKnowledge(a, ctx);
    case 'estimate_price':
      return estimatePrice(a, ctx);
    case 'propose_action':
      return proposeAction(a);
    default: {
      const platform = require('../platform/tools');
      if (platform.hasTool(name)) {
        return platform.run(name, a, {
          ...ctx,
          actor: 'model',
          now: ctx.now || (() => new Date()),
          userName: ctx.userName || '',
        });
      }
      return { error: 'Ferramenta desconhecida' };
    }
  }
}

async function searchProfessionals(args, ctx) {
  const docs = await ctx.db.query('providers', (d) => d.active === true && d.verified === true, {
    where: [['active', '==', true], ['verified', '==', true]],
    orderBy: ['rating', 'desc'],
    limit: 40,
  });
  const query = clip(args.query, 80).toLowerCase();
  const category = clip(args.category, 40).toLowerCase();
  const specialty = clip(args.specialty, 40).toLowerCase();
  const city = clip(args.city || ctx.city || '', 80).toLowerCase();
  const healthOnly = args.healthOnly === true;
  const matched = docs.filter((doc) => {
    const d = doc.data || {};
    const cats = (d.categories || []).map((c) => String(c).toLowerCase());
    const specs = (d.specialties || []).map((c) => String(c).toLowerCase());
    if (healthOnly && !cats.some((c) => HEALTH_CATEGORIES.has(c)) && specs.length === 0) return false;
    if (category && !cats.includes(category)) return false;
    if (specialty && !specs.includes(specialty)) return false;
    if (city && String(d.city || '').toLowerCase() !== city) return false;
    if (query) {
      const blob = `${d.name || ''} ${(d.bio || '')} ${cats.join(' ')} ${specs.join(' ')}`.toLowerCase();
      if (!blob.includes(query)) return false;
    }
    return true;
  }).slice(0, 8);
  return {
    count: matched.length,
    cityFilter: city || null,
    note: matched.length === 0
      ? 'Nenhum profissional cadastrado corresponde aos filtros. Não há sugestão substituta.'
      : 'Resultados limitados a cadastros ativos e verificados.',
    providers: matched.map(publicProvider),
  };
}

async function getAvailability(args, ctx) {
  const providerId = clip(args.providerId, 80);
  const provider = await ctx.db.get(`providers/${providerId}`);
  if (!provider) return { published: false, slots: [], busy: [], note: 'Profissional não encontrado.' };
  const slots = Array.isArray(provider.availabilitySlots) ? provider.availabilitySlots.slice(0, 40) : [];
  const appointments = await ctx.db.query('appointments', (d) => d.providerId === providerId, {
    where: [['providerId', '==', providerId]],
    limit: 30,
  });
  const date = clip(args.date, 20);
  const busy = appointments
    .map((doc) => doc.data || {})
    .filter((d) => !date || String(d.date || '') === date)
    .filter((d) => ['scheduled', 'requested', 'reschedule_requested'].includes(d.status))
    .map((d) => ({ date: d.date || null, time: d.time || null, status: d.status || null }));
  return {
    published: slots.length > 0,
    slots,
    busy,
    availableToday: provider.availableToday === true,
    note: slots.length === 0
      ? 'Este profissional ainda não publicou horários. Não trate nenhum horário como livre.'
      : 'Horários publicados pelo profissional. Ocupados vêm dos agendamentos gravados.',
  };
}

async function getMyOrders(args, ctx) {
  const role = args.role === 'provider' ? 'provider' : 'client';
  const field = role === 'provider' ? 'providerId' : 'clientId';
  const docs = await ctx.db.query('orders', (d) => d[field] === ctx.uid, {
    where: [[field, '==', ctx.uid]],
    orderBy: ['createdAt', 'desc'],
    limit: 20,
  });
  return { role, orders: docs.map(orderView) };
}

async function getOrder(args, ctx) {
  const order = await ctx.db.get(`orders/${clip(args.orderId, 80)}`);
  if (!order) return { error: 'Pedido não encontrado' };
  if (order.clientId !== ctx.uid && order.providerId !== ctx.uid && !ctx.isAdmin) {
    return { error: 'Sem permissão para este pedido' };
  }
  return { order: orderView({ id: clip(args.orderId, 80), data: order }) };
}

async function listProposals(args, ctx) {
  const requestId = clip(args.requestId, 80);
  const request = await ctx.db.get(`resolveRequests/${requestId}`);
  if (!request) return { error: 'Solicitação não encontrada', proposals: [] };
  if (request.clientId !== ctx.uid && !ctx.isAdmin) {
    return { error: 'Sem permissão', proposals: [] };
  }
  const docs = await ctx.db.query('resolveProposals', (d) => d.requestId === requestId, {
    where: [['requestId', '==', requestId]],
    limit: 20,
  });
  return {
    proposals: docs.map((doc) => {
      const d = doc.data || {};
      return {
        id: doc.id,
        requestId,
        providerId: d.providerId || null,
        providerName: clip(d.providerName, 80),
        price: typeof d.price === 'number' ? d.price : null,
        message: clip(d.message, 400),
        status: clip(d.status, 40),
      };
    }),
  };
}

async function searchKnowledge(args, ctx) {
  const query = clip(args.query, 80).toLowerCase();
  const docs = await ctx.db.query('aiKnowledge', (d) => d.active !== false, { limit: 40 });
  const hits = docs.filter((doc) => {
    const d = doc.data || {};
    const blob = `${d.title || ''} ${d.body || ''} ${(d.tags || []).join(' ')}`.toLowerCase();
    return query && blob.includes(query);
  }).slice(0, 4).map((doc) => ({
    id: doc.id,
    title: clip(doc.data.title, 120),
    body: clip(doc.data.body, 800),
  }));
  return {
    articles: hits,
    note: hits.length === 0 ? 'Nenhum artigo da base cobre essa pergunta.' : 'Texto publicado pelo admin.',
  };
}

async function estimatePrice(args, ctx) {
  const category = clip(args.category, 40);
  const docs = await ctx.db.query('orders', (d) => d.category === category && d.status === 'completed' && typeof d.price === 'number', {
    where: [['category', '==', category]],
    limit: 80,
  });
  const prices = docs.map((d) => d.data.price).filter((n) => n > 0).sort((a, b) => a - b);
  if (prices.length < 5) {
    return {
      sufficient: false,
      estimateAllowed: false,
      sampleSize: prices.length,
      message: 'Sem dados suficientes de pedidos concluídos nesta categoria para estimar preço.',
    };
  }
  const mid = prices[Math.floor(prices.length / 2)];
  return {
    sufficient: true,
    estimateAllowed: true,
    sampleSize: prices.length,
    min: prices[0],
    median: mid,
    max: prices[prices.length - 1],
    message: `Com base em ${prices.length} pedidos concluídos de ${category}: mínimo ${prices[0]}, mediana ${mid}, máximo ${prices[prices.length - 1]}. É histórico, não orçamento.`,
  };
}

function proposeAction(args) {
  const type = clip(args.type, 40);
  if (!ACTION_TYPES.has(type)) return { error: 'Tipo de ação não permitido' };
  const payload = args.payload && typeof args.payload === 'object' ? args.payload : {};
  return {
    proposed: true,
    action: {
      type,
      label: clip(args.label, 80) || 'Confirmar',
      payload,
      requiresConfirmation: true,
    },
  };
}

module.exports = {
  CATEGORIES,
  SPECIALTIES,
  HEALTH_CATEGORIES,
  ACTION_TYPES,
  toolSchemas,
  executeTool,
  publicProvider,
  estimatePrice,
};
