/**
 * Carajás 360 — Cloud Functions (staging-safe)
 *
 * Pagamentos reais (Mercado Pago) só rodam se:
 *   PAYMENTS_ENABLED=true  E  MERCADOPAGO_ACCESS_TOKEN no env/Secret Manager.
 * Por padrão o gateway real permanece DESLIGADO.
 */
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');
const policy = require('./orderPolicy');
const tia = require('./ai/handlers');

admin.initializeApp();
const db = admin.firestore();

const REGION = 'us-central1';
const PAYMENTS_ENABLED = process.env.PAYMENTS_ENABLED === 'true';
const ENFORCE_APP_CHECK = process.env.ENFORCE_APP_CHECK === 'true';
const ALLOWED_PROFILE_TYPES = ['client', 'provider', 'deliverer', 'company'];

function getMpToken() {
  return process.env.MERCADOPAGO_ACCESS_TOKEN || '';
}

function httpsError(code, message) {
  return new functions.https.HttpsError(code, message);
}

function requireAuth(context) {
  if (ENFORCE_APP_CHECK && !context.app) {
    throw httpsError('failed-precondition', 'App Check obrigatório');
  }
  if (!context.auth || !context.auth.uid) {
    throw httpsError('unauthenticated', 'Login obrigatório');
  }
  return context.auth;
}

async function isAdmin(auth) {
  const t = auth.token || {};
  if (t.admin === true || t.role === 'admin') return true;
  const snap = await db.collection('users').doc(auth.uid).get();
  return snap.exists && snap.data().type === 'admin';
}

async function enforceRateLimit(uid, key, max, windowMs) {
  const ref = db.collection('rateLimits').doc(`${uid}_${key}`);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const now = Date.now();
    const data = snap.data() || {};
    let windowStart = Number(data.windowStart || 0);
    let count = Number(data.count || 0);
    if (now - windowStart > windowMs) {
      windowStart = now;
      count = 0;
    }
    if (count >= max) {
      throw httpsError('resource-exhausted', 'Muitas tentativas. Aguarde um pouco.');
    }
    tx.set(ref, { uid, key, windowStart, count: count + 1, updatedAt: now }, { merge: true });
  });
}

async function notify(userId, title, body, type) {
  if (!userId) return;
  await db.collection('notifications').add({
    userId,
    title: String(title).slice(0, 120),
    body: String(body).slice(0, 500),
    type: type || 'info',
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function canNotifyTarget(callerUid, targetUid) {
  if (callerUid === targetUid) return true;
  const caller = await db.collection('users').doc(callerUid).get();
  if (caller.exists && caller.data().type === 'admin') return true;

  const asClient = await db.collection('orders')
    .where('clientId', '==', callerUid)
    .where('providerId', '==', targetUid)
    .limit(1)
    .get();
  if (!asClient.empty) return true;

  const asProvider = await db.collection('orders')
    .where('clientId', '==', targetUid)
    .where('providerId', '==', callerUid)
    .limit(1)
    .get();
  if (!asProvider.empty) return true;

  const ids = [callerUid, targetUid].sort();
  const room = await db.collection('chatRooms').doc(ids.join('_')).get();
  return room.exists;
}

async function adjustWalletTx(tx, uid, type, amount, description, icon, extra) {
  if (!uid || !(amount > 0)) {
    throw httpsError('invalid-argument', 'Parâmetros de carteira inválidos');
  }
  const walletRef = db.collection('wallets').doc(uid);
  const snap = await tx.get(walletRef);
  const bal = snap.exists ? Number(snap.data().balance || 0) : 0;
  if (type === 'debit' || type === 'withdraw') {
    if (bal < amount) throw httpsError('failed-precondition', 'Saldo insuficiente');
    tx.set(walletRef, { userId: uid, balance: policy.round2(bal - amount) }, { merge: true });
  } else {
    tx.set(walletRef, { userId: uid, balance: policy.round2(bal + amount) }, { merge: true });
  }
  tx.set(db.collection('transactions').doc(), {
    userId: uid,
    type,
    amount,
    description: description || '',
    icon: icon || '💰',
    status: type === 'withdraw' ? 'pending' : 'done',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    ...(extra || {}),
  });
}

function requirePaymentsGateway() {
  if (!PAYMENTS_ENABLED) {
    throw httpsError(
      'failed-precondition',
      'Pagamentos reais desligados neste ambiente (staging).',
    );
  }
  const token = getMpToken();
  if (!token) {
    throw httpsError('failed-precondition', 'Gateway de pagamento não configurado');
  }
  return token;
}

function publicPaymentView(pay, id) {
  return {
    id: String(id),
    status: pay.status || null,
    method: pay.method || null,
    purpose: pay.purpose || null,
    orderId: pay.orderId || null,
    pending: pay.status === 'pending' || pay.status === 'in_process',
  };
}

exports.transitionOrder = functions.region(REGION).https.onCall(async (data, context) => {
  const auth = requireAuth(context);
  const orderId = String(data?.orderId || '');
  const action = String(data?.action || '');
  if (!orderId || !policy.targetStatus(action)) {
    throw httpsError('invalid-argument', 'orderId e action obrigatórios');
  }

  const result = await db.runTransaction(async (tx) => {
    const orderRef = db.collection('orders').doc(orderId);
    const snap = await tx.get(orderRef);
    if (!snap.exists) throw httpsError('not-found', 'Pedido não encontrado');
    const order = snap.data();
    const from = order.status || 'pending';
    const to = policy.targetStatus(action);
    const paymentStatus = order.paymentStatus || 'unpaid';

    if (!policy.actorMayPerform(action, auth.uid, order.clientId, order.providerId || null)) {
      throw httpsError('permission-denied', 'Sem permissão para esta ação');
    }
    if (!policy.isAllowedTransition(from, to)) {
      throw httpsError('failed-precondition', 'Transição de status inválida');
    }

    const updates = {
      status: to,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (action === 'accept') {
      updates.providerId = order.providerId || auth.uid;
      updates.acceptedAt = admin.firestore.FieldValue.serverTimestamp();
      const quoted = Number(data?.price);
      if (!(Number(order.price) > 0) && quoted > 0) {
        updates.price = policy.round2(quoted);
      }
    }
    if (action === 'start') {
      updates.startedAt = admin.firestore.FieldValue.serverTimestamp();
    }
    if (action === 'cancel' || action === 'decline') {
      updates.cancelReason = action === 'decline'
        ? 'Recusado pelo profissional'
        : (data?.reason || 'Cancelado');
    }
    if (action === 'complete') {
      const block = policy.completeBlockReason(from, paymentStatus);
      if (block) {
        throw httpsError(
          'failed-precondition',
          block === 'payment_not_confirmed'
            ? 'Não é possível concluir sem pagamento confirmado'
            : 'Transição de status inválida',
        );
      }
      updates.completedAt = admin.firestore.FieldValue.serverTimestamp();

      if (!order.payoutProcessed) {
        const paymentId = order.transactionId;
        if (!paymentId) {
          throw httpsError('failed-precondition', 'Pagamento não confirmado');
        }
        const paySnap = await tx.get(db.collection('payments').doc(String(paymentId)));
        if (!paySnap.exists) {
          throw httpsError('failed-precondition', 'Pagamento não confirmado');
        }
        const pay = paySnap.data();
        const decision = policy.canPayout({
          status: 'completed',
          paymentStatus,
          payoutProcessed: false,
          providerId: order.providerId,
          price: order.price,
          orderId,
          paymentOrderId: pay.orderId,
          gatewayStatus: pay.status,
          paidAmount: pay.amount,
        });
        if (!decision.ok) {
          throw httpsError('failed-precondition', 'Repasse recusado: ' + decision.reason);
        }
        updates.payoutProcessed = true;
        updates.payoutStatus = 'done';
        updates.payoutAt = admin.firestore.FieldValue.serverTimestamp();
        updates.commission = decision.commission;
        updates.platformFee = decision.commission;
        updates.providerAmount = decision.providerAmount;

        await adjustWalletTx(
          tx, order.providerId, 'credit', decision.providerAmount,
          'Pagamento por serviço concluído', '💰', { orderId },
        );
        tx.set(db.collection('financialAudits').doc(), {
          orderId,
          userId: auth.uid,
          providerId: order.providerId,
          clientId: order.clientId,
          gross: decision.gross,
          fees: decision.commission,
          commission: decision.commission,
          providerAmount: decision.providerAmount,
          gatewayTransactionId: String(paymentId),
          status: 'payout_done',
          payoutProcessed: true,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }

    tx.update(orderRef, updates);
    return {
      ok: true,
      status: to,
      payoutProcessed: updates.payoutProcessed || order.payoutProcessed || false,
    };
  });

  try {
    const after = await db.collection('orders').doc(orderId).get();
    const o = after.data() || {};
    if (action === 'accept' && o.clientId) {
      await notify(o.clientId, '✅ Pedido aceito!', 'Um profissional aceitou seu pedido.', 'order');
    }
    if (action === 'start' && o.clientId) {
      await notify(o.clientId, '🔧 Profissional a caminho!', 'Seu serviço está em andamento.', 'order');
    }
    if ((action === 'cancel' || action === 'decline') && o.clientId && o.clientId !== auth.uid) {
      await notify(o.clientId, '❌ Pedido cancelado', o.cancelReason || 'Pedido cancelado', 'order');
    }
    if (action === 'cancel' && o.providerId && o.providerId !== auth.uid) {
      await notify(o.providerId, '❌ Pedido cancelado', 'O cliente cancelou a solicitação.', 'order');
    }
  } catch (e) {
    console.error('notify after transition', e);
  }
  return result;
});

exports.processPayout = functions.region(REGION).https.onCall(async (data, context) => {
  const auth = requireAuth(context);
  const orderId = String(data?.orderId || '');
  if (!orderId) throw httpsError('invalid-argument', 'orderId obrigatório');

  const adminUser = await isAdmin(auth);
  return db.runTransaction(async (tx) => {
    const orderRef = db.collection('orders').doc(orderId);
    const snap = await tx.get(orderRef);
    if (!snap.exists) throw httpsError('not-found', 'Pedido não encontrado');
    const order = snap.data();
    if (order.clientId !== auth.uid && order.providerId !== auth.uid && !adminUser) {
      throw httpsError('permission-denied', 'Sem permissão');
    }
    if (order.payoutProcessed) {
      return { ok: true, already: true, payoutProcessed: true };
    }
    const paymentId = order.transactionId;
    if (!paymentId) throw httpsError('failed-precondition', 'Pagamento não confirmado');
    const paySnap = await tx.get(db.collection('payments').doc(String(paymentId)));
    if (!paySnap.exists) throw httpsError('failed-precondition', 'Pagamento não confirmado');
    const pay = paySnap.data();
    const decision = policy.canPayout({
      status: order.status,
      paymentStatus: order.paymentStatus || 'unpaid',
      payoutProcessed: false,
      providerId: order.providerId,
      price: order.price,
      orderId,
      paymentOrderId: pay.orderId,
      gatewayStatus: pay.status,
      paidAmount: pay.amount,
    });
    if (!decision.ok) {
      throw httpsError('failed-precondition', 'Repasse recusado: ' + decision.reason);
    }
    tx.update(orderRef, {
      payoutProcessed: true,
      payoutStatus: 'done',
      payoutAt: admin.firestore.FieldValue.serverTimestamp(),
      commission: decision.commission,
      platformFee: decision.commission,
      providerAmount: decision.providerAmount,
    });
    await adjustWalletTx(
      tx, order.providerId, 'credit', decision.providerAmount,
      'Pagamento por serviço concluído', '💰', { orderId },
    );
    tx.set(db.collection('financialAudits').doc(), {
      orderId,
      userId: auth.uid,
      providerId: order.providerId,
      clientId: order.clientId,
      gross: decision.gross,
      fees: decision.commission,
      commission: decision.commission,
      providerAmount: decision.providerAmount,
      gatewayTransactionId: String(paymentId),
      status: 'payout_done',
      payoutProcessed: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { ok: true, already: false, payoutProcessed: true, providerAmount: decision.providerAmount };
  });
});

exports.payOrderWithWallet = functions.region(REGION).https.onCall(async (data, context) => {
  const auth = requireAuth(context);
  const orderId = String(data?.orderId || '');
  if (!orderId) throw httpsError('invalid-argument', 'orderId obrigatório');

  return db.runTransaction(async (tx) => {
    const orderRef = db.collection('orders').doc(orderId);
    const snap = await tx.get(orderRef);
    if (!snap.exists) throw httpsError('not-found', 'Pedido não encontrado');
    const order = snap.data();
    if (order.clientId !== auth.uid) throw httpsError('permission-denied', 'Só o cliente pode pagar');
    if ((order.paymentStatus || 'unpaid') === 'paid') {
      return { ok: true, already: true, paymentStatus: 'paid' };
    }
    const amount = Number(order.price);
    if (!(amount > 0)) throw httpsError('failed-precondition', 'Pedido sem preço definido');
    const paymentId = `wallet_${orderId}`;
    await adjustWalletTx(tx, auth.uid, 'debit', amount, `Pagamento pedido ${orderId}`, '👜', { orderId });
    tx.set(db.collection('payments').doc(paymentId), {
      orderId,
      userId: auth.uid,
      purpose: 'order',
      amount,
      method: 'wallet',
      status: 'approved',
      walletCredited: false,
      externalId: paymentId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.update(orderRef, {
      paymentStatus: 'paid',
      transactionId: paymentId,
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { ok: true, already: false, paymentStatus: 'paid', id: paymentId };
  });
});

exports.generatePix = functions.region(REGION).https.onCall(async (data, context) => {
  const auth = requireAuth(context);
  await enforceRateLimit(auth.uid, 'pix', 8, 60 * 60 * 1000);
  const token = requirePaymentsGateway();

  const purpose = String(data?.purpose || 'order');
  if (!['order', 'wallet_recharge'].includes(purpose)) {
    throw httpsError('invalid-argument', 'purpose inválido');
  }

  let amount;
  let orderId = data?.orderId ? String(data.orderId) : null;
  let description = String(data?.description || 'Pagamento Carajás 360').slice(0, 200);
  const email = String(data?.email || '').trim();

  if (purpose === 'order') {
    if (!orderId) throw httpsError('invalid-argument', 'orderId obrigatório');
    const orderSnap = await db.collection('orders').doc(orderId).get();
    if (!orderSnap.exists) throw httpsError('not-found', 'Pedido não encontrado');
    const order = orderSnap.data();
    if (order.clientId !== auth.uid) throw httpsError('permission-denied', 'Pedido de outro usuário');
    amount = Number(order.price);
    if (!(amount > 0)) throw httpsError('failed-precondition', 'Pedido sem preço definido');
    description = description || order.title || 'Pedido Carajás 360';
  } else {
    amount = Number(data?.amount);
    if (!(amount >= 10) || amount > 5000) {
      throw httpsError('invalid-argument', 'Valor de recarga inválido (R$ 10 a R$ 5.000)');
    }
    orderId = null;
  }

  const platformFee = policy.round2(amount * policy.COMMISSION_RATE);
  const netAmount = policy.round2(amount - platformFee);
  const idempotency = `${auth.uid}:${purpose}:${orderId || 'wallet'}:${Math.floor(Date.now() / 60000)}`;

  const response = await axios.post('https://api.mercadopago.com/v1/payments', {
    transaction_amount: amount,
    description,
    payment_method_id: 'pix',
    payer: { email: email || `${auth.uid}@users.carajas360.invalid` },
  }, {
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      'X-Idempotency-Key': idempotency,
    },
  });

  const { id, status, point_of_interaction } = response.data;
  await db.collection('payments').doc(String(id)).set({
    orderId,
    userId: auth.uid,
    purpose,
    amount,
    platformFee,
    netAmount,
    method: 'pix',
    status: status === 'pending' ? 'pending' : (status || 'processing'),
    walletCredited: false,
    externalId: String(id),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  if (orderId) {
    await db.collection('orders').doc(orderId).update({
      paymentStatus: 'pending',
      transactionId: String(id),
    });
  }

  const qr = point_of_interaction?.transaction_data || {};
  return {
    id: String(id),
    status,
    qr_code: qr.qr_code || null,
    qr_code_base64: qr.qr_code_base64 || null,
  };
});

exports.checkPayment = functions.region(REGION).https.onCall(async (data, context) => {
  const auth = requireAuth(context);
  await enforceRateLimit(auth.uid, 'checkpay', 30, 60 * 60 * 1000);
  const id = String(data?.id || '');
  if (!id) throw httpsError('invalid-argument', 'id obrigatório');

  const payRef = db.collection('payments').doc(id);
  const local = await payRef.get();
  if (!local.exists) throw httpsError('not-found', 'Pagamento não encontrado');
  const localData = local.data();
  if (localData.userId !== auth.uid && !(await isAdmin(auth))) {
    throw httpsError('permission-denied', 'Pagamento de outro usuário');
  }

  if (localData.method === 'wallet' || !PAYMENTS_ENABLED || !getMpToken()) {
    return publicPaymentView(localData, id);
  }

  const response = await axios.get(`https://api.mercadopago.com/v1/payments/${id}`, {
    headers: { Authorization: `Bearer ${getMpToken()}` },
  });
  const status = response.data.status;

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(payRef);
    if (!snap.exists) return;
    const p = snap.data();
    if (status === 'approved' && p.status !== 'approved') {
      tx.update(payRef, {
        status: 'approved',
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      if (p.orderId) {
        tx.update(db.collection('orders').doc(p.orderId), {
          paymentStatus: 'paid',
          transactionId: String(id),
          paidAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
      if (p.purpose === 'wallet_recharge' && p.userId && !p.walletCredited) {
        await adjustWalletTx(tx, p.userId, 'credit', Number(p.amount), 'Recarga via PIX', '⚡', { paymentId: id });
        tx.update(payRef, { walletCredited: true });
      }
    } else if (status && status !== p.status) {
      tx.update(payRef, { status });
    }
  });

  const after = (await payRef.get()).data();
  return publicPaymentView(after, id);
});

exports.processCardPayment = functions.region(REGION).https.onCall(async (data, context) => {
  const auth = requireAuth(context);
  await enforceRateLimit(auth.uid, 'card', 8, 60 * 60 * 1000);
  const token = requirePaymentsGateway();
  const cardToken = String(data?.cardToken || '');
  if (!cardToken) throw httpsError('invalid-argument', 'Token do cartão ausente');

  const orderId = String(data?.orderId || '');
  if (!orderId) throw httpsError('invalid-argument', 'orderId obrigatório');
  const orderSnap = await db.collection('orders').doc(orderId).get();
  if (!orderSnap.exists) throw httpsError('not-found', 'Pedido não encontrado');
  const order = orderSnap.data();
  if (order.clientId !== auth.uid) throw httpsError('permission-denied', 'Pedido de outro usuário');
  const amount = Number(order.price);
  if (!(amount > 0)) throw httpsError('failed-precondition', 'Pedido sem preço definido');

  const platformFee = policy.round2(amount * policy.COMMISSION_RATE);
  const netAmount = policy.round2(amount - platformFee);
  const email = String(data?.email || '').trim();
  const installments = Number(data?.installments || 1);
  const payerDocNumber = data?.payerDocNumber ? String(data.payerDocNumber).replace(/\D/g, '') : undefined;

  const response = await axios.post('https://api.mercadopago.com/v1/payments', {
    transaction_amount: amount,
    description: String(data?.description || order.title || 'Pagamento Carajás 360').slice(0, 200),
    token: cardToken,
    installments: installments >= 1 && installments <= 12 ? installments : 1,
    payer: {
      email: email || `${auth.uid}@users.carajas360.invalid`,
      identification: payerDocNumber ? { type: 'CPF', number: payerDocNumber } : undefined,
    },
  }, {
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      'X-Idempotency-Key': `${auth.uid}:${orderId}:card`,
    },
  });

  const { id, status, status_detail } = response.data;
  await db.collection('payments').doc(String(id)).set({
    orderId,
    userId: auth.uid,
    purpose: 'order',
    amount,
    platformFee,
    netAmount,
    method: 'card',
    status,
    statusDetail: status_detail,
    installments,
    walletCredited: false,
    externalId: String(id),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    ...(status === 'approved' ? { paidAt: admin.firestore.FieldValue.serverTimestamp() } : {}),
  });
  if (status === 'approved') {
    await db.collection('orders').doc(orderId).update({
      paymentStatus: 'paid',
      transactionId: String(id),
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } else {
    await db.collection('orders').doc(orderId).update({
      paymentStatus: 'pending',
      transactionId: String(id),
    });
  }
  return { id: String(id), status, statusDetail: status_detail };
});

const tiaRuntime = {
  requireAuth,
  httpsError,
  isAdmin,
  enforceRateLimit,
  notify,
};

function tiaDb() {
  return tia.bind(db);
}

exports.aiAssistant = functions.region(REGION).https.onCall(async (data, context) => {
  const result = await tia.tiaChat(tiaDb(), data, context, tiaRuntime);
  if (!result.available) {
    throw httpsError('failed-precondition', result.reason || 'IA indisponível');
  }
  return { reply: result.reply, providers: result.providers || [], actions: result.actions || [] };
});

const tiaRun = functions.region(REGION).runWith({ timeoutSeconds: 60, memory: '512MB' });
exports.tiaChat = tiaRun.https.onCall((data, context) => tia.tiaChat(tiaDb(), data, context, tiaRuntime));
exports.tiaEstimate = tiaRun.https.onCall((data, context) => tia.tiaEstimate(tiaDb(), data, context, tiaRuntime));
exports.tiaConfirm = tiaRun.https.onCall((data, context) => tia.tiaConfirm(tiaDb(), data, context, tiaRuntime));
exports.tiaStatus = tiaRun.https.onCall((data, context) => tia.tiaStatus(tiaDb(), data, context, tiaRuntime));
exports.tiaHistory = tiaRun.https.onCall((data, context) => tia.tiaHistory(tiaDb(), data, context, tiaRuntime));
exports.tiaDeleteMyData = tiaRun.https.onCall((data, context) => tia.tiaDeleteMyData(tiaDb(), data, context, tiaRuntime));
exports.tiaAdminGet = tiaRun.https.onCall((data, context) => tia.tiaAdminGet(tiaDb(), data, context, tiaRuntime));
exports.tiaAdminUpdate = tiaRun.https.onCall((data, context) => tia.tiaAdminUpdate(tiaDb(), data, context, tiaRuntime));
exports.tiaAdminDeleteUser = tiaRun.https.onCall((data, context) => tia.tiaAdminDeleteUser(tiaDb(), data, context, tiaRuntime));
exports.tiaAnalyzePhoto = functions.region(REGION).runWith({ timeoutSeconds: 120, memory: '512MB' })
  .https.onCall((data, context) => tia.tiaAnalyzePhoto(tiaDb(), data, context, tiaRuntime));

const { registerPlatform } = require('./platform/registry');
registerPlatform(exports, {
  functions,
  region: REGION,
  firestore: db,
  adapter: () => tiaDb(),
  requireAuth,
  isAdmin,
  enforceRateLimit,
  notify,
  paymentsEnabled: () => PAYMENTS_ENABLED,
  gatewayConfigured: () => Boolean(getMpToken()),
  whatsappConfigured: () => Boolean(process.env.WHATSAPP_TOKEN && process.env.WHATSAPP_PHONE_ID),
});

const { runReminders } = require('./agenda/reminders');
exports.lembretesAgenda = functions.pubsub.schedule('every 60 minutes').onRun(async () => (
  runReminders(tiaDb(), new Date(), notify)
));

exports.walletOp = functions.region(REGION).https.onCall(async (data, context) => {
  const auth = requireAuth(context);
  const op = String(data?.op || '');
  const value = Number(data?.amount);
  if (!['debit', 'withdraw', 'cashback'].includes(op)) {
    throw httpsError('invalid-argument', 'Operação não permitida');
  }
  if (op !== 'cashback' && !(value > 0)) {
    throw httpsError('invalid-argument', 'Valor inválido');
  }

  if (op === 'cashback') {
    const orderId = String(data?.orderId || '');
    if (!orderId) throw httpsError('invalid-argument', 'orderId obrigatório');
    return db.runTransaction(async (tx) => {
      const orderRef = db.collection('orders').doc(orderId);
      const orderSnap = await tx.get(orderRef);
      if (!orderSnap.exists) throw httpsError('not-found', 'Pedido não encontrado');
      const order = orderSnap.data();
      if (order.status !== 'completed') throw httpsError('failed-precondition', 'Pedido não concluído');
      if (order.clientId !== auth.uid && order.providerId !== auth.uid) {
        throw httpsError('permission-denied', 'Sem permissão');
      }
      if (order.cashbackGranted) return { ok: true, already: true };
      const cashback = policy.round2(Number(order.price || 0) * 0.02);
      if (cashback > 0) {
        await adjustWalletTx(
          tx, order.clientId, 'credit', cashback,
          `Cashback: ${order.title || 'Serviço'}`, '🎁', { orderId },
        );
      }
      tx.update(orderRef, { cashbackGranted: true });
      return { ok: true, cashback };
    });
  }

  if (op === 'withdraw' && value < 10) {
    throw httpsError('invalid-argument', 'Saque mínimo R$ 10');
  }
  await db.runTransaction(async (tx) => {
    await adjustWalletTx(
      tx,
      auth.uid,
      op,
      value,
      data?.description || (op === 'withdraw' ? `Saque para ${data?.pixKey || ''}` : ''),
      data?.icon || (op === 'withdraw' ? '📤' : '👜'),
      op === 'withdraw' ? { pixKey: data?.pixKey || null } : {},
    );
  });
  return { ok: true };
});

exports.createNotification = functions.region(REGION).https.onCall(async (data, context) => {
  const auth = requireAuth(context);
  await enforceRateLimit(auth.uid, 'notif', 40, 60 * 60 * 1000);
  const userId = String(data?.userId || '');
  const title = String(data?.title || '');
  const body = String(data?.body || '');
  if (!userId || !title || !body) {
    throw httpsError('invalid-argument', 'Campos obrigatórios ausentes');
  }
  if (!(await canNotifyTarget(auth.uid, userId))) {
    throw httpsError('permission-denied', 'Não é permitido notificar este usuário');
  }
  await notify(userId, title, body, data?.type || 'info');
  return { ok: true };
});

exports.switchProfileType = functions.region(REGION).https.onCall(async (data, context) => {
  const auth = requireAuth(context);
  const next = String(data?.type || '');
  if (!ALLOWED_PROFILE_TYPES.includes(next)) {
    throw httpsError('invalid-argument', 'Tipo de perfil inválido');
  }
  const ref = db.collection('users').doc(auth.uid);
  const snap = await ref.get();
  if (snap.exists && snap.data().type === 'admin') {
    throw httpsError('permission-denied', 'Perfil admin não pode ser alterado por esta operação');
  }
  await ref.set({ type: next, updatedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
  return { ok: true, type: next };
});

exports.sendPushNotification = functions.firestore
  .document('notifications/{notifId}')
  .onCreate(async (snap) => {
    const { userId, title, body } = snap.data();
    const userDoc = await db.collection('users').doc(userId).get();
    const fcmToken = userDoc.data()?.fcmToken;
    if (!fcmToken) return null;
    return admin.messaging().send({
      token: fcmToken,
      notification: { title, body },
      android: { notification: { icon: 'ic_launcher', color: '#0B3D91' } },
      apns: { payload: { aps: { badge: 1, sound: 'default' } } },
    });
  });

exports.updateProviderRating = functions.firestore
  .document('reviews/{reviewId}')
  .onCreate(async (snap) => {
    const { providerId, clientId } = snap.data();
    if (!providerId) return null;
    const reviews = await db.collection('reviews').where('providerId', '==', providerId).get();
    const total = reviews.docs.reduce((sum, d) => sum + (d.data().stars || 0), 0);
    const avg = total / reviews.size;
    await db.collection('providers').doc(providerId).update({
      rating: parseFloat(avg.toFixed(1)),
      totalReviews: reviews.size,
    });
    if (clientId) {
      await db.collection('users').doc(clientId).set(
        { xp: admin.firestore.FieldValue.increment(30) },
        { merge: true },
      );
    }
    return null;
  });

exports.onUserCreateGrantXp = functions.firestore
  .document('users/{uid}')
  .onCreate(async (snap) => {
    const xp = Number(snap.data().xp || 0);
    if (xp > 0) return null;
    await snap.ref.update({ xp: 50 });
    return null;
  });

exports.cleanupOldOrders = functions.pubsub.schedule('every 24 hours').onRun(async () => {
  const cutoff = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
  const oldOrders = await db.collection('orders')
    .where('status', '==', 'pending')
    .where('createdAt', '<', cutoff)
    .get();
  let i = 0;
  let batch = db.batch();
  for (const doc of oldOrders.docs) {
    batch.update(doc.ref, { status: 'cancelled', cancelReason: 'Expirado automaticamente' });
    i += 1;
    if (i >= 400) {
      await batch.commit();
      batch = db.batch();
      i = 0;
    }
  }
  if (i > 0) await batch.commit();
  return null;
});

function gone(_req, res) {
  res.status(410).json({ error: 'Endpoint público desativado. Use callable autenticado.' });
}
exports.generatePixHttp = functions.https.onRequest(gone);
exports.checkPaymentHttp = functions.https.onRequest(gone);
exports.processCardPaymentHttp = functions.https.onRequest(gone);
exports.aiAssistantHttp = functions.https.onRequest(gone);
