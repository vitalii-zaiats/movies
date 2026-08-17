<script setup lang="ts">
// The phone: a control surface, plus enough of the catalogue to choose from.
//
// It stays anonymous on purpose. Browsing costs no identity — `GET /shows` and
// `GET /shows/{key}` ask nobody who they are — but `/auth/me`, `/playlists` and
// `/me/*` all mint a guest, so this page calls none of them, and `layout: false`
// keeps the nav (which asks) off it. A phone that walked in to press pause does
// not walk out with a watch history.
//
// It also never plays anything itself: it names an episode and the screen opens
// it. The video belongs on the television.

import { IDLE_STATE, commands, isCode, type ServerMessage } from '~/lib/hub/protocol'
import type { ShowSummary, ShowWithEpisodes } from '~/types/catalogue'

definePageMeta({ layout: false })

const route = useRoute()
const catalogue = useCatalogue()
const code = String(route.params.code ?? '').toUpperCase()
const known = isCode(code)

const state = ref({ ...IDLE_STATE })

const { status, peers, error, send } = useHub({
  role: 'remote',
  code,
  onMessage(message: ServerMessage) {
    if (message.type === 'state') state.value = message.state
  },
})

const connected = computed(() => status.value === 'open' && peers.value.displays > 0)
const tab = ref<'now' | 'browse'>('now')

// --- the catalogue, as much of it as a phone needs ------------------------
const query = ref('')
const results = ref<ShowSummary[]>([])
const opened = ref<ShowWithEpisodes | null>(null)
const looking = ref(false)

async function look(): Promise<void> {
  looking.value = true
  try {
    const page = await catalogue.shows({
      q: query.value.trim() || undefined,
      order: query.value.trim() ? 'title' : 'added',
      limit: 30,
    })
    results.value = page.items
  } finally {
    looking.value = false
  }
}

let typing: ReturnType<typeof setTimeout> | undefined
watch(query, () => {
  clearTimeout(typing)
  typing = setTimeout(look, 300)
})

onMounted(() => {
  if (known) void look()
})

/** A film goes straight on; a series opens so a season and episode can be chosen. */
async function choose(show: ShowSummary): Promise<void> {
  const detail = await catalogue.show(show.key)
  if (detail.is_film) {
    const [episode] = detail.episodes
    if (episode?.playlist) start(episode.id)
    return
  }
  opened.value = detail
}

function start(episodeId: number): void {
  send(commands.play(episodeId))
  opened.value = null
  tab.value = 'now'
}

// --- the transport --------------------------------------------------------
const scrubbing = ref(false)
const scrub = ref(0)
const position = computed(() => (scrubbing.value ? scrub.value : state.value.position))

function clock(seconds: number): string {
  if (!Number.isFinite(seconds) || seconds <= 0) return '0:00'
  const whole = Math.floor(seconds)
  const minutes = Math.floor(whole / 60)
  const rest = String(whole % 60).padStart(2, '0')
  if (minutes < 60) return `${minutes}:${rest}`
  return `${Math.floor(minutes / 60)}:${String(minutes % 60).padStart(2, '0')}:${rest}`
}

function commit(): void {
  scrubbing.value = false
  send(commands.seek(scrub.value))
}
</script>

<template>
  <div class="remote">
    <header class="head">
      <span class="brand">LUMEN</span>
      <span class="state" :class="{ live: connected }">
        {{ connected ? 'connected' : status === 'rejected' ? 'code expired' : status }}
      </span>
    </header>

    <StateNote v-if="!known" tone="error" :message="`“${code}” is not a code.`" class="pad" />
    <StateNote v-else-if="error" tone="error" :message="error" class="pad" />

    <template v-else>
      <div class="seg tabs" role="group" aria-label="Mode">
        <label class="seg-opt">
          <input v-model="tab" type="radio" name="tab" value="now" >
          Now playing
        </label>
        <label class="seg-opt">
          <input v-model="tab" type="radio" name="tab" value="browse" >
          Browse
        </label>
      </div>

      <!-- ── now playing ─────────────────────────────────────────────── -->
      <template v-if="tab === 'now'">
        <section class="now">
          <p class="show">{{ state.show ?? '—' }}</p>
          <h1 class="title">{{ state.title ?? 'Nothing is playing' }}</h1>
          <p v-if="state.code" class="episode mono">{{ state.code }}</p>
          <button v-if="state.idle" type="button" class="btn btn-secondary pick" @click="tab = 'browse'">
            {{ state.resume.length ? 'Carry on with something' : 'Pick something' }}
          </button>
        </section>

        <section class="scrub">
          <input
            class="range"
            type="range"
            min="0"
            :max="Math.max(1, state.duration)"
            :value="position"
            :disabled="state.idle"
            aria-label="Position"
            @pointerdown="scrubbing = true"
            @input="scrub = Number(($event.target as HTMLInputElement).value)"
            @change="commit"
          >
          <div class="times mono">
            <span>{{ clock(position) }}</span>
            <span>{{ clock(state.duration) }}</span>
          </div>
        </section>

        <section class="transport">
          <button type="button" class="btn btn-secondary big" :disabled="state.idle" @click="send(commands.skip(-10))">
            −10s
          </button>
          <button type="button" class="btn btn-primary big" :disabled="state.idle" @click="send(commands.toggle())">
            {{ state.playing ? 'Pause' : 'Play' }}
          </button>
          <button type="button" class="btn btn-secondary big" :disabled="state.idle" @click="send(commands.skip(30))">
            +30s
          </button>
        </section>

        <section class="row">
          <button type="button" class="btn btn-secondary" :disabled="state.idle" @click="send(commands.prev())">
            ← Previous
          </button>
          <button type="button" class="btn btn-secondary" :disabled="state.idle" @click="send(commands.next())">
            Next →
          </button>
        </section>

        <section class="row">
          <button type="button" class="btn btn-ghost" :disabled="state.idle" @click="send(commands.mute(!state.muted))">
            {{ state.muted ? 'Unmute' : 'Mute' }}
          </button>
          <input
            class="range"
            type="range"
            min="0"
            max="1"
            step="0.05"
            :value="state.volume"
            :disabled="state.idle"
            aria-label="Volume"
            @change="send(commands.volume(Number(($event.target as HTMLInputElement).value)))"
          >
        </section>

        <p v-if="state.error" class="fault">{{ state.error }}</p>
      </template>

      <!-- ── browse ──────────────────────────────────────────────────── -->
      <template v-else>
        <!-- Sent by the screen, because history lives behind an identity and a
             remote hasn't got one. See `DisplayState.resume`. -->
        <section v-if="state.resume.length && !opened && !query" class="resume">
          <h2 class="heading">Continue watching</h2>
          <ul class="list">
            <li v-for="entry in state.resume" :key="entry.episodeId">
              <button type="button" class="entry" @click="start(entry.episodeId)">
                <span class="bar" :style="{ '--at': `${Math.round((entry.ratio ?? 0) * 100)}%` }" />
                <span class="entry-title">{{ entry.title }}</span>
                <span class="muted">
                  {{ entry.code ?? entry.show }}
                  <template v-if="entry.ratio"> · {{ Math.round(entry.ratio * 100) }}%</template>
                </span>
              </button>
            </li>
          </ul>
        </section>

        <input
          v-model="query"
          class="input"
          type="search"
          placeholder="Search the catalogue…"
          aria-label="Search"
        >

        <!-- A series opens into its episodes; everything else plays on tap. -->
        <template v-if="opened">
          <div class="opened">
            <button type="button" class="btn btn-ghost back" @click="opened = null">← Back</button>
            <span class="opened-title">{{ opened.title }}</span>
          </div>
          <ul class="list">
            <li v-for="episode in opened.episodes" :key="episode.id">
              <button
                type="button"
                class="entry"
                :disabled="!episode.playlist"
                @click="start(episode.id)"
              >
                <span class="mono tag-code">{{ episodeCode(episode) }}</span>
                <span class="entry-title">{{ episodeName(episode) ?? '—' }}</span>
                <span v-if="!episode.playlist" class="muted">no stream</span>
              </button>
            </li>
          </ul>
        </template>

        <template v-else>
          <p v-if="looking" class="muted">Looking…</p>
          <ul v-else class="list">
            <li v-for="show in results" :key="show.key">
              <button type="button" class="entry" @click="choose(show)">
                <img v-if="show.poster" :src="show.poster" alt="" class="thumb" loading="lazy" >
                <span v-else class="thumb blank" />
                <span class="entry-title">{{ show.title }}</span>
                <span class="muted">{{ show.episode_count === 1 ? 'film' : `${show.episode_count} eps` }}</span>
              </button>
            </li>
          </ul>
        </template>
      </template>

      <p class="note">Code {{ code }} · this phone stays anonymous</p>
    </template>
  </div>
</template>

<style scoped lang="scss">
.remote {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
  min-height: 100vh;
  padding: var(--space-5);
  background: var(--color-bg);
}

.head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 13px;
  font-weight: 700;
}

.brand {
  letter-spacing: 0.14em;
}

.state {
  color: color-mix(in srgb, var(--color-text) 55%, transparent);

  &.live {
    color: var(--color-accent);
  }
}

.tabs {
  align-self: stretch;
}

.pad {
  margin-top: var(--space-6);
}

.now {
  margin-top: var(--space-2);
}

.show {
  margin: 0;
  font-size: 12px;
  font-weight: 700;
  color: var(--color-accent-700);
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.title {
  margin: var(--space-2) 0 0;
  font-size: 24px;
  line-height: 1.15;
}

.episode {
  margin: var(--space-2) 0 0;
  font-size: 13px;
  color: color-mix(in srgb, var(--color-text) 60%, transparent);
}

.pick {
  margin-top: var(--space-4);
}

.scrub {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.range {
  width: 100%;
  accent-color: var(--color-accent);
}

.times {
  display: flex;
  justify-content: space-between;
  font-size: 12px;
  color: color-mix(in srgb, var(--color-text) 60%, transparent);
}

.transport {
  display: grid;
  grid-template-columns: 1fr 1.4fr 1fr;
  gap: var(--space-3);
}

// A thumb finds these in the dark; a mouse never has to.
.big {
  min-height: 64px;
  font-size: 16px;
}

.row {
  display: flex;
  gap: var(--space-3);
  align-items: center;

  > * {
    flex: 1;
  }
}

.list {
  display: flex;
  flex-direction: column;
  padding: 0;
  margin: 0;
  list-style: none;
  border-top: 1px solid var(--color-divider);
}

.resume {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.heading {
  margin: 0;
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: color-mix(in srgb, var(--color-text) 55%, transparent);
}

// How far in, as a rule under the row rather than a number nobody reads.
.bar {
  flex: none;
  width: 4px;
  align-self: stretch;
  background: linear-gradient(
    to top,
    var(--color-accent) var(--at, 0%),
    color-mix(in srgb, var(--color-text) 18%, transparent) var(--at, 0%)
  );
}

.entry {
  display: flex;
  gap: var(--space-3);
  align-items: center;
  width: 100%;
  min-height: 56px;
  padding: var(--space-2) 0;
  font: inherit;
  font-size: 15px;
  color: inherit;
  text-align: left;
  cursor: pointer;
  background: none;
  border: 0;
  border-bottom: 1px solid var(--color-divider);

  &:disabled {
    opacity: 0.5;
  }
}

.thumb {
  flex: none;
  width: 36px;
  height: 54px;
  object-fit: cover;
  background: var(--color-neutral-900);
}

.blank {
  display: block;
}

.entry-title {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.tag-code {
  flex: none;
  font-size: 13px;
  color: var(--color-accent-700);
}

.muted {
  flex: none;
  font-size: 12px;
  color: color-mix(in srgb, var(--color-text) 55%, transparent);
}

.opened {
  display: flex;
  gap: var(--space-3);
  align-items: center;
}

.back {
  padding: 0;
}

.opened-title {
  font-weight: 700;
}

.fault {
  margin: 0;
  font-size: 13px;
  color: var(--color-accent-700);
}

.note {
  margin: auto 0 0;
  font-size: 12px;
  color: color-mix(in srgb, var(--color-text) 50%, transparent);
}
</style>
