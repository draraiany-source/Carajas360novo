const test = require('node:test');
const assert = require('node:assert/strict');
const { describe, startCharge } = require('./adapter');

test('sem credencial o gateway não aprova', () => {
  const status = describe({});
  assert.equal(status.status, 'aguardando_credenciais');
  assert.equal(status.approved, false);
  const charge = startCharge({}, { method: 'pix', orderId: 'o1' });
  assert.equal(charge.ok, false);
  assert.equal(charge.approved, false);
  assert.equal(charge.code, 'aguardando_credenciais');
});

test('com credencial o adapter ainda não aprova localmente', () => {
  const env = { PAYMENTS_ENABLED: 'true', MERCADOPAGO_ACCESS_TOKEN: 'test-token' };
  const status = describe(env);
  assert.equal(status.status, 'configurado');
  assert.equal(status.approved, false);
  const charge = startCharge(env, { method: 'boleto', orderId: 'o1' });
  assert.equal(charge.approved, false);
  assert.equal(charge.ok, false);
});
