'use strict';

/** Lembretes de agenda. Idempotente pelo campo reminderSentAt. */

function parseWhen(date, time) {
  const stamp = Date.parse(`${date}T${time}:00`);
  return Number.isNaN(stamp) ? null : stamp;
}

async function runReminders(db, now, notify) {
  const docs = await db.query('appointments', (d) =>
    d.status === 'confirmed' || d.status === 'scheduled' || d.status === 'agendado');
  let sent = 0;
  for (const doc of docs) {
    const data = doc.data || {};
    if (data.reminderSentAt) continue;
    const when = parseWhen(data.date, data.time);
    if (when == null) continue;
    const delta = when - now.getTime();
    if (delta < 0 || delta > 24 * 60 * 60 * 1000) continue;
    const title = 'Lembrete de atendimento';
    const body = `${data.date} às ${data.time}`;
    if (data.clientId && notify) await notify(data.clientId, title, body, 'agenda');
    if (data.providerId && notify) await notify(data.providerId, title, body, 'agenda');
    await db.set(`appointments/${doc.id}`, { reminderSentAt: now.toISOString() }, { merge: true });
    sent += 1;
  }
  return { ok: true, sent };
}

module.exports = { runReminders, parseWhen };
