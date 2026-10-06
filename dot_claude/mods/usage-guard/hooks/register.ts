import type { EngineInterface, Register } from 'claude-code'

import { LIMIT, WARN, describe, fiveHour, notes } from './guard'

const CRON_TOOLS = new Set(['CronCreate', 'CronList', 'CronDelete'])

async function reading($: EngineInterface) {
  if ((await $.store.get('off')) === true) return null
  const w = fiveHour((await $.session.usage()).rateLimits, await $.clock.now())
  return w && w.pct >= WARN ? w : null
}

export const register: Register = on => {
  // Last warned percentage per window and loop; a reload forgets it and warns once more.
  const warned = new Map<string, number>()

  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'usage-guard',
      description: 'Show the 5h usage guard, or turn it off/on',
    })
    return next(e)
  })

  on('command.run', { command: 'usage-guard' }, async ($, e) => {
    const arg = e.args.trim()
    if (arg === 'off' || arg === 'on') await $.store.set('off', arg === 'off')
    const isOff = (await $.store.get('off')) === true
    const w = fiveHour((await $.session.usage()).rateLimits, await $.clock.now())
    const summary = w ? describe(w) : 'No current 5h reading.'
    return { text: `${summary} Guard is ${isOff ? 'OFF' : 'on'} (warn ${WARN}%, stop ${LIMIT}%).` }
  })

  on('session.measure', async ($, e, next) => {
    const w = e.changed.includes('rateLimits') ? fiveHour(e.rateLimits, await $.clock.now()) : null
    const key = `toast-${w?.reset}`
    const level = w && w.pct >= LIMIT ? LIMIT : w && w.pct >= WARN ? WARN : 0
    if (w && level > (warned.get(key) ?? 0)) {
      warned.set(key, level)
      $.ui.toast(notes(w, false).status)
    }
    return next(e)
  })

  on('prompt.submit', async ($, e, next) => {
    const w = await reading($)
    if (!w) return next(e)
    const n = notes(w, false)
    if (w.pct >= LIMIT && e.origin.kind !== 'task-notification')
      return { drop: `${n.status} Resume after the reset, or run /usage-guard off to override.` }
    const note = w.pct >= LIMIT ? n.notification : `${n.status} Keep this turn short.`
    return next({ ...e, context: [...(e.context ?? []), note] })
  })

  on('tool.call', async ($, e, next) => {
    const w = await reading($)
    if (!w) return next(e)
    const n = notes(w, e.agentId !== undefined)
    if (w.pct >= LIMIT) {
      if (CRON_TOOLS.has(e.tool)) return next(e)
      return { deny: e.agentId === undefined ? n.hardStop : n.wrap }
    }
    const key = `${w.reset}-${e.agentId ?? ''}`
    const ran = await next(e)
    if (ran.deny !== undefined || w.pct - (warned.get(key) ?? 0) < 3) return ran
    warned.set(key, w.pct)
    return { ...ran, context: [...(ran.context ?? []), n.wrap] }
  })
}
