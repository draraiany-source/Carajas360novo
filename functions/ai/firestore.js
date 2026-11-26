/**
 * Adaptador do Firestore admin e banco em memória para testes.
 */

function adminDb(firestore) {
  return {
    async get(path) {
      const snap = await firestore.doc(path).get();
      return snap.exists ? snap.data() : null;
    },
    async set(path, data, opts = {}) {
      await firestore.doc(path).set(data, { merge: Boolean(opts.merge) });
    },
    async add(col, data) {
      const ref = await firestore.collection(col).add(data);
      return ref.id;
    },
    async delete(path) {
      await firestore.doc(path).delete();
    },
    async query(col, pred, opts = {}) {
      let q = firestore.collection(col);
      for (const w of opts.where || []) q = q.where(w[0], w[1], w[2]);
      if (opts.orderBy) q = q.orderBy(opts.orderBy[0], opts.orderBy[1] || 'asc');
      const snap = await q.limit(opts.limit || 40).get();
      return snap.docs
        .map((d) => ({ id: d.id, data: d.data() }))
        .filter((d) => !pred || pred(d.data));
    },
  };
}

function memoryDb(seed = {}) {
  const docs = new Map(Object.entries(seed).map(([k, v]) => [k, clone(v)]));
  function rows(col) {
    const out = [];
    for (const [path, data] of docs) {
      const parts = path.split('/');
      if (parts.length === 2 && parts[0] === col) out.push({ id: parts[1], data: clone(data) });
    }
    return out;
  }
  return {
    async get(path) {
      return docs.has(path) ? clone(docs.get(path)) : null;
    },
    async set(path, data, opts = {}) {
      const prev = docs.get(path) || {};
      docs.set(path, opts.merge ? { ...prev, ...clone(data) } : clone(data));
    },
    async add(col, data) {
      const id = `id_${Math.random().toString(36).slice(2, 10)}`;
      docs.set(`${col}/${id}`, clone(data));
      return id;
    },
    async delete(path) {
      docs.delete(path);
    },
    async query(col, pred) {
      return rows(col).filter((d) => !pred || pred(d.data));
    },
    async runTransaction(fn) {
      const tx = {
        async get(path) {
          return docs.has(path) ? clone(docs.get(path)) : null;
        },
        set(path, data, opts = {}) {
          const prev = docs.get(path) || {};
          docs.set(path, opts.merge ? { ...prev, ...clone(data) } : clone(data));
        },
      };
      return fn(tx);
    },
    dump() {
      return Object.fromEntries([...docs.entries()].map(([k, v]) => [k, clone(v)]));
    },
  };
}

function clone(value) {
  return value == null ? value : JSON.parse(JSON.stringify(value));
}

module.exports = { adminDb, memoryDb };
