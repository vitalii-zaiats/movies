// One socket to `apps/hub`, kept alive.
//
// Reconnects on drop — a screen is meant to sit there for hours — but stops for
// good once the hub says the code is unknown, because retrying can't fix that.

import type { ClientMessage, PeersMessage, Role, ServerMessage } from '~/lib/hub/protocol'

export type HubStatus = 'connecting' | 'open' | 'closed' | 'rejected'

const RETRY_STEPS = [1000, 2000, 5000, 10_000]

export interface HubOptions {
  role: Role
  /** Required for a remote; a display may ask for the code it had last time. */
  code?: string
  onMessage?: (message: ServerMessage) => void
}

export function useHub(options: HubOptions) {
  const status = ref<HubStatus>('connecting')
  const code = ref<string | null>(options.code?.toUpperCase() ?? null)
  const peers = ref<Pick<PeersMessage, 'displays' | 'remotes'>>({ displays: 0, remotes: 0 })
  const error = ref<string | null>(null)

  const socket = shallowRef<WebSocket | null>(null)
  let attempt = 0
  let retryTimer: ReturnType<typeof setTimeout> | undefined
  let closedByUs = false

  function url(): string {
    const params = new URLSearchParams({ role: options.role })
    if (code.value) params.set('code', code.value)
    // Same origin as the page, so a https tunnel upgrades this to wss for free
    // and nginx proxies /ws to the hub either way.
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
      retryTimer = setTimeout(connect, wait)
    })
  }

  function send(message: ClientMessage): boolean {
    if (socket.value?.readyState !== WebSocket.OPEN) return false
    socket.value.send(JSON.stringify(message))
    return true
  }

  function close(): void {
    closedByUs = true
    clearTimeout(retryTimer)
    socket.value?.close()
  }

  connect()
  onBeforeUnmount(close)

  return { status, code, peers, error, send, close }
}
