// What a screen and a phone say to each other, mirroring
// `apps/hub/src/hub/protocol.py` — keep the two in step.
//
// The hub relays `command` and `state` and looks inside neither, so everything
// below is an agreement between the two ends alone. `web/` has its own copy of
// this file with its own vocabulary; the duplication is the price of two apps
// that don't depend on each other.

export type Role = 'display' | 'remote'

export const CODE_LENGTH = 6
// No 0/O/1/I: this gets read off a television and typed on a phone.
export const CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'

export function isCode(value: string): boolean {
  const code = value.trim().toUpperCase()
  return code.length === CODE_LENGTH && [...code].every((char) => CODE_ALPHABET.includes(char))
}

/** One row of "carry on with this", as the screen knows it. */
export interface ResumeEntry {
  episodeId: number
  title: string
  show: string
  /** `S01E02`, or null for a film. */
  code: string | null
  /** How far in, 0–1, or null when nothing knows the duration. */
  ratio: number | null
}

/**
 * Everything the phone needs to draw itself, reported by the screen.
 *
 * The remote holds no catalogue of its own and asks the API for nothing — it
 * knows what it was told. That's deliberate: a phone that joins a room should
 * not become a user, and it doesn't have to in order to press pause.
 */
export interface DisplayState {
  title: string | null
  show: string | null
  /** `S01E02`, or null for a film. */
  code: string | null
  playing: boolean
  position: number
  duration: number
  volume: number
  muted: boolean
  /** Set when the screen has nothing open — the remote says so rather than lying. */
  idle: boolean
  error: string | null
  /**
   * What this viewer had going, sent *by the screen*.
   *
   * The phone can't ask for it: history lives behind `/me/*`, which mints a
   * guest for whoever knocks, and a remote is not a person. The screen already
   * is that person, so it looks it up and passes it along. The hub relays
   * `state` without opening it, so this costs the protocol nothing.
   */
  resume: ResumeEntry[]
}

export const IDLE_STATE: DisplayState = {
  title: null,
  show: null,
  code: null,
  playing: false,
  position: 0,
  duration: 0,
  volume: 1,
  muted: false,
  idle: true,
  error: null,
  resume: [],
}

export interface WelcomeMessage {
  type: 'welcome'
  role: Role
  code: string
  id: string
}

export interface PeersMessage {
  type: 'peers'
  displays: number
  remotes: number
}

export interface CommandMessage {
  type: 'command'
  name: string
  args?: Record<string, unknown>
  from?: Role
}

export interface StateMessage {
  type: 'state'
  state: DisplayState
  from?: Role
}

export interface ErrorMessage {
  type: 'error'
  message: string
}

export type ServerMessage =
  | WelcomeMessage
  | PeersMessage
  | CommandMessage
  | StateMessage
  | ErrorMessage

export type ClientMessage = CommandMessage | StateMessage

function command(name: string, args?: Record<string, unknown>): CommandMessage {
  return { type: 'command', name, args }
}

export const commands = {
  /**
   * Put this on. The phone may browse the catalogue — that costs no identity,
   * `GET /shows` and `GET /episodes` ask nobody who they are — but it never
   * plays anything itself: it names an episode and the screen opens it.
   */
  play: (episodeId: number) => command('play', { episodeId }),
  toggle: () => command('toggle'),
  next: () => command('next'),
  prev: () => command('prev'),
  /** Relative, resolved by the screen against wherever it actually is. */
  skip: (delta: number) => command('skip', { delta }),
  seek: (position: number) => command('seek', { position }),
  volume: (level: number) => command('volume', { level }),
  mute: (muted: boolean) => command('mute', { muted }),
  stop: () => command('stop'),
}
