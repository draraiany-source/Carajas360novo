'use strict';

/** Máquina de estados do pedido. O status legado segue em paralelo para o repasse. */

const STATES = [
  'criada',
  'aguardando_orcamentos',
  'orcamentos_recebidos',
  'aceito',
  'aguardando_confirmacao',
  'agendado',
  'a_caminho',
  'iniciado',
  'em_execucao',
  'aguardando_confirmacao_conclusao',
  'concluido',
  'avaliado',
  'cancelado',
  'em_contestacao',
];

const TRANSITIONS = {
  criada: ['aguardando_orcamentos', 'cancelado'],
  aguardando_orcamentos: ['orcamentos_recebidos', 'cancelado'],
  orcamentos_recebidos: ['aceito', 'aguardando_orcamentos', 'cancelado'],
  aceito: ['aguardando_confirmacao', 'agendado', 'cancelado', 'em_contestacao'],
  aguardando_confirmacao: ['agendado', 'cancelado', 'em_contestacao'],
  agendado: ['a_caminho', 'cancelado', 'em_contestacao'],
  a_caminho: ['iniciado', 'cancelado', 'em_contestacao'],
  iniciado: ['em_execucao', 'cancelado', 'em_contestacao'],
  em_execucao: ['aguardando_confirmacao_conclusao', 'cancelado', 'em_contestacao'],
  aguardando_confirmacao_conclusao: ['concluido', 'em_contestacao'],
  concluido: ['avaliado'],
  avaliado: [],
  cancelado: [],
  em_contestacao: ['cancelado', 'em_execucao'],
};

const LEGACY = {
  criada: 'pending',
  aguardando_orcamentos: 'pending',
  orcamentos_recebidos: 'pending',
  aceito: 'accepted',
  aguardando_confirmacao: 'accepted',
  agendado: 'accepted',
  a_caminho: 'inProgress',
  iniciado: 'inProgress',
  em_execucao: 'inProgress',
  aguardando_confirmacao_conclusao: 'inProgress',
  concluido: 'completed',
  avaliado: 'completed',
  cancelado: 'cancelled',
  em_contestacao: 'disputed',
};

const CLIENT_ONLY = new Set([
  'concluido',
  'avaliado',
  'em_contestacao',
]);

const PROVIDER_ONLY = new Set([
  'a_caminho',
  'iniciado',
  'em_execucao',
  'aguardando_confirmacao_conclusao',
]);

function legacyStatus(lifecycle) {
  return LEGACY[lifecycle] || null;
}

function canMove(from, to) {
  return (TRANSITIONS[from] || []).includes(to);
}

function actorMay(to, role) {
  if (CLIENT_ONLY.has(to)) return role === 'client' || role === 'admin';
  if (PROVIDER_ONLY.has(to)) return role === 'provider' || role === 'admin';
  if (to === 'cancelado') return role === 'client' || role === 'provider' || role === 'admin';
  if (to === 'agendado') return role === 'client' || role === 'provider' || role === 'admin';
  return role === 'admin';
}

module.exports = {
  STATES,
  TRANSITIONS,
  legacyStatus,
  canMove,
  actorMay,
};
