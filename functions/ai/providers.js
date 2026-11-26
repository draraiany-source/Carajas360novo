/**
 * Adaptadores de provedor. A chave fica só no processo da função.
 * Gemini (Firebase AI / Google AI) é o padrão. OpenAI-compatível e Anthropic são opcionais.
 */

const { toolSchemas } = require('./tools');

function resolveProvider(env, config) {
  const forced = String((config && config.provider) || '').trim().toLowerCase();
  const gemini = String(env.GEMINI_API_KEY || '');
  const openai = String(env.OPENAI_API_KEY || '');
  const anthropic = String(env.ANTHROPIC_API_KEY || '');
  const choice = forced || (gemini ? 'gemini' : openai ? 'openai' : anthropic ? 'anthropic' : '');
  if (!choice) {
    return {
      ok: false,
      reason: 'IA indisponível: nenhum provedor configurado. Defina GEMINI_API_KEY, OPENAI_API_KEY ou ANTHROPIC_API_KEY no Secret Manager.',
    };
  }
  const key = choice === 'gemini' ? gemini : choice === 'openai' ? openai : anthropic;
  if (!key || key === 'disabled') {
    return {
      ok: false,
      reason: `IA indisponível: o provedor "${choice}" está selecionado, mas a chave correspondente não está configurada.`,
    };
  }
  const model = choice === 'gemini'
    ? (config && config.geminiModel) || 'gemini-2.0-flash'
    : choice === 'openai'
      ? (config && config.openaiModel) || 'gpt-4o-mini'
      : (config && config.anthropicModel) || 'claude-sonnet-4-5';
  return {
    ok: true,
    provider: choice,
    apiKey: key,
    model,
    baseUrl: (config && config.openaiBaseUrl) || env.OPENAI_BASE_URL || 'https://api.openai.com',
  };
}

function keysPresent(env) {
  return {
    gemini: Boolean(env.GEMINI_API_KEY && env.GEMINI_API_KEY !== 'disabled'),
    openai: Boolean(env.OPENAI_API_KEY && env.OPENAI_API_KEY !== 'disabled'),
    anthropic: Boolean(env.ANTHROPIC_API_KEY && env.ANTHROPIC_API_KEY !== 'disabled'),
  };
}

async function generate({ provider, apiKey, baseUrl, model, system, messages, fetchImpl, image }) {
  if (provider === 'gemini') return gemini({ apiKey, model, system, messages, fetchImpl, image });
  if (provider === 'openai') return openai({ apiKey, baseUrl, model, system, messages, fetchImpl, image });
  if (provider === 'anthropic') return anthropic({ apiKey, model, system, messages, fetchImpl, image });
  throw new Error('Provedor não suportado');
}

async function gemini({ apiKey, model, system, messages, fetchImpl, image }) {
  const contents = toGeminiContents(messages, image);
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${encodeURIComponent(apiKey)}`;
  const body = {
    systemInstruction: { parts: [{ text: system }] },
    contents,
    tools: [{ functionDeclarations: toolSchemas().map(geminiDecl) }],
    generationConfig: { temperature: 0.4, maxOutputTokens: image ? 900 : 700 },
  };
  const res = await fetchImpl(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const json = await readJson(res);
  if (!res.ok) return httpFailure(res.status);
  const parts = json.candidates?.[0]?.content?.parts || [];
  const text = parts.filter((p) => p.text).map((p) => p.text).join('\n').trim();
  const toolCalls = parts.filter((p) => p.functionCall).map((p, i) => ({
    id: `gem_${i}_${p.functionCall.name}`,
    name: p.functionCall.name,
    args: p.functionCall.args || {},
  }));
  const usage = json.usageMetadata || {};
  return {
    text,
    toolCalls,
    usage: {
      input: Number(usage.promptTokenCount || 0),
      output: Number(usage.candidatesTokenCount || 0),
    },
  };
}

function geminiDecl(tool) {
  return {
    name: tool.name,
    description: tool.description,
    parameters: tool.parameters,
  };
}

function toGeminiContents(messages, image) {
  const contents = [];
  messages.forEach((m, index) => {
    if (m.role === 'user') {
      const parts = [{ text: m.content }];
      if (image && index === messages.length - 1) {
        parts.push({ inlineData: { mimeType: image.mimeType, data: image.data } });
      }
      contents.push({ role: 'user', parts });
    } else if (m.role === 'assistant') {
      const parts = [];
      if (m.content) parts.push({ text: m.content });
      for (const call of m.toolCalls || []) {
        parts.push({ functionCall: { name: call.name, args: call.args || {} } });
      }
      if (parts.length) contents.push({ role: 'model', parts });
    } else if (m.role === 'tool') {
      let parsed = {};
      try { parsed = JSON.parse(m.content); } catch (_) { parsed = { raw: m.content }; }
      contents.push({
        role: 'user',
        parts: [{ functionResponse: { name: m.name, response: parsed } }],
      });
    }
  });
  return contents;
}

async function openai({ apiKey, baseUrl, model, system, messages, fetchImpl, image }) {
  const payloadMessages = [{ role: 'system', content: system }];
  for (const m of messages) {
    if (m.role === 'user') {
      if (image && m === messages[messages.length - 1]) {
        payloadMessages.push({
          role: 'user',
          content: [
            { type: 'text', text: m.content },
            { type: 'image_url', image_url: { url: `data:${image.mimeType};base64,${image.data}` } },
          ],
        });
      } else {
        payloadMessages.push({ role: 'user', content: m.content });
      }
    } else if (m.role === 'assistant') {
      const msg = { role: 'assistant', content: m.content || '' };
      if (m.toolCalls?.length) {
        msg.tool_calls = m.toolCalls.map((c) => ({
          id: c.id,
          type: 'function',
          function: { name: c.name, arguments: JSON.stringify(c.args || {}) },
        }));
      }
      payloadMessages.push(msg);
    } else if (m.role === 'tool') {
      payloadMessages.push({ role: 'tool', tool_call_id: m.toolCallId, content: m.content });
    }
  }
  const root = String(baseUrl || 'https://api.openai.com').replace(/\/$/, '');
  const res = await fetchImpl(`${root}/v1/chat/completions`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model,
      temperature: 0.4,
      max_tokens: image ? 900 : 700,
      messages: payloadMessages,
      tools: toolSchemas().map((t) => ({
        type: 'function',
        function: { name: t.name, description: t.description, parameters: t.parameters },
      })),
    }),
  });
  const json = await readJson(res);
  if (!res.ok) return httpFailure(res.status);
  const choice = json.choices?.[0]?.message || {};
  const toolCalls = (choice.tool_calls || []).map((c) => ({
    id: c.id,
    name: c.function?.name,
    args: parseArgs(c.function?.arguments),
  }));
  return {
    text: String(choice.content || '').trim(),
    toolCalls,
    usage: {
      input: Number(json.usage?.prompt_tokens || 0),
      output: Number(json.usage?.completion_tokens || 0),
    },
  };
}

async function anthropic({ apiKey, model, system, messages, fetchImpl, image }) {
  const payload = [];
  for (const m of messages) {
    if (m.role === 'user') {
      if (image && m === messages[messages.length - 1]) {
        payload.push({
          role: 'user',
          content: [
            { type: 'text', text: m.content },
            { type: 'image', source: { type: 'base64', media_type: image.mimeType, data: image.data } },
          ],
        });
      } else {
        payload.push({ role: 'user', content: m.content });
      }
    } else if (m.role === 'assistant') {
      const content = [];
      if (m.content) content.push({ type: 'text', text: m.content });
      for (const call of m.toolCalls || []) {
        content.push({ type: 'tool_use', id: call.id, name: call.name, input: call.args || {} });
      }
      payload.push({ role: 'assistant', content: content.length ? content : (m.content || '') });
    } else if (m.role === 'tool') {
      payload.push({
        role: 'user',
        content: [{ type: 'tool_result', tool_use_id: m.toolCallId, content: m.content }],
      });
    }
  }
  const res = await fetchImpl('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model,
      max_tokens: image ? 900 : 700,
      system,
      tools: toolSchemas().map((t) => ({
        name: t.name,
        description: t.description,
        input_schema: t.parameters,
      })),
      messages: payload,
    }),
  });
  const json = await readJson(res);
  if (!res.ok) return httpFailure(res.status);
  const blocks = json.content || [];
  const text = blocks.filter((b) => b.type === 'text').map((b) => b.text).join('\n').trim();
  const toolCalls = blocks.filter((b) => b.type === 'tool_use').map((b) => ({
    id: b.id,
    name: b.name,
    args: b.input || {},
  }));
  return {
    text,
    toolCalls,
    usage: {
      input: Number(json.usage?.input_tokens || 0),
      output: Number(json.usage?.output_tokens || 0),
    },
  };
}

function parseArgs(raw) {
  if (!raw) return {};
  if (typeof raw === 'object') return raw;
  try { return JSON.parse(raw); } catch (_) { return {}; }
}

async function readJson(res) {
  try { return await res.json(); } catch (_) { return {}; }
}

function httpFailure(status) {
  return {
    text: '',
    toolCalls: [],
    usage: { input: 0, output: 0 },
    error: `O provedor de IA respondeu HTTP ${status}. Nenhuma resposta foi inventada.`,
  };
}

module.exports = { resolveProvider, generate, keysPresent };
