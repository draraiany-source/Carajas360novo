const test = require('node:test');
const assert = require('node:assert/strict');
const { memoryDb } = require('../ai/firestore');
const { runReminders } = require('./reminders');

test('lembrete só nas próximas 24h e não reenvia', async () => {
  const db = memoryDb({
    'appointments/a1': {
      clientId: 'u1', providerId: 'p1', date: '2026-11-26', time: '18:00', status: 'scheduled',
    },
    'appointments/a2': {
      clientId: 'u1', providerId: 'p1', date: '2026-12-20', time: '18:00', status: 'scheduled',
    },
  });
  const notes = [];
  const now = new Date('2026-11-26T12:00:00');
  const first = await runReminders(db, now, async (userId) => notes.push(userId));
  assert.equal(first.sent, 1);
  assert.equal(notes.length, 2);
  const second = await runReminders(db, now, async (userId) => notes.push(userId));
  assert.equal(second.sent, 0);
  assert.equal(notes.length, 2);
});
