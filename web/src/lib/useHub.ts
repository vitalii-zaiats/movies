import { onBeforeUnmount, ref, shallowRef } from 'vue'
import type { ClientMessage, PeersMessage, Role, ServerMessage } from './protocol'

export type HubStatus = 'connecting' | 'open' | 'closed' | 'rejected'

const RETRY_STEPS = [1000, 2000, 5000, 10000]

export interface HubOptions {
  role: Role
  /**
   * Required for a remote. A display may pass the code it had last time and the
   * hub will hand it back if it's free — otherwise it issues a fresh one.
   */
  code?: string
  onMessage?: (message: ServerMessage) => void
}

/**
 * One socket to the hub, kept alive.
 *
 * Reconnects on drop — a display is meant to sit on a TV for hours — but stops
 * for good once the hub says the code is unknown, because retrying can't fix it.
 */
export function useHub(options: HubOptions) {
  const status = ref<HubStatus>('connecting')
  const code = ref<string | null>(options.code?.toUpperCase() ?? null)
  const peers = ref<Pick<PeersMessage, 'displays' | 'remotes'>>({ displays: 0, remotes: 0 })
  const error = ref<string | null>(null)

  const socket = shallowRef<WebSocket | null>(null)
  let attempt = 0
  let retryTimer: number | undefined
  let closedByUs = false

  function url(): string {
    const params = new URLSearchParams({ role: options.role })
    if (code.value) params.set('code', code.value)
    // Same origin as the page, so an https tunnel upgrades this to wss for free.
    const scheme = location.protocol === 'https:' ? 'wss' : 'ws'
    return `${scheme}://${location.host}/ws?${params}`
  }

  function connect(): void {
    closedByUs = false
    status.value = 'connecting'

    const ws = new WebSocket(url())
    socket.value = ws

    ws.addEventListener('open', () => {
      attempt = 0
      status.value = 'open'
      error.value = null
    })

    ws.addEventListener('message', (event) => {
      const message = JSON.parse(event.data as string) as ServerMessage
      switch (message.type) {
        case 'welcome':
          code.value = message.code
          break
        case 'peers':
          peers.value = { displays: message.displays, remotes: message.remotes }
          break
        case 'error':
          error.value = message.message
          status.value = 'rejected'
          closedByUs = true // a bad code stays bad; don't hammer the hub
          break
      }
      options.onMessage?.(message)
    })

    ws.addEventListener('close', () => {
      socket.value = null
      if (closedByUs) {
        if (status.value !== 'rejected') status.value = 'closed'
        return
      }
      status.value = 'closed'
      const wait = RETRY_STEPS[Math.min(attempt, RETRY_STEPS.length - 1)]
      attempt += 1
      retryTimer = window.setTimeout(connect, wait)
    })
  }

  function send(message: ClientMessage): boolean {
    if (socket.value?.readyState !== WebSocket.OPEN) return false
    socket.value.send(JSON.stringify(message))
    return true
  }

  function close(): void {
    closedByUs = true
    window.clearTimeout(retryTimer)
    socket.value?.close()
  }

  connect()
  onBeforeUnmount(close)

  return { status, code, peers, error, send, close }
}
