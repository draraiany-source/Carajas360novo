'use strict';

/** WhatsApp Cloud API. Sem token, não envia mensagem. */

function describe(env = {}) {
  const configured = Boolean(env.WHATSAPP_TOKEN && env.WHATSAPP_PHONE_ID);
  return {
    provider: 'WhatsApp Cloud API',
    status: configured ? 'configurado' : 'aguardando_credenciais',
    sends: false,
    message: configured
      ? 'Credenciais presentes. O envio ainda não está ligado neste ambiente.'
      : 'Integração aguardando credenciais. Nenhuma mensagem foi enviada.',
  };
}

module.exports = { describe };
