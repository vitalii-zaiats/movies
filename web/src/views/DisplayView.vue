<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, useTemplateRef, watch } from 'vue'
import QRCode from 'qrcode'
import type HlsPlayer from 'hls.js'
import { useHub } from '../lib/useHub'
import { IDLE_STATE } from '../lib/protocol'
import type { DisplayState, ServerMessage } from '../lib/protocol'
import { api } from '../lib/api'
import type { Playlist, PlaylistItem } from '../lib/api'
import { forget, keys, recall, remember } from '../lib/storage'

/** Enough to put the screen back exactly where it was after a reload. */
interface Snapshot {
  playlistId: number
  index: number
  position: number
  volume: number
  muted: boolean
}

const SAVE_EVERY_MS = 5000

const stage = useTemplateRef<HTMLElement>('stage')
const video = useTemplateRef<HTMLVideoElement>('video')

const state = ref<DisplayState>({ ...IDLE_STATE })
const queue = ref<PlaylistItem[]>([])
const catalogue = ref<Playlist[]>([])
const qr = ref('')

// hls.js is ~180 kB gzipped and only the display ever needs it, so it's pulled
// in on first playback instead of in the bundle every phone downloads.
let hls: HlsPlayer | null = null
let reporter: number | undefined
let savedAt = 0
let resumeAt = 0

const { status, code, peers, error, send } = useHub({
  role: 'display',
  // Ask for the code we had last time so a phone that remembered it still works.
  code: recall<string>(keys.displayCode) ?? undefined,
  onMessage: handle,
})

const joinUrl = computed(() => (code.value ? `${location.origin}/r/${code.value}` : ''))
const idle = computed(() => queue.value.length === 0)

function report(): void {
  send({ type: 'state', state: { ...state.value } })
  save()
}

function save(force = false): void {
  if (!state.value.playlistId) return
  const now = Date.now()
  if (!force && now - savedAt < SAVE_EVERY_MS) return
  savedAt = now

  remember<Snapshot>(keys.displayPlayer, {
    playlistId: state.value.playlistId,
    index: state.value.index,
    position: state.value.position,
    volume: state.value.volume,
    muted: state.value.muted,
  })
}

async function handle(message: ServerMessage): Promise<void> {
  if (message.type === 'peers') return report() // a remote just joined: catch it up
  if (message.type !== 'command') return

  const args = message.args ?? {}
  switch (message.name) {
    case 'play':
      await load(Number(args.playlistId), Number(args.index ?? 0))
      break
    case 'toggle':
      toggle()
      break
    case 'next':
      await playAt(state.value.index + 1)
      break
    case 'prev':
      await playAt(state.value.index - 1)
      break
    case 'seek':
      if (video.value) video.value.currentTime = Number(args.position ?? 0)
      break
    case 'skip':
      skip(Number(args.delta ?? 0))
      break
    case 'volume':
      if (video.value) {
        video.value.volume = Math.max(0, Math.min(1, Number(args.level ?? 1)))
        video.value.muted = false
      }
      break
    case 'mute':
      if (video.value) video.value.muted = Boolean(args.muted)
      break
    case 'fullscreen':
      await setFullscreen(Boolean(args.on))
      break
    case 'background':
      state.value.background = String(args.color ?? IDLE_STATE.background)
      report()
      break
  }
}

function toggle(): void {
  if (video.value?.paused) void video.value.play().catch(() => {})
  else video.value?.pause()
}

function skip(delta: number): void {
  if (!video.value) return
  // Relative to where the screen really is, not to the remote's last report.
  const target = video.value.currentTime + delta
  video.value.currentTime = Math.max(0, Math.min(target, video.value.duration || target))
}

async function load(playlistId: number, index: number, at = 0): Promise<void> {
  try {
    const playlist = await api.playlist(playlistId)
    queue.value = playlist.items
    state.value.playlistId = playlist.id
    state.value.playlistName = playlist.name
    state.value.total = playlist.items.length
    state.value.error = null
    resumeAt = at
    await playAt(index)
  } catch (cause) {
    state.value.error = `playlist ${playlistId}: ${(cause as Error).message}`
    report()
  }
}

async function playAt(index: number): Promise<void> {
  const item = queue.value[index]
  if (!item) return stop() // ran off either end of the queue

  state.value.index = index
  state.value.title = item.episode.title
  state.value.position = resumeAt
  state.value.duration = 0
  state.value.error = item.episode.playlist ? null : 'this episode has no VOD'

  if (!item.episode.playlist || !video.value) return report()

  await attach(video.value, item.episode.playlist)
  video.value.volume = state.value.volume
  video.value.muted = state.value.muted

  try {
    await video.value.play()
  } catch {
    // Autoplay is refused until the screen gets one interaction; the native
    // controls are right there, so this is a pause, not a failure.
    state.value.playing = false
  }
  report()
}

/** Safari plays HLS natively; everyone else needs hls.js over MSE. */
async function attach(element: HTMLVideoElement, url: string): Promise<void> {
  hls?.destroy()
  hls = null

  if (element.canPlayType('application/vnd.apple.mpegurl')) {
    element.src = url
    return
  }

  const { default: Hls } = await import('hls.js')
  if (!Hls.isSupported()) {
    state.value.error = 'this browser cannot play HLS'
    return
  }

  hls = new Hls({ enableWorker: true })
  hls.loadSource(url)
  hls.attachMedia(element)
  hls.on(Hls.Events.ERROR, (_event, data) => {
    if (!data.fatal) return
    // Don't skip ahead on a fatal error: with a bad gateway that would race
    // through the whole queue in seconds.
    state.value.error = `${data.type}: ${data.details}`
    state.value.playing = false
    report()
  })
}

function stop(): void {
  hls?.destroy()
  hls = null
  video.value?.pause()
  video.value?.removeAttribute('src')
  video.value?.load()
  queue.value = []
  forget(keys.displayPlayer)
  state.value = {
    ...IDLE_STATE,
    background: state.value.background,
    volume: state.value.volume,
    muted: state.value.muted,
    fullscreen: state.value.fullscreen,
  }
  report()
}

async function setFullscreen(on: boolean): Promise<void> {
  try {
    if (on) await stage.value?.requestFullscreen()
    else if (document.fullscreenElement) await document.exitFullscreen()
  } catch {
    // Browsers only grant fullscreen on a gesture, so a remote can't force it.
    state.value.error = 'fullscreen needs a click on the screen itself — or press F there'
    report()
  }
}

function onFullscreenChange(): void {
  state.value.fullscreen = document.fullscreenElement !== null
  state.value.error = null
  report()
}

function onKey(event: KeyboardEvent): void {
  if (event.key === 'f' || event.key === 'F') void setFullscreen(!state.value.fullscreen)
}

function onPlay(): void {
  state.value.playing = true
  report()
  window.clearInterval(reporter)
  reporter = window.setInterval(() => {
    if (!video.value) return
    state.value.position = video.value.currentTime
    report()
  }, 1000)
}

function onPause(): void {
  state.value.playing = false
  window.clearInterval(reporter)
  save(true)
  report()
}

function onMeta(): void {
  state.value.duration = video.value?.duration ?? 0
  if (resumeAt > 0 && video.value) {
    video.value.currentTime = resumeAt // pick up where the last page left off
    resumeAt = 0
  }
  report()
}

function onVolume(): void {
  if (!video.value) return
  state.value.volume = video.value.volume
  state.value.muted = video.value.muted
  report()
}

watch(code, (value) => {
  if (value) remember(keys.displayCode, value)
})

watch(
  joinUrl,
  async (value) => {
    qr.value = value
      ? await QRCode.toString(value, { type: 'svg', margin: 0, color: { light: '#0000' } })
      : ''
  },
  { immediate: true },
)

onMounted(async () => {
  document.addEventListener('fullscreenchange', onFullscreenChange)
  window.addEventListener('keydown', onKey)
  window.addEventListener('beforeunload', () => save(true))

  const snapshot = recall<Snapshot>(keys.displayPlayer)
  if (snapshot) {
    state.value.volume = snapshot.volume
    state.value.muted = snapshot.muted
    // A reload is not a reset: same episode, same second.
    await load(snapshot.playlistId, snapshot.index, snapshot.position)
  }

  try {
    catalogue.value = await api.playlists()
  } catch (cause) {
    state.value.error = `catalogue: ${(cause as Error).message}`
  }
})

onBeforeUnmount(() => {
  window.clearInterval(reporter)
  document.removeEventListener('fullscreenchange', onFullscreenChange)
  window.removeEventListener('keydown', onKey)
  hls?.destroy()
})
</script>

<template>
  <section ref="stage" class="display" :style="{ '--stage': state.background }">
    <!-- Native controls on purpose: play, seek, volume and fullscreen that
         already work with a keyboard, a remote-control d-pad and a mouse. -->
    <video
      ref="video"
      class="video"
      :class="{ 'video--hidden': idle }"
      controls
      playsinline
      @play="onPlay"
      @pause="onPause"
      @loadedmetadata="onMeta"
      @volumechange="onVolume"
      @ended="playAt(state.index + 1)"
    />

    <div v-if="idle" class="idle">
      <aside class="pairing">
        <h1>Scan to pair</h1>
        <div v-if="qr" class="qr" v-html="qr" />
        <p class="code">{{ code ?? '······' }}</p>
        <p class="url">{{ joinUrl }}</p>
        <p class="status" :data-status="status">
          <template v-if="error">{{ error }}</template>
          <template v-else-if="status !== 'open'">{{ status }}</template>
          <template v-else-if="peers.remotes">
            {{ peers.remotes }} remote{{ peers.remotes > 1 ? 's' : '' }} connected
          </template>
          <template v-else>waiting for a remote</template>
        </p>
      </aside>

      <div class="picker">
        <h2>Or just start something</h2>
        <ul>
          <li v-for="playlist in catalogue" :key="playlist.id">
            <button type="button" @click="load(playlist.id, 0)">
              <span>{{ playlist.name }}</span>
              <span class="picker__count">{{ playlist.count }}</span>
            </button>
          </li>
          <li v-if="!catalogue.length" class="empty">no playlists yet — build one in /dashboard</li>
        </ul>
      </div>
    </div>

    <div v-else class="hud">
      <button type="button" title="previous" @click="playAt(state.index - 1)">⏮</button>
      <button type="button" title="next" @click="playAt(state.index + 1)">⏭</button>
      <button type="button" title="back to the list" @click="stop()">⏹</button>
      <span class="hud__title">{{ state.title }}</span>
      <span class="hud__meta">{{ state.index + 1 }} / {{ state.total }}</span>
      <button type="button" title="fullscreen (F)" @click="setFullscreen(!state.fullscreen)">
        {{ state.fullscreen ? '⤡' : '⛶' }}
      </button>
      <span class="hud__code">{{ code }}</span>
    </div>

    <p v-if="state.error" class="fault">{{ state.error }}</p>
  </section>
</template>

<style scoped lang="scss">
@use '../styles/tokens' as *;

.display {
  position: relative;
  min-height: 100dvh;
  background: var(--stage);
  transition: background 320ms ease;
}

.video {
  display: block;
  width: 100%;
  height: 100dvh;
  background: #000;
  object-fit: contain;

  &--hidden {
    display: none;
  }
}

.idle {
  display: flex;
  flex-wrap: wrap;
  gap: $gap-lg;
  align-items: flex-start;
  justify-content: center;
  min-height: 100dvh;
  padding: $gap-lg;
}

.pairing {
  display: flex;
  flex-direction: column;
  gap: $gap-sm;
  align-items: center;
  padding: $gap-lg;
  text-align: center;
  background: $surface;
  border: 1px solid $line;
  border-radius: $radius-lg;

  h1 {
    margin: 0;
    font-size: 1.1rem;
  }
}

.qr {
  width: min(14rem, 30vw);

  :deep(svg) {
    display: block;
    width: 100%;
    height: auto;
    fill: $fg;
  }
}

.code {
  margin: 0;
  font-family: $mono;
  font-size: 2rem;
  letter-spacing: 0.28em;
  text-indent: 0.28em;
}

.url,
.status {
  margin: 0;
  color: $muted;
  font-size: 0.85rem;
  overflow-wrap: anywhere;
}

.status[data-status='open'] {
  color: $accent;
}

.status[data-status='rejected'] {
  color: $danger;
}

.picker {
  flex: 1 1 22rem;
  max-width: 34rem;
  padding: $gap-lg;
  background: $surface;
  border: 1px solid $line;
  border-radius: $radius-lg;

  h2 {
    margin: 0 0 $gap-sm;
    color: $muted;
    font-size: 0.85rem;
    font-weight: 600;
    letter-spacing: 0.08em;
    text-transform: uppercase;
  }

  ul {
    display: flex;
    flex-direction: column;
    gap: 0.4rem;
    max-height: 60dvh;
    margin: 0;
    padding: 0;
    overflow-y: auto;
    list-style: none;
  }

  button {
    display: flex;
    gap: $gap-sm;
    align-items: center;
    justify-content: space-between;
    width: 100%;
    padding: 0.75rem 0.9rem;
    color: inherit;
    font: inherit;
    text-align: left;
    background: $bg;
    border: 1px solid $line;
    border-radius: $radius-sm;

    &:hover {
      border-color: $accent;
    }
  }

  &__count {
    color: $muted;
    font-family: $mono;
    font-size: 0.8rem;
  }
}

.empty {
  color: $muted;
  font-size: 0.9rem;
}

.hud {
  position: absolute;
  top: 0;
  right: 0;
  left: 0;
  display: flex;
  gap: 0.5rem;
  align-items: center;
  padding: $gap-sm $gap-lg;
  color: $fg;
  font-size: 0.9rem;
  background: linear-gradient(rgb(0 0 0 / 70%), transparent);
  opacity: 0.25;
  transition: opacity 200ms ease;

  &:hover,
  &:focus-within {
    opacity: 1;
  }

  button {
    padding: 0.3rem 0.6rem;
    color: inherit;
    font-size: 1rem;
    background: rgb(0 0 0 / 45%);
    border: 1px solid $line;
    border-radius: $radius-sm;
  }

  &__title {
    margin-left: 0.5rem;
    font-weight: 600;
  }

  &__meta {
    margin-right: auto; // pushes the fullscreen button and code to the right
    color: $muted;
  }

  &__code {
    color: $muted;
    font-family: $mono;
    letter-spacing: 0.2em;
  }
}

.fault {
  position: absolute;
  right: $gap-lg;
  bottom: 4.5rem;
  left: $gap-lg;
  margin: 0;
  color: $danger;
  text-align: center;
}
</style>
