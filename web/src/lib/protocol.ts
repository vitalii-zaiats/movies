// Mirror of apps/hub/src/hub/protocol.py — keep the two in step.
//
// The hub relays `command` and `state` without looking inside, so everything
// below is an agreement between the display and the remote alone.

export type Role = 'display' | 'remote'

export const CODE_LENGTH = 6
export const CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'

export function isCode(value: string): boolean {
  const code = value.trim().toUpperCase()
  return code.length === CODE_LENGTH && [...code].every((c) => CODE_ALPHABET.includes(c))
}

/** Everything the remote needs to draw itself, reported by the screen. */
export interface DisplayState {
  background: string
  playlistId: number | null
  playlistName: string | null
  index: number
  total: number
  title: string | null
  playing: boolean
  position: number
  duration: number
  /** 0..1. iOS ignores programmatic volume, so treat it as a hint there. */
  volume: number
  muted: boolean
  fullscreen: boolean
  error: string | null
}

export const IDLE_STATE: DisplayState = {
  background: '#0f172a',
  playlistId: null,
  playlistName: null,
  index: 0,
  total: 0,
  title: null,
  playing: false,
  position: 0,
  duration: 0,
  volume: 1,
  muted: false,
  fullscreen: false,
  error: null,
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
  play: (playlistId: number, index = 0) => command('play', { playlistId, index }),
  toggle: () => command('toggle'),
  next: () => command('next'),
  prev: () => command('prev'),
  stop: () => command('stop'),
  seek: (position: number) => command('seek', { position }),
  /** Relative jump, resolved by the screen against wherever it actually is. */
  skip: (delta: number) => command('skip', { delta }),
  volume: (level: number) => command('volume', { level }),
  mute: (muted: boolean) => command('mute', { muted }),
  /** Browsers only grant this on a gesture, so the screen may refuse politely. */
  fullscreen: (on: boolean) => command('fullscreen', { on }),
  background: (color: string) => command('background', { color }),
}
