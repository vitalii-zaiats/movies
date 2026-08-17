// The wire between whatever is playing and whoever is holding the phone.
//
// Neither end knows the other exists. The player writes what it's doing and
// reads commands addressed to it; the paired session ships those over the socket
// and hands back what comes in. That way the player has no socket in it and the
// socket has no opinion about players — and a page with no player at all still
// reports something honest, which is "nothing is on".

import { IDLE_STATE, type CommandMessage, type DisplayState } from '~/lib/hub/protocol'

/** Where the room code is kept, so a reload rejoins instead of starting over. */
const REMEMBERED = 'lumen:cast'

/**
 * Which tab is holding the room, and when it last said so.
 *
 * Two tabs are two screens, and the hub knows it: `claim_room` is a Redis
 * `SET NX`, so the second one asking for a remembered code doesn't get it — it
 * gets a room of its own. That much is safe. What isn't safe is both tabs
 * writing the remembered code, because then the tab the phone is *actually*
 * paired with loses its own memory to the other one. So exactly one tab holds
 * the session, and the rest say where it is.
 */
const OWNER = 'lumen:cast:owner'
/** Refreshed this often; a record older than the stale mark is a crashed tab. */
const HEARTBEAT = 2000
const STALE = 6000

export function useCast() {
  /** What the screen is doing. The player owns this; the session ships it. */
  const state = useState<DisplayState>('cast:state', () => ({ ...IDLE_STATE }))

  /** Whether this screen is offering itself, and to how many phones. */
  const pairing = useState('cast:pairing', () => false)
  const phones = useState('cast:phones', () => 0)

  /**
   * The last command from the phone, stamped so the same one twice — pause,
   * pause — still counts twice. A watcher on the number is the whole protocol.
   */
  const command = useState<{ seq: number; message: CommandMessage } | null>(
    'cast:command',
    () => null,
  )
  const seq = useState('cast:seq', () => 0)

  /** Called by the paired session when the remote says something. */
  function deliver(message: CommandMessage): void {
    seq.value += 1
    command.value = { seq: seq.value, message }
  }

  /** Called by the player on every change worth telling the phone about. */
  function report(patch: Partial<DisplayState>): void {
    state.value = { ...state.value, ...patch }
  }

  /** The player is gone — say so rather than leaving the phone with a ghost. */
  function idle(): void {
    state.value = { ...IDLE_STATE }
  }

  /** Run `apply` for every command that arrives, until the caller unmounts. */
  function onCommand(apply: (message: CommandMessage) => void): void {
    watch(
      () => command.value?.seq,
      () => {
        const message = command.value?.message
        if (message) apply(message)
      },
    )
  }

  /**
   * The code this screen had last time.
   *
   * The hub hands a display back its own code if the room is still free, so
   * remembering it is what makes a reload — or a reopened dialog — rejoin the
   * phone that's already holding the remote, instead of stranding it in a room
   * nobody is in any more.
   */
  function remembered(): { code: string | null; pairing: boolean } {
    if (import.meta.server) return { code: null, pairing: false }
    try {
      const raw = localStorage.getItem(REMEMBERED)
      const saved = raw ? (JSON.parse(raw) as { code?: string; pairing?: boolean }) : null
      return { code: saved?.code ?? null, pairing: Boolean(saved?.pairing) }
    } catch {
      // A browser that refuses storage still pairs; it just forgets.
      return { code: null, pairing: false }
    }
  }

  function remember(code: string | null, on: boolean): void {
    if (import.meta.server) return
    try {
      localStorage.setItem(REMEMBERED, JSON.stringify({ code, pairing: on }))
    } catch {
      // Not worth a word to the viewer: forgetting a code costs one scan.
    }
  }

  /** This tab, for as long as it lives. */
  const tabId = useState('cast:tab', () => Math.random().toString(36).slice(2))

  function owner(): { tab: string; at: number } | null {
    if (import.meta.server) return null
    try {
      const raw = localStorage.getItem(OWNER)
      return raw ? (JSON.parse(raw) as { tab: string; at: number }) : null
    } catch {
      return null
    }
  }

  /** Somebody else has the remote, and is still alive to prove it. */
  function heldElsewhere(): boolean {
    const record = owner()
    return Boolean(record && record.tab !== tabId.value && Date.now() - record.at < STALE)
  }

  function claim(): void {
    if (import.meta.server) return
    try {
      localStorage.setItem(OWNER, JSON.stringify({ tab: tabId.value, at: Date.now() }))
    } catch {
      // Without storage there is no lock and no takeover — one tab, as before.
    }
  }

  function release(): void {
    if (import.meta.server) return
    try {
      if (owner()?.tab === tabId.value) localStorage.removeItem(OWNER)
    } catch {
      // Nothing to undo.
    }
  }

  return {
    state,
    command,
    pairing,
    phones,
    tabId,
    deliver,
    report,
    idle,
    onCommand,
    remembered,
    remember,
    owner,
    heldElsewhere,
    claim,
    release,
    HEARTBEAT,
  }
}
