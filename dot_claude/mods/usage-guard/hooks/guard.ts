import type { SessionRateLimit } from 'claude-code'

export const WARN = 80
export const LIMIT = 90

export type Window = { pct: number; reset: number }

// A reading whose reset has passed is from a past window: nothing to guard.
export const fiveHour = (limits: readonly SessionRateLimit[], now: number): Window | null => {
  const w = limits.find(l => l.kind === 'five_hour')
  const reset = w?.resetsAt ? Date.parse(w.resetsAt) : NaN
  return w && reset > now ? { pct: Math.round(w.percentUsed), reset } : null
}

// One-shot cron jobs on :00/:30 may fire up to 90s early, i.e. before the reset; skip those minutes.
export const resumeAt = (reset: number) => {
  let d = new Date(reset + 60_000)
  if (d.getMinutes() % 30 === 0) d = new Date(d.getTime() + 60_000)
  const pad = (n: number) => String(n).padStart(2, '0')
  return {
    at: `${pad(d.getHours())}:${pad(d.getMinutes())}`,
    cron: `${d.getMinutes()} ${d.getHours()} ${d.getDate()} ${d.getMonth() + 1} *`,
  }
}

export const describe = ({ pct, reset }: Window) =>
  `5h window at ${pct}% (hard stop at ${LIMIT}%, resets at ${resumeAt(reset).at}).`

export const notes = (w: Window, isSubagent: boolean) => {
  const { cron } = resumeAt(w.reset)
  const status = `Usage guard: ${describe(w)}`
  const schedule = `schedule the resume with CronCreate (cron "${cron}", recurring false) using a handoff prompt that says where to pick up`
  return {
    status,
    wrap: isSubagent
      ? `${status} Finish the current step and return your result to the parent now; do not start new work.`
      : `${status} Bring the work to a clean stopping point: land or note the current edit, start no new subagents or tasks. Then ${schedule}, tell the user what is unfinished, and stop.`,
    hardStop: `${status} Hard stop: every tool but CronCreate is denied now. ${schedule[0]!.toUpperCase()}${schedule.slice(1)}, tell the user what is unfinished, and stop.`,
    notification: `${status} Hard stop: record this result for the user, ${schedule} if not done yet, and stop.`,
  }
}
