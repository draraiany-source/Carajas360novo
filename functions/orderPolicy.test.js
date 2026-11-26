'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const policy = require('./orderPolicy');

describe('máquina de estados', () => {
  it('aceita apenas transições explícitas', () => {
    assert.equal(policy.isAllowedTransition('pending', 'accepted'), true);
    assert.equal(policy.isAllowedTransition('pending', 'completed'), false);
    assert.equal(policy.isAllowedTransition('accepted', 'inProgress'), true);
    assert.equal(policy.isAllowedTransition('inProgress', 'completed'), true);
    assert.equal(policy.isAllowedTransition('completed', 'pending'), false);
    assert.equal(policy.isAllowedTransition('cancelled', 'accepted'), false);
  });

  it('não deixa cliente/prestador pular para completed a partir de pending', () => {
    assert.equal(policy.isAllowedTransition('pending', 'completed'), false);
    assert.equal(policy.isAllowedTransition('accepted', 'completed'), false);
  });
});

describe('ações por ator', () => {
  it('accept só pelo prestador designado (ou se ainda vazio)', () => {
    assert.equal(policy.actorMayPerform('accept', 'p1', 'c1', null), true);
    assert.equal(policy.actorMayPerform('accept', 'p1', 'c1', 'p1'), true);
    assert.equal(policy.actorMayPerform('accept', 'p2', 'c1', 'p1'), false);
  });

  it('start só pelo prestador', () => {
    assert.equal(policy.actorMayPerform('start', 'p1', 'c1', 'p1'), true);
    assert.equal(policy.actorMayPerform('start', 'c1', 'c1', 'p1'), false);
  });
});

describe('concluir sem pagamento deve falhar', () => {
  it('bloqueia complete se paymentStatus != paid', () => {
    assert.equal(
      policy.completeBlockReason('inProgress', 'unpaid'),
      'payment_not_confirmed',
    );
    assert.equal(
      policy.completeBlockReason('inProgress', 'pending'),
      'payment_not_confirmed',
    );
    assert.equal(policy.completeBlockReason('inProgress', 'paid'), null);
    assert.equal(policy.completeBlockReason('pending', 'paid'), 'invalid_transition');
  });
});

describe('payout', () => {
  const base = {
    status: 'completed',
    paymentStatus: 'paid',
    payoutProcessed: false,
    providerId: 'p1',
    price: 100,
    orderId: 'o1',
    paymentOrderId: 'o1',
    gatewayStatus: 'approved',
    paidAmount: 100,
  };

  it('payout válido calcula comissão 15%', () => {
    const r = policy.canPayout(base);
    assert.equal(r.ok, true);
    assert.equal(r.commission, 15);
    assert.equal(r.providerAmount, 85);
  });

  it('segunda execução é idempotente (already_processed)', () => {
    const r = policy.canPayout({ ...base, payoutProcessed: true });
    assert.equal(r.ok, false);
    assert.equal(r.reason, 'already_processed');
  });

  it('sem pagamento confirmado falha', () => {
    const r = policy.canPayout({
      ...base,
      paymentStatus: 'unpaid',
      gatewayStatus: 'pending',
    });
    assert.equal(r.ok, false);
    assert.equal(r.reason, 'payment_not_confirmed');
  });

  it('price diferente do valor pago falha', () => {
    const r = policy.canPayout({ ...base, paidAmount: 1 });
    assert.equal(r.ok, false);
    assert.equal(r.reason, 'amount_mismatch');
  });

  it('payment de outro pedido falha', () => {
    const r = policy.canPayout({ ...base, paymentOrderId: 'other' });
    assert.equal(r.ok, false);
    assert.equal(r.reason, 'payment_order_mismatch');
  });

  it('providerId vazio falha', () => {
    const r = policy.canPayout({ ...base, providerId: '' });
    assert.equal(r.ok, false);
    assert.equal(r.reason, 'missing_provider');
  });
});

describe('campos sensíveis', () => {
  it('inclui price, providerId, status e payoutProcessed', () => {
    for (const f of ['price', 'providerId', 'status', 'payoutProcessed', 'clientId']) {
      assert.ok(policy.SENSITIVE_FIELDS.includes(f), f);
    }
  });
});
