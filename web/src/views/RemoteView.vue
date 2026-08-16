<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useHub } from '../lib/useHub'
import { IDLE_STATE, commands, isCode } from '../lib/protocol'
import type { DisplayState, ServerMessage } from '../lib/protocol'
import { api } from '../lib/api'
import type { Playlist, PlaylistDetail } from '../lib/api'
import { forget, keys, recall, remember } from '../lib/storage'

const SKIPS = [-30, -10, 10, 30]

const route = useRoute()
const router = useRouter()

const routeCode = String(route.params.code ?? '').toUpperCase()
// The URL wins; otherwise fall back to the code this phone paired with before,
// so the QR is a one-time thing rather than a ritual.
const savedCode = recall<string>(keys.remoteCode) ?? ''
const activeCode = isCode(routeCode) ? routeCode : isCode(savedCode) ? savedCode : ''
const joined = ref(isCode(activeCode))

const typed = ref('')
const screen = ref<DisplayState>({ ...IDLE_STATE })
const playlists = ref<Playlist[]>([])
const open = ref<PlaylistDetail | null>(null)
const filter = ref('')
const loadError = ref<string | null>(null)

// While a finger is on a slider, reports from the screen must not fight it.
const scrubbing = ref(false)
const scrub = ref(0)
const sliding = ref(false)
const slide = ref(1)

const hub = joined.value ? useHub({ role: 'remote', code: activeCode, onMessage: track }) : null

const status = computed(() => hub?.status.value ?? 'closed')
const error = computed(() => hub?.error.value ?? null)
const live = computed(() => status.value === 'open')
const hasQueue = computed(() => screen.value.total > 0)
const position = computed(() => (scrubbing.value ? scrub.value : screen.value.position))
const volume = computed(() => (sliding.value ? slide.value : screen.value.volume))

const episodes = computed(() => {
  const items = open.value?.items ?? []
  const needle = filter.value.trim().toLowerCase()
  return needle
    ? items.filter((item) => item.episode.title.toLowerCase().includes(needle))
    : items
})

/** True only for the episode the screen is on, and only in its own playlist. */
function isCurrent(position_: number): boolean {
  return screen.value.playlistId === open.value?.id && screen.value.index === position_
}

function track(message: ServerMessage): void {
  if (message.type === 'state') screen.value = message.state
}

function send(message: ReturnType<typeof commands.toggle>): void {
  hub?.send(message)
}

async function show(id: number): Promise<void> {
  try {
    open.value = await api.playlist(id)
    filter.value = ''
  } catch (cause) {
    loadError.value = (cause as Error).message
  }
}

function playFrom(index: number): void {
  if (open.value) send(commands.play(open.value.id, index))
}

function commitSeek(): void {
  send(commands.seek(scrub.value))
  scrubbing.value = false
}

function commitVolume(): void {
  send(commands.volume(slide.value))
  sliding.value = false
}

function clock(seconds: number): string {
  if (!Number.isFinite(seconds) || seconds <= 0) return '0:00'
  const total = Math.floor(seconds)
  const minutes = Math.floor(total / 60)
  return `${minutes}:${String(total % 60).padStart(2, '0')}`
}

function join(): void {
  const code = typed.value.trim().toUpperCase()
  if (isCode(code)) router.push(`/r/${code}`).then(() => location.reload())
}

// Follow the screen: if it starts a playlist we aren't showing, show it.
watch(
  () => screen.value.playlistId,
  (id) => {
    if (id && id !== open.value?.id) void show(id)
  },
)

watch(status, (value) => {
  if (value === 'open') remember(keys.remoteCode, activeCode)
  // A code the hub refuses is a code worth forgetting, or we'd retry it forever.
  if (value === 'rejected') {
    forget(keys.remoteCode)
    joined.value = false
  }
})

onMounted(async () => {
  if (!joined.value) return
  // Paired from memory: put the code in the URL so the page stays shareable.
  if (routeCode !== activeCode) void router.replace(`/r/${activeCode}`)

  try {
    playlists.value = await api.playlists()
  } catch (cause) {
    loadError.value = `catalogue: ${(cause as Error).message}`
  }
})
</script>

<template>
  <section class="remote">
    <template v-if="!joined">
      <h1>Enter the code</h1>
      <p class="lede">It's on the screen, under the QR.</p>
      <form class="join" @submit.prevent="join">
        <input
          v-model="typed"
          class="join__input"
          maxlength="6"
          autocapitalize="characters"
          autocomplete="off"
          placeholder="ABC123"
          aria-label="pairing code"
        />
        <button class="join__go" type="submit" :disabled="!isCode(typed)">Pair</button>
      </form>
    </template>

    <template v-else>
      <header class="head">
        <h1>Remote</h1>
        <p class="status" :data-status="status">
          <template v-if="error">{{ error }}</template>
          <template v-else>{{ status === 'open' ? activeCode : status }}</template>
        </p>
      </header>

      <article class="now">
        <p class="now__title">{{ screen.title ?? 'nothing playing' }}</p>
        <p class="now__meta">
          <template v-if="hasQueue">
            {{ screen.playlistName }} · {{ screen.index + 1 }} / {{ screen.total }}
          </template>
          <template v-else>pick an episode below</template>
        </p>

        <input
          class="slider"
          type="range"
          min="0"
          :max="Math.max(screen.duration, 1)"
          step="1"
          :value="position"
          :disabled="!live || !hasQueue"
          aria-label="position"
          @input="scrubbing = true; scrub = Number(($event.target as HTMLInputElement).value)"
          @change="commitSeek"
        />
        <p class="times">
          <span>{{ clock(position) }}</span>
          <span>{{ clock(screen.duration) }}</span>
        </p>

        <div class="skips">
          <button
            v-for="delta in SKIPS"
            :key="delta"
            type="button"
            :disabled="!live || !hasQueue"
            @click="send(commands.skip(delta))"
          >
            {{ delta > 0 ? `+${delta}s` : `${delta}s` }}
          </button>
        </div>

        <div class="transport">
          <button :disabled="!live || !hasQueue" type="button" @click="send(commands.prev())">
            ⏮
          </button>
          <button
            class="transport__main"
            :disabled="!live || !hasQueue"
            type="button"
            @click="send(commands.toggle())"
          >
            {{ screen.playing ? '⏸' : '▶' }}
          </button>
          <button :disabled="!live || !hasQueue" type="button" @click="send(commands.next())">
            ⏭
          </button>
          <button :disabled="!live || !hasQueue" type="button" @click="send(commands.stop())">
            ⏹
          </button>
        </div>

        <div class="volume">
          <button
            class="volume__mute"
            type="button"
            :disabled="!live"
            @click="send(commands.mute(!screen.muted))"
          >
            {{ screen.muted || volume === 0 ? '🔇' : '🔊' }}
          </button>
          <input
            class="slider"
            type="range"
            min="0"
            max="1"
            step="0.05"
            :value="volume"
            :disabled="!live"
            aria-label="volume"
            @input="sliding = true; slide = Number(($event.target as HTMLInputElement).value)"
            @change="commitVolume"
          />
          <span class="volume__value">{{ Math.round(volume * 100) }}</span>
          <button
            class="volume__mute"
            type="button"
            :disabled="!live"
            :title="screen.fullscreen ? 'leave fullscreen' : 'fullscreen'"
            @click="send(commands.fullscreen(!screen.fullscreen))"
          >
            {{ screen.fullscreen ? '⤡' : '⛶' }}
          </button>
        </div>

        <p v-if="screen.error" class="fault">{{ screen.error }}</p>
      </article>

      <h2>Playlists</h2>
      <p v-if="loadError" class="fault">{{ loadError }}</p>
      <ul class="playlists">
        <li v-for="playlist in playlists" :key="playlist.id">
          <button
            class="playlist"
            :class="{ 'playlist--on': open?.id === playlist.id }"
            :disabled="!live"
            type="button"
            @click="show(playlist.id)"
          >
            <span>{{ playlist.name }}</span>
            <span class="playlist__count">{{ playlist.count }}</span>
          </button>
        </li>
      </ul>

      <template v-if="open">
        <h2>{{ open.name }}</h2>
        <div class="tools">
          <input v-model="filter" class="tools__filter" placeholder="filter episodes" />
          <button class="tools__go" type="button" :disabled="!live" @click="playFrom(0)">
            play all
          </button>
        </div>

        <ul class="episodes">
          <li v-for="item in episodes" :key="item.id">
            <button
              class="episode"
              :class="{ 'episode--on': isCurrent(item.position) }"
              :disabled="!live || !item.episode.playlist"
              type="button"
              @click="playFrom(item.position)"
            >
              <span class="episode__pos">{{ item.position + 1 }}</span>
              <span class="episode__title">{{ item.episode.title }}</span>
              <span v-if="isCurrent(item.position)" class="episode__now">▶</span>
            </button>
          </li>
          <li v-if="!episodes.length" class="empty">nothing matches</li>
        </ul>
      </template>
    </template>
  </section>
</template>

<style scoped lang="scss">
@use '../styles/tokens' as *;

.remote {
  display: flex;
  flex-direction: column;
  gap: $gap-sm;
  max-width: 30rem;
  margin: 0 auto;
  padding: $gap-lg;
}

.head {
  display: flex;
  gap: $gap-sm;
  align-items: baseline;
  justify-content: space-between;
}

h1 {
  margin: 0;
  font-size: 1.3rem;
}

h2 {
  margin: $gap-sm 0 0;
  color: $muted;
  font-size: 0.9rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.lede {
  margin: 0 0 $gap-sm;
  color: $muted;
}

.status {
  margin: 0;
  color: $muted;
  font-family: $mono;
  font-size: 0.85rem;
  letter-spacing: 0.12em;

  &[data-status='open'] {
    color: $accent;
  }

  &[data-status='rejected'] {
    color: $danger;
  }
}

.join {
  display: flex;
  gap: $gap-sm;

  &__input {
    flex: 1;
    padding: 0.75rem;
    color: inherit;
    font-family: $mono;
    font-size: 1.4rem;
    letter-spacing: 0.3em;
    text-align: center;
    text-transform: uppercase;
    background: $surface;
    border: 1px solid $line;
    border-radius: $radius-sm;
  }

  &__go {
    padding: 0 1.2rem;
    color: $bg;
    font: inherit;
    font-weight: 600;
    background: $accent;
    border: none;
    border-radius: $radius-sm;

    &:disabled {
      opacity: 0.4;
    }
  }
}

.now {
  padding: $gap-lg;
  background: $surface;
  border: 1px solid $line;
  border-radius: $radius-lg;

  &__title {
    margin: 0;
    font-size: 1.1rem;
    font-weight: 600;
  }

  &__meta {
    margin: 0.25rem 0 $gap-sm;
    color: $muted;
    font-size: 0.85rem;
  }
}

.slider {
  width: 100%;
  accent-color: $accent;
}

.times {
  display: flex;
  justify-content: space-between;
  margin: 0 0 $gap-sm;
  color: $muted;
  font-family: $mono;
  font-size: 0.8rem;
}

.skips {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 0.4rem;
  margin-bottom: 0.6rem;

  button {
    padding: 0.5rem 0;
    color: $muted;
    font: inherit;
    font-size: 0.8rem;
    background: $bg;
    border: 1px solid $line;
    border-radius: $radius-sm;

    &:disabled {
      opacity: 0.4;
    }
  }
}

.transport {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 0.5rem;

  button {
    padding: 0.9rem 0;
    color: inherit;
    font-size: 1.2rem;
    background: $bg;
    border: 1px solid $line;
    border-radius: $radius-sm;

    &:disabled {
      opacity: 0.4;
    }
  }

  &__main {
    color: $accent !important;
  }
}

.volume {
  display: flex;
  gap: 0.6rem;
  align-items: center;
  margin-top: $gap-sm;

  &__mute {
    padding: 0.4rem 0.6rem;
    font-size: 1rem;
    background: $bg;
    border: 1px solid $line;
    border-radius: $radius-sm;
  }

  &__value {
    min-width: 2.2rem;
    color: $muted;
    font-family: $mono;
    font-size: 0.8rem;
    text-align: right;
  }
}

.playlists,
.episodes {
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
  margin: 0;
  padding: 0;
  list-style: none;
}

.episodes {
  max-height: 22rem;
  overflow-y: auto;
}

.playlist,
.episode {
  display: flex;
  gap: $gap-sm;
  align-items: center;
  width: 100%;
  padding: 0.75rem 0.9rem;
  color: inherit;
  font: inherit;
  text-align: left;
  background: $surface;
  border: 1px solid $line;
  border-radius: $radius-sm;

  &:disabled {
    opacity: 0.45;
  }
}

.playlist {
  justify-content: space-between;

  &--on {
    border-color: $accent;
  }

  &__count {
    color: $muted;
    font-family: $mono;
    font-size: 0.8rem;
  }
}

.episode {
  padding: 0.6rem 0.9rem;

  &--on {
    border-color: $accent;
  }

  &__pos {
    min-width: 2.2rem;
    color: $muted;
    font-family: $mono;
    font-size: 0.78rem;
  }

  &__title {
    flex: 1;
    overflow-wrap: anywhere;
  }

  &__now {
    color: $accent;
  }
}

.tools {
  display: flex;
  gap: 0.5rem;

  &__filter {
    flex: 1;
    min-width: 0;
    padding: 0.55rem 0.7rem;
    color: inherit;
    font: inherit;
    background: $surface;
    border: 1px solid $line;
    border-radius: $radius-sm;
  }

  &__go {
    padding: 0.55rem 0.9rem;
    color: $bg;
    font: inherit;
    font-weight: 600;
    background: $accent;
    border: none;
    border-radius: $radius-sm;

    &:disabled {
      opacity: 0.45;
    }
  }
}

.empty {
  color: $muted;
  font-size: 0.9rem;
}

.fault {
  margin: $gap-sm 0 0;
  color: $danger;
  font-size: 0.85rem;
}
</style>
