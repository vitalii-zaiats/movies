<script setup lang="ts">
// One show: what it is, which seasons arrived, and every episode as a line.

import type { Episode, EpisodeWithShow, Show } from '~/types/catalogue'

const route = useRoute()
const catalogue = useCatalogue()

const key = computed(() => String(route.params.key))

const { data: show, pending, error } = await useAsyncData(
  () => `show:${key.value}`,
  () => catalogue.show(key.value),
  { watch: [key] },
)

const season = ref<number | null>(null)
const seasons = computed(() => seasonsOf(show.value?.episodes ?? []))
const episodes = computed(() => show.value?.episodes ?? [])

const shown = computed(() =>
  episodes.value.filter((episode) => season.value === null || episode.season === season.value),
)
const playable = computed(() => shown.value.filter((episode) => episode.playlist !== null))

// The dialog wants the show attached; on this page it's the one thing we know.
function withShow(episode: Episode): EpisodeWithShow | null {
  if (!show.value) return null
  const { episodes: _episodes, ...bare } = show.value
  return { ...episode, show: bare as Show }
}

const queued = ref<EpisodeWithShow | null>(null)

const building = ref(false)
const problem = ref<string | null>(null)

/** The API builds the playlist server-side — it knows which episodes play. */
async function buildPlaylist(): Promise<void> {
  building.value = true
  problem.value = null
  try {
    const detail = await catalogue.playlistFromShow(key.value, season.value ?? undefined)
    await navigateTo(`/playlists/${detail.id}`)
  } catch (cause) {
    problem.value = (cause as Error).message
  } finally {
    building.value = false
  }
}
</script>

<template>
  <div>
    <StateNote v-if="pending" message="Reading the show…" class="pad" />
    <StateNote v-else-if="error" tone="error" :message="error.message" class="pad" />

    <template v-else-if="show">
      <section class="head">
        <ArtFrame :art-key="show.key" :poster="show.poster" variant="stripes" drained class="art" />

        <div class="about">
          <h1 class="title">{{ show.title }}</h1>

          <div class="meta-line">
            <span v-if="show.is_film">film</span>
            <template v-else>
              <span>{{ countLabel(seasons.length, 'season') }}</span>
              <span>{{ countLabel(episodes.length, 'episode') }}</span>
            </template>
            <span>{{ episodes.filter((episode) => episode.playlist).length }} playable</span>
            <span>added {{ formatDate(show.created_at) }}</span>
          </div>

          <div class="actions">
            <NuxtLink
              v-if="playable[0]"
              :to="`/watch/${playable[0].id}`"
              class="btn btn-primary btn-lg"
            >
              {{ show.is_film ? 'Play' : `Play ${episodeCode(playable[0])}` }}
            </NuxtLink>
            <button
              type="button"
              class="btn btn-secondary btn-lg"
              :disabled="building || !playable.length"
              @click="buildPlaylist"
            >
              {{ season === null ? 'Queue the whole show' : `Queue season ${season}` }}
            </button>
          </div>

          <p v-if="problem" class="problem">{{ problem }}</p>
        </div>
      </section>

      <section class="section">
        <div class="section-head">
          <h2 class="section-title">{{ show.is_film ? 'The film' : 'Episodes' }}</h2>
          <SeasonTabs v-if="seasons.length > 1" v-model="season" :seasons="seasons" />
        </div>

        <StateNote
          v-if="!shown.length"
          tone="empty"
          :message="show.is_film ? 'Nothing here yet.' : 'Nothing in this season.'"
        />
        <div v-else class="rows">
          <EpisodeRow
            v-for="episode in shown"
            :key="episode.id"
            :episode="episode"
            :film="show.is_film"
            @queue="queued = withShow($event)"
          />
        </div>
      </section>
    </template>

    <EpisodeDialog v-if="queued" :episode="queued" @close="queued = null" />
  </div>
</template>

<style scoped lang="scss">
.pad {
  margin: var(--space-8);
}

.head {
  display: grid;
  grid-template-columns: 360px 1fr;
  gap: var(--space-8);
  padding: var(--space-8);
  border-bottom: 2px solid var(--color-divider);
}

.about {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
  align-items: flex-start;
}

.key {
  color: color-mix(in srgb, var(--color-text) 55%, transparent);
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.title {
  margin: 0;
  font-size: 48px;
  line-height: 1.05;
}

.actions {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-3);
  margin-top: auto;
}

.problem {
  margin: 0;
  font-size: 13px;
  font-weight: 600;
  color: var(--color-accent-700);
}

.rows {
  border-top: 2px solid var(--color-divider);
}

@media (max-width: 900px) {
  .head {
    grid-template-columns: 1fr;
    gap: var(--space-6);
    padding: var(--space-6) var(--space-4);
  }

  .title {
    font-size: 32px;
  }
}
</style>
