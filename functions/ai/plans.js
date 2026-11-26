/**
 * Planos iniciais. Preço comercial fica nulo até o admin gravar.
 * Os tetos são proteção técnica contra custo inesperado da API.
 */

const DEFAULT_PLANS = {
  gratuito: {
    id: 'gratuito',
    label: 'Gratuito',
    priceCents: null,
    monthlyMessages: 30,
    monthlyTokens: 20000,
    monthlyPhotos: 3,
    voiceOnDevice: true,
  },
  premium: {
    id: 'premium',
    label: 'Premium',
    priceCents: null,
    monthlyMessages: 300,
    monthlyTokens: 200000,
    monthlyPhotos: 40,
    voiceOnDevice: true,
  },
  profissional: {
    id: 'profissional',
    label: 'Profissional',
    priceCents: null,
    monthlyMessages: 800,
    monthlyTokens: 500000,
    monthlyPhotos: 120,
    voiceOnDevice: true,
  },
  empresarial: {
    id: 'empresarial',
    label: 'Empresarial',
    priceCents: null,
    monthlyMessages: 3000,
    monthlyTokens: 2000000,
    monthlyPhotos: 400,
    voiceOnDevice: true,
  },
};

const PLAN_ALIASES = {
  free: 'gratuito',
  gratis: 'gratuito',
  gratuito: 'gratuito',
  premium: 'premium',
  pro: 'profissional',
  professional: 'profissional',
  profissional: 'profissional',
  enterprise: 'empresarial',
  empresarial: 'empresarial',
  company: 'empresarial',
};

function normalizePlanId(value) {
  const key = String(value || '').trim().toLowerCase();
  return PLAN_ALIASES[key] || 'gratuito';
}

function mergePlans(stored) {
  const out = {};
  for (const [id, base] of Object.entries(DEFAULT_PLANS)) {
    const override = stored && typeof stored === 'object' ? stored[id] : null;
    out[id] = { ...base, ...(override || {}), id };
    if (override && override.priceCents === undefined) out[id].priceCents = base.priceCents;
  }
  return out;
}

function monthKey(date) {
  const y = date.getUTCFullYear();
  const m = String(date.getUTCMonth() + 1).padStart(2, '0');
  return `${y}-${m}`;
}

/**
 * Estimativas públicas de referência (USD por 1 milhão de tokens).
 * O admin pode substituir em config/ai. Não é fatura.
 */
const DEFAULT_RATES = {
  gemini: { in: 0.1, out: 0.4 },
  openai: { in: 0.15, out: 0.6 },
  anthropic: { in: 3, out: 15 },
};

function estimateUsd(provider, tokensIn, tokensOut, rates) {
  const table = { ...DEFAULT_RATES[provider], ...(rates || {}) };
  const input = Number(tokensIn || 0) * Number(table.in || 0) / 1e6;
  const output = Number(tokensOut || 0) * Number(table.out || 0) / 1e6;
  return Math.round((input + output) * 10000) / 10000;
}

module.exports = {
  DEFAULT_PLANS,
  normalizePlanId,
  mergePlans,
  monthKey,
  DEFAULT_RATES,
  estimateUsd,
};
