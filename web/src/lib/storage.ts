// Small wrapper over localStorage: every value carries a timestamp so it can go
// stale on its own, and every access is guarded — storage throws in private mode
// and when a browser has it switched off entirely.

const NAMESPACE = 'kino'
const DEFAULT_TTL_DAYS = 60

interface Envelope<T> {
  v: T
  at: number
}

function full(key: string): string {
  return `${NAMESPACE}.${key}`
}

export function remember<T>(key: string, value: T): void {
  try {
    localStorage.setItem(full(key), JSON.stringify({ v: value, at: Date.now() }))
  } catch {
    // Not worth failing a render over.
  }
}

export function recall<T>(key: string, ttlDays = DEFAULT_TTL_DAYS): T | null {
  try {
    const raw = localStorage.getItem(full(key))
    if (!raw) return null

    const envelope = JSON.parse(raw) as Envelope<T>
    if (!envelope || typeof envelope.at !== 'number') return null

    if (Date.now() - envelope.at > ttlDays * 86_400_000) {
      forget(key)
      return null
    }
    return envelope.v
  } catch {
    return null
  }
}

export function forget(key: string): void {
  try {
    localStorage.removeItem(full(key))
  } catch {
    // as above
  }
}

export const keys = {
  displayCode: 'display.code',
  displayPlayer: 'display.player',
  remoteCode: 'remote.code',
} as const
