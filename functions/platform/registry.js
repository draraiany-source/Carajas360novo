'use strict';

const { TOOL_NAMES, run } = require('./tools');

function withTransaction(firestore, adapter) {
  return {
    get: (path) => adapter.get(path),
    set: (path, data, opts) => adapter.set(path, data, opts),
    add: (col, data) => adapter.add(col, data),
    delete: (path) => adapter.delete(path),
    query: (col, pred, opts) => adapter.query(col, pred, opts),
    async runTransaction(fn) {
      return firestore.runTransaction(async (tx) => fn({
        async get(path) {
          const snap = await tx.get(firestore.doc(path));
          return snap.exists ? snap.data() : null;
        },
        set(path, data, opts = {}) {
          tx.set(firestore.doc(path), data, { merge: Boolean(opts.merge) });
        },
      }));
    },
  };
}

function registerPlatform(exportsObj, deps) {
  for (const name of TOOL_NAMES) {
    exportsObj[name] = deps.functions.region(deps.region).https.onCall(async (data, context) => {
      const auth = deps.requireAuth(context);
      const adapter = deps.adapter();
      const db = withTransaction(deps.firestore, adapter);
      const admin = await deps.isAdmin(auth);
      const user = (await adapter.get(`users/${auth.uid}`)) || {};
      return run(name, data || {}, {
        db,
        uid: auth.uid,
        isAdmin: admin,
        city: user.city || '',
        userName: user.name || '',
        now: () => new Date(),
        notify: deps.notify,
        enforceRateLimit: deps.enforceRateLimit,
        paymentsEnabled: deps.paymentsEnabled(),
        gatewayConfigured: deps.gatewayConfigured(),
        whatsappConfigured: deps.whatsappConfigured ? deps.whatsappConfigured() : false,
        paymentProvider: process.env.PAYMENT_PROVIDER || 'mercadopago',
        actor: 'user',
        plans: null,
      });
    });
  }
}

module.exports = { registerPlatform, withTransaction };
