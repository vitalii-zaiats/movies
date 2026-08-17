<script setup lang="ts">
// The player, and enough around it to keep going: what follows this episode in
// the queue it was opened from, or in its own season when it was opened alone.

import type { EpisodeWithShow } from '~/types/catalogue'

const route = useRoute()
const catalogue = useCatalogue()
// What a paired phone sees, and what it can ask for. The socket lives in the
// cast session; this page only speaks through the bus.
const cast = useCast()
const player = ref<{
  play: () => Promise<boolean>
  toggle: () => void
  pause: () => void
  seek: (seconds: number) => void
  skip: (delta: number) => void
  setVolume: (level: number) => void
  setMuted: (muted: boolean) => void
} | null>(null)

const id = computed(() => Number(route.params.id))
const queueId = computed(() => (route.query.playlist ? Number(route.query.playlist) : null))

const { data, pending, error } = await useAsyncData(
  () => `watch:${id.value}:${queueId.value ?? 'none'}`,
  async () => {
    const episode = await catalogue.episode(id.value)
    const queue = queueId.value === null ? null : await catalogue.playlist(queueId.value)
    // Whatever else is in this season, in order — the fallback for "next".
    const season = await catalogue.episodes({
      show: episode.show.key,
      season: episode.season,
      limit: 200,
    })
    // Where this was left, if it was. A guest has one of these too.
    const progress = await catalogue.progress(id.value)
    return { episode, queue, season: season.items, progress }
  },
  { watch: [id, queueId] },
)

/** Where the player opens. Read once per episode: it must not move mid-watch. */
const resumeAt = ref(0)
watch(
  data,
  (loaded) => {
    resumeAt.value = loaded?.progress && !loaded.progress.completed
      ? loaded.progress.position_seconds
      : 0
  },
  { immediate: true },
)

// Writes are the player's rhythm, not this page's: it reports every ten seconds
// and on every pause, and each report is the whole truth about where we are.
async function keepPlace(at: { position: number; duration: number | null }): Promise<void> {
  await catalogue
    .report(id.value, {
      position_seconds: at.position,
      duration_seconds: at.duration ?? undefined,
    })
    .catch(() => {
      // A lost bookmark is not worth interrupting a film for.
    })
}

// Opened from a phone: nobody is going to click here, so the player is told to
// start itself. It does that when the source is attached and not a moment
// earlier — asking sooner is asking a video with no manifest to play.
const fromPhone = computed(() => route.query.cast === '1')
const blocked = ref(false)

function refused(): void {
  blocked.value = true
  cast.report({ error: 'The screen blocked autoplay — tap it once to allow sound.' })
}

/** The screen's own report. The remote draws itself from exactly this. */
function announce(status: {
  playing: boolean
  position: number
  duration: number
  volume: number
  muted: boolean
}): void {
  const episode = data.value?.episode
  cast.report({
    ...status,
    idle: false,
    title: episode ? episodeHeading(episode) : null,
    show: episode?.show.title ?? null,
    code: episode && !episode.show.is_film ? episodeCode(episode) : null,
    error: blocked.value ? 'Tap the screen once to allow playback.' : null,
  })
}

// Transport only, and every one of them is a thing the player already does —
// the phone gets no say in what is playing, only in how it plays.
cast.onCommand((message) => {
  const controls = player.value
  if (!controls) return

  switch (message.name) {
    case 'toggle':
      return controls.toggle()
    case 'stop':
      return controls.pause()
    case 'skip':
      return controls.skip(Number(message.args?.delta ?? 0))
    case 'seek':
      return controls.seek(Number(message.args?.position ?? 0))
    case 'volume':
      return controls.setVolume(Number(message.args?.level ?? 1))
    case 'mute':
      return controls.setMuted(Boolean(message.args?.muted))
    case 'next':
      if (next.value) void navigateTo(keep(next.value.id))
      return
    case 'prev':
      if (previous.value) void navigateTo(keep(previous.value.id))
      return
  }
})

// Leaving the player behind means the phone should stop showing one.
onBeforeUnmount(() => cast.idle())

async function finished(at: { duration: number | null }): Promise<void> {
  await catalogue
    .report(id.value, {
      position_seconds: at.duration ?? 0,
      duration_seconds: at.duration ?? undefined,
      completed: true,
    })
    .catch(() => {})

  // Rolling on is what a queue is for; a film ends where it ends.
  if (next.value) await navigateTo(keep(next.value.id))
}

/** The queue's order if there is one, the season's if there isn't. */
const line = computed<EpisodeWithShow[]>(() => {
  if (!data.value) return []
  return data.value.queue
    ? data.value.queue.items.map((item) => item.episode)
    : data.value.season
})

const at = computed(() => line.value.findIndex((episode) => episode.id === id.value))
const next = computed(() => (at.value < 0 ? null : (line.value[at.value + 1] ?? null)))
const previous = computed(() => (at.value <= 0 ? null : (line.value[at.value - 1] ?? null)))
const ahead = computed(() => (at.value < 0 ? [] : line.value.slice(at.value + 1)))

function keep(id: number) {
  return queueId.value === null ? `/watch/${id}` : `/watch/${id}?playlist=${queueId.value}`
}

// Fixtures describe streams that nothing is serving; handing the player a URL
// that resolves to a 404 would only produce a scary error where a note belongs.
const source = computed(() =>
  catalogue.mocked ? null : (data.value?.episode.playlist ?? null),
)

const note = computed(() =>
  data.value?.episode.playlist
    ? 'fixtures — nothing is served at /vod yet'
    : 'no stream — this episode was never packaged',
)
</script>

<template>
  <div>
    <StateNote v-if="pending" message="Opening…" class="pad" />
    <StateNote v-else-if="error" tone="error" :message="error.message" class="pad" />

    <template v-else-if="data">
      <HlsPlayer
        :src="source"
        :note="note"
        :poster="data.episode.poster ?? data.episode.show.poster"
        :art-key="`${data.episode.show.key}-${data.episode.season}`"
        ref="player"
        :start="resumeAt"
        :tracks="data.episode.tracks"
        :autoplay="fromPhone"
        @progress="keepPlace"
        @status="announce"
        @ended="finished"
        @blocked="refused"
      />

      <!-- The one thing a phone cannot do for you: give this document a gesture. -->
      <button v-if="blocked" type="button" class="unblock" @click="player?.play(); blocked = false">
        Tap to start — this browser wants a click before it plays sound
      </button>

      <section class="section">
        <div class="section-head">
          <div>
            <NuxtLink :to="`/shows/${data.episode.show.key}`" class="show">
              {{ data.episode.show.title }}
            </NuxtLink>
            <h1 class="title">{{ episodeHeading(data.episode) }}</h1>
            <div class="meta-line">
              <span v-if="!data.episode.show.is_film" class="code">{{ episodeCode(data.episode) }}</span>
              <span v-if="data.queue">from “{{ data.queue.name }}”</span>
              <span v-if="!data.episode.playlist">no stream</span>
            </div>
          </div>

          <div class="actions">
            <NuxtLink v-if="previous" :to="keep(previous.id)" class="btn btn-secondary">
              ← {{ episodeCode(previous) }}
            </NuxtLink>
            <NuxtLink v-if="next" :to="keep(next.id)" class="btn btn-primary">
              Next · {{ episodeCode(next) }}
            </NuxtLink>
          </div>
        </div>
      </section>

      <CardRail v-if="ahead.length" :title="data.queue ? 'Later in the queue' : 'Rest of the season'">
        <EpisodeCard
          v-for="episode in ahead"
          :key="episode.id"
          :episode="episode"
          :with-show="false"
          @pick="navigateTo(keep($event.id))"
        />
      </CardRail>
    </template>
  </div>
</template>

<style scoped lang="scss">
.pad {
  margin: var(--space-8);
}

.unblock {
  display: block;
  width: 100%;
  padding: var(--space-4);
  font: inherit;
  font-weight: 700;
  color: var(--color-ink-text);
  cursor: pointer;
  background: var(--color-accent);
  border: 0;
}

.show {
  font-size: 13px;
  font-weight: 700;
  color: var(--color-accent-700);
  text-decoration: none;
  letter-spacing: 0.06em;
  text-transform: uppercase;
}

.title {
  margin: var(--space-2) 0;
  font-size: 32px;
}

.code {
  font-family: var(--font-mono);
}

.actions {
  display: flex;
  gap: var(--space-3);
  align-items: center;
}
</style>
