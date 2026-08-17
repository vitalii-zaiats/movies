<script setup lang="ts">
// The player. Safari reads HLS natively; everywhere else hls.js does, and it is
// imported only when a stream is actually attached — no reason to ship 400 kB to
// someone who is only browsing.

import type Hls from 'hls.js'

const props = withDefaults(
  defineProps<{
    /** `{vod_url}/index.m3u8`. Null when there is nothing to attach. */
    src: string | null
    poster?: string | null
    artKey: string
    /** Shown over the placeholder. Why there is no stream is the caller's to say. */
    note?: string
    /** Seconds to open at, from wherever this was left. */
    start?: number
    /**
     * The dubs this episode has, when it has more than one. The player owns the
     * choice because it owns the source: switching voice is switching stream.
     */
    tracks?: { vod_id: number; audio: string | null; playlist: string }[]
    /**
     * Start as soon as there's something to start.
     *
     * Timing is the whole trick: a `play()` before the manifest is attached has
     * nothing to play and does nothing. So this is honoured at the end of the
     * attach, not by whoever asked for it.
     */
    autoplay?: boolean
  }>(),
  {
    poster: null,
    note: 'no stream — this episode was never packaged',
    start: 0,
    autoplay: false,
    tracks: () => [],
  },
)

const emit = defineEmits<{
  /** Where the playhead is. Throttled — this is a bookmark, not telemetry. */
  progress: [{ position: number; duration: number | null }]
  ended: [{ duration: number | null }]
  /** Everything a remote needs to draw itself. Cheap, so it goes out often. */
  status: [
    { playing: boolean; position: number; duration: number; volume: number; muted: boolean },
  ]
  /** The browser refused to start on its own. Somebody has to touch the screen. */
  blocked: []
}>()

// A resume point that lands on the closing seconds is worse than none: it drops
// you at the credits of something you finished.
const TAIL = 20
// How often a position is worth writing down. Ten seconds of lost place is
// nothing; a request per frame is not.
const EVERY = 10

// Which voice is playing. `null` means whatever the episode came with, and
// changing it swaps the source under the player — so the position is kept and
// handed back, or every switch would restart the episode.
const voice = ref<string | null>(null)

const dubs = computed(() => props.tracks.filter((track) => track.audio))
const source = computed(() => {
  const chosen = props.tracks.find((track) => track.audio === voice.value)
  return chosen ? chosen.playlist : props.src
})

const video = ref<HTMLVideoElement | null>(null)
const problem = ref<string | null>(null)
let engine: Hls | null = null
let reported = 0

/**
 * The ladder this stream actually offers, read off the manifest.
 *
 * Nothing here is invented: a stream with one rung gets no control at all, and
 * Safari — which plays HLS itself and exposes no way to pick a variant — gets
 * none either. Offering a choice that does nothing is worse than offering none.
 */
interface Rung {
  index: number
  label: string
}

const rungs = ref<Rung[]>([])
/** -1 is auto, which is also hls.js's word for it. */
const chosen = ref(-1)
/** What auto settled on, so "Auto" can say what it's actually doing. */
const playing = ref<string | null>(null)

function label(level: { height?: number; bitrate?: number }): string {
  if (level.height) return `${level.height}p`
  return level.bitrate ? `${Math.round(level.bitrate / 1000)}k` : 'stream'
}

function choose(index: number): void {
  chosen.value = index
  // `currentLevel` switches now rather than at the next segment: somebody who
  // just asked for 1080p wants to see 1080p, not agree to it for later.
  if (engine) engine.currentLevel = index
}

function duration(element: HTMLVideoElement): number | null {
  return Number.isFinite(element.duration) && element.duration > 0 ? element.duration : null
}

function opened(): void {
  const element = video.value
  if (!element) return

  announce()

  const total = duration(element)
  const wanted = props.start
  if (wanted > 0 && (total === null || wanted < total - TAIL)) {
    element.currentTime = wanted
  }
}

function ticked(): void {
  const element = video.value
  if (!element) return

  // The remote wants the clock; the bookmark only wants it every ten seconds.
  announce()

  if (element.seeking) return
  if (Math.abs(element.currentTime - reported) < EVERY) return

  reported = element.currentTime
  emit('progress', { position: element.currentTime, duration: duration(element) })
}

/** On pause and on leaving: the two moments a place is most worth keeping. */
function paused(): void {
  const element = video.value
  if (!element) return

  reported = element.currentTime
  emit('progress', { position: element.currentTime, duration: duration(element) })
}

function finished(): void {
  const element = video.value
  emit('ended', { duration: element ? duration(element) : null })
}

/** The whole picture, for whoever is watching from a phone. */
function announce(): void {
  const element = video.value
  if (!element) return

  emit('status', {
    playing: !element.paused && !element.ended,
    position: element.currentTime,
    duration: duration(element) ?? 0,
    volume: element.volume,
    muted: element.muted,
  })
}

// What a remote is allowed to do to this player. Deliberately small: transport
// only, no source switching — choosing what to watch stays with the screen.
defineExpose({
  /**
   * Start it, and admit it when the browser says no.
   *
   * Autoplay with sound needs a gesture in *this* document, and a phone's tap
   * happened in another one — so a remote asking for playback is exactly the
   * case that gets refused. Saying so beats a silent nothing.
   */
  async play(): Promise<boolean> {
    const element = video.value
    if (!element) return false
    try {
      await element.play()
      return true
    } catch {
      emit('blocked')
      return false
    }
  },
  toggle(): void {
    const element = video.value
    if (!element) return
    if (element.paused) void element.play().catch(() => emit('blocked'))
    else element.pause()
  },
  pause(): void {
    video.value?.pause()
  },
  seek(seconds: number): void {
    const element = video.value
    if (element) element.currentTime = Math.max(0, seconds)
  },
  skip(delta: number): void {
    const element = video.value
    if (element) element.currentTime = Math.max(0, element.currentTime + delta)
  },
  setVolume(level: number): void {
    const element = video.value
    if (element) element.volume = Math.min(1, Math.max(0, level))
  },
  setMuted(muted: boolean): void {
    const element = video.value
    if (element) element.muted = muted
  },
})

function detach(): void {
  engine?.destroy()
  engine = null
  rungs.value = []
  chosen.value = -1
  playing.value = null
}

async function attach(src: string): Promise<void> {
  detach()
  problem.value = null

  const element = video.value
  if (!element) return

  if (element.canPlayType('application/vnd.apple.mpegurl')) {
    element.src = src
    await started(element)
    return
  }

  const { default: HlsEngine } = await import('hls.js')
  if (!HlsEngine.isSupported()) {
    problem.value = 'This browser cannot play HLS.'
    return
  }

  engine = new HlsEngine({ enableWorker: true })

  engine.on(HlsEngine.Events.MANIFEST_PARSED, () => {
    const levels = engine?.levels ?? []
    rungs.value = levels
      .map((level, index) => ({ index, label: label(level), height: level.height ?? 0 }))
      // Best first: it's the order people read a quality menu in.
      .sort((a, b) => b.height - a.height)
      .map(({ index, label: text }) => ({ index, label: text }))
    chosen.value = engine?.currentLevel ?? -1
  })

  engine.on(HlsEngine.Events.LEVEL_SWITCHED, (_event, data) => {
    const level = engine?.levels?.[data.level]
    playing.value = level ? label(level) : null
  })

  engine.on(HlsEngine.Events.ERROR, (_event, data) => {
    // Only fatal ones are worth a message; hls.js recovers from the rest on its
    // own and saying so would just make the page flicker.
    if (data.fatal) problem.value = `${data.type}: ${data.details}`
  })
  engine.loadSource(src)
  engine.attachMedia(element)
  await started(element)
}

/** Attached, therefore playable — the only moment `autoplay` can mean anything. */
async function started(element: HTMLVideoElement): Promise<void> {
  if (!props.autoplay) return
  try {
    await element.play()
  } catch {
    // Some browsers want a gesture in this document first. Say so; don't sulk.
    emit('blocked')
  }
}

// Not `immediate`: an immediate watcher runs during setup, before the template
// exists, so `video` is still null and the attach quietly does nothing — which
// is exactly how a player ends up showing controls and playing silence. The
// first attach belongs on mount; the watcher is only for the src changing after.
watch(source, (next, previous) => {
  if (!next) {
    detach()
    return
  }

  // A voice swap should carry on where the last one stopped; a new episode
  // should not, and it arrives with `start` instead.
  const at = previous && previous !== next ? (video.value?.currentTime ?? 0) : 0
  reported = 0
  void attach(next).then(() => {
    if (at > 1 && video.value) video.value.currentTime = at
  })
}, { flush: 'post' })

// Walking away is the commonest way to stop watching, and it fires no `pause`.
onMounted(() => {
  if (source.value) void attach(source.value)
  window.addEventListener('pagehide', paused)
})
onBeforeUnmount(() => {
  window.removeEventListener('pagehide', paused)
  paused()
  detach()
})
</script>

<template>
  <div class="player">
    <video
      v-if="src"
      ref="video"
      controls
      playsinline
      :poster="poster ?? undefined"
      @loadedmetadata="opened"
      @timeupdate="ticked"
      @pause="paused"
      @ended="finished"
      @play="announce"
      @volumechange="announce"
    />

    <div v-if="src && (rungs.length > 1 || dubs.length > 1)" class="bar">
      <template v-if="dubs.length > 1">
        <label class="visually-hidden" for="voice">Voice</label>
        <select
          id="voice"
          class="input quality"
          :value="voice ?? ''"
          @change="voice = ($event.target as HTMLSelectElement).value || null"
        >
          <option value="">Default voice</option>
          <option v-for="track in dubs" :key="track.vod_id" :value="track.audio!">
            {{ track.audio }}
          </option>
        </select>
      </template>

      <label class="visually-hidden" for="quality">Quality</label>
      <select
        v-if="rungs.length > 1"
        id="quality"
        class="input quality"
        :value="chosen"
        @change="choose(Number(($event.target as HTMLSelectElement).value))"
      >
        <option :value="-1">Auto{{ playing ? ` · ${playing}` : '' }}</option>
        <option v-for="rung in rungs" :key="rung.index" :value="rung.index">
          {{ rung.label }}
        </option>
      </select>
    </div>

    <ArtFrame v-else-if="!src" :art-key="artKey" :poster="poster" drained>
      <span class="empty mono">{{ note }}</span>
    </ArtFrame>

    <p v-if="problem" class="problem mono">{{ problem }}</p>
  </div>
</template>

<style scoped lang="scss">
.player {
  background: var(--color-neutral-900);
}

video {
  display: block;
  width: 100%;
  aspect-ratio: 16 / 9;
  background: #000;
}

.empty {
  position: absolute;
  bottom: var(--space-4);
  left: var(--space-4);
  padding: 6px 12px;
  color: var(--color-ink-text);
  background: rgb(20 18 17 / 80%);
}

.problem {
  padding: var(--space-3) var(--space-4);
  margin: 0;
  color: var(--color-ink-text);
  background: var(--color-accent-700);
}

// Under the video rather than over it: the native controls own that strip, and
// two rows of chrome fighting for the same corner is how a player gets ugly.
.bar {
  display: flex;
  gap: var(--space-2);
  justify-content: flex-end;
  padding: var(--space-2) var(--space-3);
  background: var(--color-neutral-900);
}

.quality {
  width: auto;
  min-height: 30px;
  padding: 3px 8px;
  font-size: 13px;
  color: var(--color-ink-text);
  background: color-mix(in srgb, var(--color-ink-text) 12%, transparent);
  border-color: color-mix(in srgb, var(--color-ink-text) 30%, transparent);
}
</style>
