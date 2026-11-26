'use strict';

const catalog = require('../data/catalogo_categorias.json');

function fold(value) {
  return String(value || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();
}

function identify(text) {
  const folded = fold(text);
  if (!folded) return null;
  let best = null;
  let bestLen = 0;
  function consider(phrases, match) {
    for (const phrase of phrases) {
      const token = fold(phrase);
      if (token.length < 4) continue;
      if (folded.includes(token) && token.length > bestLen) {
        best = match;
        bestLen = token.length;
      }
    }
  }
  for (const profession of catalog.professions) {
    consider([profession.name, ...(profession.keywords || [])], {
      kind: 'profissao',
      id: profession.id,
      name: profession.name,
      categoryId: profession.categoryId,
    });
  }
  for (const category of catalog.categories) {
    if (category.kind === 'navegacao') continue;
    consider([category.name], {
      kind: 'categoria',
      id: category.id,
      name: category.name,
      categoryId: category.id,
    });
  }
  return best;
}

function publicCategories() {
  return catalog.categories
    .filter((category) => category.kind === 'servico' || category.home)
    .map((category) => ({
      id: category.id,
      name: category.name,
      pendingArt: category.pendingArt === true,
      kind: category.kind,
      home: category.home === true,
    }));
}

function publicProfessions() {
  return catalog.professions.map((profession) => ({
    id: profession.id,
    name: profession.name,
    group: profession.group,
    categoryId: profession.categoryId,
  }));
}

module.exports = {
  catalog,
  fold,
  identify,
  publicCategories,
  publicProfessions,
};
