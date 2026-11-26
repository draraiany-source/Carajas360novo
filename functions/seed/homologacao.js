'use strict';

/**
 * Semente só para o emulador. Cada documento traz dataset=homologacao.
 * Recusa rodar se FIRESTORE_EMULATOR_HOST não estiver definido.
 */

const admin = require('firebase-admin');

const DATASET = 'homologacao';

function docs() {
  return {
    'users/hml_cliente': {
      name: 'Cliente Homologação',
      type: 'client',
      city: 'Canaã dos Carajás',
      dataset: DATASET,
    },
    'users/hml_prestador': {
      name: 'Prestador Homologação',
      type: 'provider',
      city: 'Canaã dos Carajás',
      dataset: DATASET,
    },
    'users/hml_empresa': {
      name: 'Empresa Homologação',
      type: 'company',
      city: 'Canaã dos Carajás',
      dataset: DATASET,
    },
    'users/hml_admin': {
      name: 'Admin Homologação',
      type: 'admin',
      city: 'Canaã dos Carajás',
      dataset: DATASET,
    },
    'providers/hml_prestador': {
      name: 'Prestador Homologação',
      userId: 'hml_prestador',
      categories: ['pedreiro'],
      city: 'Canaã dos Carajás',
      active: true,
      verified: true,
      rating: 0,
      totalReviews: 0,
      dataset: DATASET,
    },
    'config/featureFlags': {
      explorar: true,
      tia: true,
      orcamentos: true,
      agenda: true,
      pagamentos: false,
      whatsapp: false,
      saude: true,
      chat: true,
      dataset: DATASET,
    },
  };
}

async function main() {
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    console.error('Recusado: defina FIRESTORE_EMULATOR_HOST. Esta semente não grava em produção.');
    process.exit(1);
  }
  if (!admin.apps.length) admin.initializeApp({ projectId: process.env.GCLOUD_PROJECT || 'demo-carajas360' });
  const db = admin.firestore();
  const batch = docs();
  for (const [path, data] of Object.entries(batch)) {
    await db.doc(path).set(data, { merge: true });
  }
  console.log(`Semente ${DATASET} gravada no emulador (${Object.keys(batch).length} documentos).`);
}

if (require.main === module) {
  main().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}

module.exports = { DATASET, docs };
