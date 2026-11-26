'use strict';

const COMMISSION_RATE = 0.15;

const SENSITIVE_FIELDS = [
  'price', 'total', 'providerId', 'clientId', 'status',
  'paymentStatus', 'payoutStatus', 'payoutProcessed',
  'commission', 'platformFee', 'providerAmount', 'transactionId',
  'cashbackGranted', 'paidAt', 'payoutAt',
];

const TRANSITIONS = {
  pending: ['accepted', 'cancelled'],
  accepted: ['inProgress', 'cancelled'],
  inProgress: ['completed', 'cancelled', 'disputed'],
  completed: [],
  cancelled: [],
  disputed: ['cancelled'],
};

const ACTIONS = {
  accept: 'accepted',
  start: 'inProgress',
  complete: 'completed',
  cancel: 'cancelled',
  decline: 'cancelled',
  dispute: 'disputed',
};

function round2(n) {
  return Math.round(Number(n) * 100) / 100;
}

function isAllowedTransition(from, to) {
  return (TRANSITIONS[from] || []).includes(to);
}

function targetStatus(action) {
  return ACTIONS[action] || null;
}

function actorMayPerform(action, uid, clientId, providerId) {
  const isClient = uid === clientId;
  const isProvider = Boolean(providerId) && uid === providerId;
  switch (action) {
    case 'accept':
      return !providerId || uid === providerId;
    case 'start':
    case 'decline':
      return isProvider;
    case 'complete':
    case 'dispute':
    case 'cancel':
      return isClient || isProvider;
    default:
      return false;
  }
}

function completeBlockReason(currentStatus, paymentStatus) {
  if (currentStatus !== 'inProgress') return 'invalid_transition';
  if (paymentStatus !== 'paid') return 'payment_not_confirmed';
  return null;
}

function canPayout({
  status,
  paymentStatus,
  payoutProcessed,
  providerId,
  price,
  orderId,
  paymentOrderId,
  gatewayStatus,
  paidAmount,
}) {
  if (payoutProcessed) return { ok: false, reason: 'already_processed' };
  if (status !== 'completed') return { ok: false, reason: 'order_not_completed' };
  const paid = paymentStatus === 'paid' || gatewayStatus === 'approved';
  if (!paid) return { ok: false, reason: 'payment_not_confirmed' };
  if (!providerId) return { ok: false, reason: 'missing_provider' };
  const gross = Number(price);
  if (!(gross > 0)) return { ok: false, reason: 'invalid_price' };
  if (paymentOrderId && paymentOrderId !== orderId) {
    return { ok: false, reason: 'payment_order_mismatch' };
  }
  if (paidAmount != null && Math.abs(Number(paidAmount) - gross) > 0.009) {
    return { ok: false, reason: 'amount_mismatch' };
  }
  const commission = round2(gross * COMMISSION_RATE);
  const providerAmount = round2(gross - commission);
  return { ok: true, gross, commission, providerAmount };
}

module.exports = {
  COMMISSION_RATE,
  SENSITIVE_FIELDS,
  TRANSITIONS,
  ACTIONS,
  round2,
  isAllowedTransition,
  targetStatus,
  actorMayPerform,
  completeBlockReason,
  canPayout,
};
