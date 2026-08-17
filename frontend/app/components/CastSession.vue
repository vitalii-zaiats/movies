<script setup lang="ts">
// This screen, offered to a phone.
//
// The socket lives here and *only* here, for as long as pairing is on — the
// dialog is a window onto it, not the thing itself. That distinction is the
// whole point: the hub deletes a room the moment its display disconnects, so a
// session that died with the dialog would strand the phone holding the remote
// and hand out a fresh code the next time anyone looked.

import QRCode from 'qrcode'
import type { ServerMessage } from '~/lib/hub/protocol'

const props = defineProps<{ showing: boolean }>()
const emit = defineEmits<{
  /** Put the window away; the room stays open. */
  hide: []
  /** End it: no more room, no more remote. */
  stop: []
}>()

const { state, deliver, report, phones, remembered, remember, claim, release, HEARTBEAT } =
  useCast()
const catalogue = useCatalogue()

const { status, code, peers, error, send } = useHub({
  role: 'display',
  // Ask for the code this screen had last time. The hub gives it back if the
  // room is still free, which is what keeps a paired phone paired.
  code: remembered().code ?? undefined,
  onMessage(message: ServerMessage) {
    if (message.type !== 'command') return

    // `play` is the one command the screen answers itself: it's about which
    // page to be on, and the player can't handle that — it may not exist yet.
    // `cast=1` tells the page it was opened from a phone, which is what lets it
    // try to start on its own instead of waiting for a click that isn't coming.
    if (message.name === 'play') {
      const id = Number(message.args?.episodeId)
      if (Number.isFinite(id)) void navigateTo({ path: `/watch/${id}`, query: { cast: '1' } })
      return
    }

    deliver(message)
  },
})

/** What the phone should open. Same origin, so the tunnel carries it too. */
const link = computed(() =>
  code.value ? `${location.origin}/remote/${code.value}` : null,
)

/** A phone in the room. Until one arrives, this dialog is just an invitation. */
const paired = computed(() => peers.value.remotes > 0)

// The dock button shows this, and it has no socket of its own.
watch(() => peers.value.remotes, (count) => (phones.value = count), { immediate: true })

/**
 * What this viewer had going, fetched here and shipped to the phone.
 *
 * This is the screen's own history — it is the one with the session — and the
 * only reason it's done here rather than on the phone is that asking for it
 * from the phone would hand a passing handset an identity it never wanted.
 */
async function carryOn(): Promise<void> {
  try {
    const rows = await catalogue.continueWatching(12)
    report({
      resume: rows.map((entry) => ({
        episodeId: entry.episode.id,
        title: episodeHeading(entry.episode),
        show: entry.episode.show.title,
        code: entry.episode.show.is_film ? null : episodeCode(entry.episode),
        ratio: entry.ratio,
      })),
    })
  } catch {
    // A screen that can't reach its own history still pairs; the phone just
    // gets a shorter list to choose from.
  }
}

onMounted(carryOn)
// Refreshed when a phone arrives, and after anything is played: the list is only
// worth anything if it's the one from a minute ago.
watch(paired, (on) => {
  if (on) void carryOn()
})
watch(() => state.value.title, () => void carryOn())

// Remembered as soon as the hub names it, so a reload rejoins the same room.
watch(code, (value) => remember(value, true), { immediate: true })

// This tab owns the room for as long as it holds the socket. The heartbeat is
// what lets another tab tell "busy" from "crashed with the flag still set".
let beat: ReturnType<typeof setInterval> | undefined

function stood_down(event: StorageEvent): void {
  // Another tab took it. Two screens with one phone is nobody's idea of a
  // remote, so this one steps aside rather than fighting for the room.
  if (event.key === 'lumen:cast:owner') emit('stop')
}

onMounted(() => {
  claim()
  beat = setInterval(claim, HEARTBEAT)
  window.addEventListener('storage', stood_down)
})

onBeforeUnmount(() => {
  clearInterval(beat)
  window.removeEventListener('storage', stood_down)
  release()
})

// Once a phone is on, the dialog has said what it had to say. It closes itself
// rather than sitting over the screen the phone is now driving — but only after
// long enough to read the word, and never while somebody is still looking at it
// on purpose (closing it by hand cancels nothing, it just gets there first).
const AFTER_PAIRED = 4000
let dismiss: ReturnType<typeof setTimeout> | undefined

watch([paired, () => props.showing], ([on, showing]) => {
  clearTimeout(dismiss)
  if (on && showing) dismiss = setTimeout(() => emit('hide'), AFTER_PAIRED)
})

onBeforeUnmount(() => clearTimeout(dismiss))

function stop(): void {
  remember(null, false)
  emit('stop')
}

const qr = ref<string | null>(null)

watch(
  link,
  async (value) => {
    qr.value = value
      ? await QRCode.toDataURL(value, { margin: 1, width: 320, errorCorrectionLevel: 'M' })
      : null
  },
  { immediate: true },
)

// Every change the player reports goes straight out. The state is small and the
// socket is local; there is nothing here worth batching.
watch(state, (value) => {
  send({ type: 'state', state: value })
}, { deep: true })
</script>

<template>
  <UiDialog v-if="showing" width="min(560px, 94vw)" @close="emit('hide')">
    <div class="pair">
      <h2 class="title">
        {{ paired ? 'Paired' : 'Drive this screen from your phone' }}
      </h2>

      <p v-if="paired" class="lede done">
        {{ countLabel(peers.remotes, 'phone') }} connected — it can browse and
        press play. Nothing here has to stay open; the pairing holds.
      </p>
      <p v-else class="lede">
        Scan it, or open the address and type the code. The phone gets the
        controls and nothing else — no account, no history.
      </p>

      <div class="face">
        <img v-if="qr" :src="qr" alt="" width="220" height="220" >
        <div v-else class="waiting">…</div>

        <div class="side">
          <span class="label">Code</span>
          <span class="code mono">{{ code ?? '——————' }}</span>

          <span class="label">Status</span>
          <span class="value" :class="{ live: paired }">
            {{ paired ? 'connected' : status === 'open' ? 'waiting for a phone' : status }}
          </span>

          <span v-if="link" class="label">Address</span>
          <span v-if="link" class="value wrap mono">{{ link }}</span>
        </div>
      </div>

      <p v-if="error" class="fault">{{ error }}</p>

      <div class="actions">
        <button type="button" class="btn btn-ghost" @click="stop">Stop pairing</button>
        <button
          v-if="paired"
          type="button"
          class="btn btn-primary"
          @click="emit('hide')"
        >
          Done
        </button>
      </div>
    </div>
  </UiDialog>
</template>

<style scoped lang="scss">
.pair {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
  padding: var(--space-6);
}

.title {
  margin: 0;
  font-size: 22px;
}

.lede {
  margin: 0;
  font-size: 14px;
  color: color-mix(in srgb, var(--color-text) 70%, transparent);
}

.face {
  display: flex;
  gap: var(--space-6);
  align-items: center;
}

img {
  border: 2px solid var(--color-divider);
}

.waiting {
  display: grid;
  place-items: center;
  width: 220px;
  height: 220px;
  border: 2px solid var(--color-divider);
}

.side {
  display: grid;
  grid-template-columns: 1fr;
  gap: 2px;
  font-size: 14px;
}

.label {
  margin-top: var(--space-3);
  font-size: 11px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: color-mix(in srgb, var(--color-text) 55%, transparent);

  &:first-child {
    margin-top: 0;
  }
}

.code {
  font-size: 28px;
  font-weight: 700;
  letter-spacing: 0.14em;
}

.wrap {
  font-size: 12px;
  word-break: break-all;
}

.fault {
  margin: 0;
  font-size: 13px;
  color: var(--color-accent-700);
}

.done {
  color: var(--color-accent-700);
  font-weight: 600;
}

.live {
  font-weight: 700;
  color: var(--color-accent-700);
}

.actions {
  display: flex;
  gap: var(--space-3);
  align-items: center;
  justify-content: flex-end;
}

@media (max-width: 620px) {
  .face {
    flex-direction: column;
    align-items: flex-start;
  }
}
</style>
