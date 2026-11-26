'use strict';

/**
 * Adapter de gateway brasileiro. Sem credencial, a resposta é
 * "aguardando_credenciais" e approved permanece false.
 * Este módulo nunca marca um pagamento como aprovado.
 */

const ADAPTERS = {
  mercadopago: { id: 'mercadopago', name: 'Mercado Pago', env: 'MERCADOPAGO_ACCESS_TOKEN' },
  asaas: { id: 'asaas', name: 'Asaas', env: 'ASAAS_API_KEY' },
  pagarme: { id: 'pagarme', name: 'Pagar.me', env: 'PAGARME_API_KEY' },
};

const METHODS = ['pix', 'cartao', 'boleto'];

function describe(env = {}) {
  const id = String(env.PAYMENT_PROVIDER || 'mercadopago');
  const spec = ADAPTERS[id] || ADAPTERS.mercadopago;
  const configured = Boolean(env[spec.env]);
  const enabled = env.PAYMENTS_ENABLED === true || env.PAYMENTS_ENABLED === 'true';
  const ready = configured && enabled;
  return {
    provider: spec.name,
    providerId: spec.id,
    configured,
    enabled,
    ready,
    status: ready ? 'configurado' : 'aguardando_credenciais',
    sandbox: !ready,
    approved: false,
    methods: METHODS,
    message: ready
      ? 'Gateway configurado. A aprovação só entra por webhook assinado.'
      : 'Gateway aguardando credenciais. Nenhum pagamento foi aprovado.',
  };
}

function startCharge(env, input) {
  const status = describe(env);
  if (!status.ready) {
    return {
      ok: false,
      code: 'aguardando_credenciais',
      approved: false,
      message: status.message,
      data: { ...status, method: input.method || null, orderId: input.orderId || null },
    };
  }
  return {
    ok: false,
    code: 'failed-precondition',
    approved: false,
    message: 'A cobrança real continua nos callables generatePix e processCardPayment. Este adapter não aprova pagamento.',
    data: status,
  };
}

module.exports = { ADAPTERS, METHODS, describe, startCharge };
