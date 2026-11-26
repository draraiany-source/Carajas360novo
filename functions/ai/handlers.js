/**
 * Callables da Tia Carajás IA. Segredos só em process.env / Secret Manager.
 */

const { runChat, runPhoto, estimateDirect, loadConfig, INTRO } = require('./orchestrator');
const { confirmAction } = require('./actions');
const { CATEGORIES } = require('./tools');
const { keysPresent } = require('./providers');
const { adminDb } = require('./firestore');
const { mergePlans, monthKey, normalizePlanId } = require('./plans');

const MAX_IMAGE_BYTES = 1.2 * 1024 * 1024;

function depsOf(db, helpers, context) {
  const auth = helpers.requireAuth(context);
  return { auth, env: aiEnv(), fetchImpl: helpers.fetchImpl || fetch };
}

function aiEnv() {
  return {
    GEMINI_API_KEY: process.env.GEMINI_API_KEY || '',
    OPENAI_API_KEY: process.env.OPENAI_API_KEY || '',
    OPENAI_BASE_URL: process.env.OPENAI_BASE_URL || '',
    ANTHROPIC_API_KEY: process.env.ANTHROPIC_API_KEY || '',
  };
}

async function tiaChat(db, data, context, helpers) {
  const { auth, env, fetchImpl } = depsOf(db, helpers, context);
  await helpers.enforceRateLimit(auth.uid, 'tia', 20, 60 * 1000);
  const admin = await helpers.isAdmin(auth);
  return runChat({
    db,
    env,
    fetchImpl,
    uid: auth.uid,
    data,
    isAdmin: admin,
    now: () => new Date(),
  });
}

async function tiaAnalyzePhoto(db, data, context, helpers) {
  const { auth, env, fetchImpl } = depsOf(db, helpers, context);
  await helpers.enforceRateLimit(auth.uid, 'tia_photo', 8, 60 * 60 * 1000);
  const image = decodeImage(data);
  return runPhoto({
    db,
    env,
    fetchImpl,
    uid: auth.uid,
    image,
    note: data?.note,
    categoryIds: CATEGORIES.map((c) => c.id),
    now: () => new Date(),
  });
}

function decodeImage(data) {
  const mimeType = String(data?.mimeType || 'image/jpeg');
  if (!/^image\/(jpeg|png|webp)$/.test(mimeType)) {
    return null;
  }
  const raw = String(data?.imageBase64 || '');
  if (!raw) return null;
  const cleaned = raw.replace(/^data:image\/\w+;base64,/, '');
  let bytes;
  try { bytes = Buffer.from(cleaned, 'base64'); } catch (_) { return null; }
  if (!bytes.length || bytes.length > MAX_IMAGE_BYTES) return null;
  return { mimeType, data: cleaned };
}

async function tiaEstimate(db, data, context, helpers) {
  const { auth } = depsOf(db, helpers, context);
  await helpers.enforceRateLimit(auth.uid, 'tia_estimate', 20, 60 * 60 * 1000);
  const result = await estimateDirect(db, String(data?.category || ''));
  return { available: true, ...result };
}

async function tiaConfirm(db, data, context, helpers) {
  const { auth } = depsOf(db, helpers, context);
  await helpers.enforceRateLimit(auth.uid, 'tia_confirm', 30, 60 * 60 * 1000);
  const user = (await db.get(`users/${auth.uid}`)) || {};
  const config = (await db.get('config/ai')) || {};
  return confirmAction({
    db,
    uid: auth.uid,
    city: user.city || '',
    userName: user.name || '',
    isAdmin: await helpers.isAdmin(auth),
    now: () => new Date(),
    handoffEnabled: config.handoffEnabled !== false,
    notify: (userId, title, body, type) => helpers.notify(userId, title, body, type),
  }, data || {});
}

async function tiaStatus(db, data, context, helpers) {
  const { auth, env } = depsOf(db, helpers, context);
  const loaded = await loadConfig(db);
  const user = (await db.get(`users/${auth.uid}`)) || {};
  const month = monthKey(new Date());
  const planId = normalizePlanId(user.plan);
  const plan = loaded.plans[planId] || loaded.plans.gratuito;
  const usage = (await db.get(`aiUsage/${auth.uid}_${month}`)) || {};
  return {
    intro: loaded.config.greeting || INTRO,
    enabled: loaded.config.enabled !== false,
    killSwitch: loaded.config.killSwitch === true,
    provider: loaded.config.provider || 'auto',
    keys: keysPresent(env),
    plan: planId,
    plans: loaded.plans,
    usage: {
      month,
      messages: Number(usage.messages || 0),
      tokens: Number(usage.tokens || 0),
      photos: Number(usage.photos || 0),
      messageLimit: plan ? plan.monthlyMessages : null,
      tokenLimit: plan ? plan.monthlyTokens : null,
      photoLimit: plan ? plan.monthlyPhotos : null,
    },
    global: {
      tokens: Number(loaded.config.spentTokens || 0),
      tokenCap: Number(loaded.config.monthlyTokenCap || 0) || null,
    },
  };
}

async function tiaHistory(db, data, context, helpers) {
  const { auth } = depsOf(db, helpers, context);
  const docs = await db.query('aiConversations', (d) => d.userId === auth.uid, {
    where: [['userId', '==', auth.uid]],
    limit: 20,
  });
  docs.sort((a, b) => String(b.data.updatedAt || '').localeCompare(String(a.data.updatedAt || '')));
  const latest = docs[0];
  return {
    conversationId: latest ? latest.id : null,
    messages: latest ? (latest.data.messages || []).slice(-30) : [],
  };
}

async function tiaDeleteMyData(db, data, context, helpers) {
  const { auth } = depsOf(db, helpers, context);
  const conversations = await db.query('aiConversations', (d) => d.userId === auth.uid, {
    where: [['userId', '==', auth.uid]],
    limit: 100,
  });
  let removed = 0;
  for (const doc of conversations) {
    await db.delete(`aiConversations/${doc.id}`);
    removed += 1;
  }
  await db.add('aiAudit', {
    uid: auth.uid,
    type: 'delete_my_data',
    ok: true,
    removed,
    at: new Date().toISOString(),
  });
  return { ok: true, removed };
}

async function tiaAdminGet(db, data, context, helpers) {
  const { auth, env } = depsOf(db, helpers, context);
  if (!(await helpers.isAdmin(auth))) {
    throw helpers.httpsError('permission-denied', 'Apenas admin');
  }
  const loaded = await loadConfig(db);
  const errors = await db.query('aiAudit', (d) => d.type === 'error', { limit: 20 });
  const handoffs = await db.query('aiAudit', (d) => d.type === 'handoff_support' || d.result?.kind === 'handoff_support', { limit: 20 });
  const orders = await db.query('orders', (d) => d.source === 'tia', { limit: 50 });
  return {
    config: publicConfig(loaded.config),
    plans: loaded.plans,
    keys: keysPresent(env),
    usage: {
      month: loaded.config.monthKey || null,
      tokens: Number(loaded.config.spentTokens || 0),
      estimatedUsd: Number(loaded.config.spentUsdEstimate || 0),
    },
    counts: {
      errors: errors.length,
      handoffs: handoffs.length,
      ordersFromAi: orders.length,
    },
    recentErrors: errors.slice(0, 8).map((d) => ({
      at: d.data.at || null,
      message: d.data.message || '',
    })),
  };
}

async function tiaAdminUpdate(db, data, context, helpers) {
  const { auth } = depsOf(db, helpers, context);
  if (!(await helpers.isAdmin(auth))) {
    throw helpers.httpsError('permission-denied', 'Apenas admin');
  }
  const patch = data?.config && typeof data.config === 'object' ? data.config : {};
  const allowed = [
    'enabled', 'provider', 'geminiModel', 'openaiModel', 'openaiBaseUrl', 'anthropicModel',
    'killSwitch', 'monthlyTokenCap', 'monthlyUsdBudget', 'retentionDays', 'greeting', 'handoffEnabled',
  ];
  const next = {};
  for (const key of allowed) {
    if (patch[key] !== undefined) next[key] = patch[key];
  }
  if (JSON.stringify(patch).toLowerCase().includes('api_key') || patch.secret || patch.token) {
    throw helpers.httpsError('invalid-argument', 'Segredos não são gravados no Firestore');
  }
  await db.set('config/ai', next, { merge: true });
  if (data?.plans && typeof data.plans === 'object') {
    const plans = mergePlans(data.plans);
    await db.set('config/aiPlans', { plans }, { merge: false });
  }
  if (data?.knowledge && data.knowledge.title && data.knowledge.body) {
    await db.add('aiKnowledge', {
      title: String(data.knowledge.title).slice(0, 120),
      body: String(data.knowledge.body).slice(0, 4000),
      tags: Array.isArray(data.knowledge.tags) ? data.knowledge.tags.slice(0, 8) : [],
      active: true,
      updatedAt: new Date().toISOString(),
    });
  }
  await db.add('aiAudit', {
    uid: auth.uid,
    type: 'admin_update',
    ok: true,
    at: new Date().toISOString(),
  });
  return { ok: true };
}

async function tiaAdminDeleteUser(db, data, context, helpers) {
  const { auth } = depsOf(db, helpers, context);
  if (!(await helpers.isAdmin(auth))) {
    throw helpers.httpsError('permission-denied', 'Apenas admin');
  }
  const uid = String(data?.uid || '');
  if (!uid) throw helpers.httpsError('invalid-argument', 'uid obrigatório');
  const conversations = await db.query('aiConversations', (d) => d.userId === uid, {
    where: [['userId', '==', uid]],
    limit: 200,
  });
  for (const doc of conversations) {
    await db.delete(`aiConversations/${doc.id}`);
  }
  await db.add('aiAudit', {
    uid: auth.uid,
    type: 'admin_delete_user',
    target: uid,
    ok: true,
    removed: conversations.length,
    at: new Date().toISOString(),
  });
  return { ok: true, removed: conversations.length };
}

function publicConfig(config) {
  const copy = { ...(config || {}) };
  delete copy.secret;
  delete copy.apiKey;
  delete copy.token;
  return copy;
}

function bind(firestore) {
  return adminDb(firestore);
}

module.exports = {
  tiaChat,
  tiaAnalyzePhoto,
  tiaEstimate,
  tiaConfirm,
  tiaStatus,
  tiaHistory,
  tiaDeleteMyData,
  tiaAdminGet,
  tiaAdminUpdate,
  tiaAdminDeleteUser,
  bind,
  aiEnv,
};
