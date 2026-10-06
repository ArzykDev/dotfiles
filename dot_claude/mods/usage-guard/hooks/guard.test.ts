import type { On } from 'claude-code'
import { expect, mock, test } from 'claude-code/testing'

const NOW = Date.parse('2026-10-06T10:00:00Z')
const RESET = '2026-10-06T12:00:00Z'

const setup = (on: On, percentUsed: number, resetsAt = RESET, store = {}) => {
  mock.clock(on, { now: NOW })
  mock.store(on, store)
  on('session.usage', () => ({
    value: {
      startedAt: 0,
      context: { window: 200_000 },
      rateLimits: [{ kind: 'five_hour', percentUsed, resetsAt }],
    },
  }))
  on('tool.call', () => ({ result: 'ran' }))
}

test('below the warn line nothing changes', async ($, on) => {
  setup(on, 50)
  const r = await $.tool.call({ tool: 'Bash', command: 'ls' })
  expect(r.deny).toBeUndefined()
  expect(r.context).toBeUndefined()
})

test('at the warn line the result carries one wrap-up note per 3%', async ($, on) => {
  setup(on, 82)
  const first = await $.tool.call({ tool: 'Bash', command: 'ls' })
  expect(first.context?.[0]).toMatch(/82%.*CronCreate \(cron "\d+ \d+ \d+ \d+ \*"/)
  const second = await $.tool.call({ tool: 'Bash', command: 'ls' })
  expect(second.context).toBeUndefined()
})

test('at the limit every tool but the cron ones is denied', async ($, on) => {
  setup(on, 91)
  const bash = await $.tool.call({ tool: 'Bash', command: 'ls' })
  expect(bash.deny).toMatch(/Hard stop/)
  const cron = await $.tool.call({ tool: 'CronCreate', cron: '1 12 6 10 *', prompt: 'x', recurring: false })
  expect(cron.deny).toBeUndefined()
})

test('a reading from a past window is ignored', async ($, on) => {
  setup(on, 95, '2026-10-06T09:00:00Z')
  const r = await $.tool.call({ tool: 'Bash', command: 'ls' })
  expect(r.isError).toBeUndefined()
})

test('the off switch lets everything through', async ($, on) => {
  setup(on, 95, RESET, { off: true })
  const r = await $.tool.call({ tool: 'Bash', command: 'ls' })
  expect(r.isError).toBeUndefined()
})
