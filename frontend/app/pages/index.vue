<script setup lang="ts">
// Home: one title up top, then a rail of what arrived last, one of the series
// and one of the films.
//
// Everything here is one request each. It used to be a page request per show to
// learn a count, which was fine for a dozen shows and impossible at eight
// thousand — `GET /shows` now pages, counts and filters on the server, and the
// rails are those parameters rather than work done in the browser.
//
// Ordered by release year, not by when a row was synced: the catalogue is built
// by pulling the whole VOD list, so "when we got it" is one timestamp for
// thousands of titles and says nothing at all.

import type { EpisodeWithShow, Show } from '~/types/catalogue'

const catalogue = useCatalogue()

const RAIL = 18

const { data, pending, error } = await useAsyncData('home', async () => {
  const [going, recent, series, films, playlists] = await Promise.all([
    // Started and unfinished, newest first. A guest has one of these too — the
    // API gives everyone an identity, so resuming never waits on signing up.
    catalogue.continueWatching(RAIL),
    catalogue.shows({ order: 'newest', limit: RAIL }),
    catalogue.shows({ order: 'newest', series: true, limit: RAIL }),
    catalogue.shows({ order: 'newest', series: false, limit: RAIL }),
    catalogue.playlists(),
  ])

  // The hero wants episodes, and only the detail route carries them. A series
  // has more to say than a film, so it leads when there is one.
  const lead = series.items[0] ?? recent.items[0]
  const featured = lead ? await catalogue.show(lead.key) : null

  return { going, recent, series, films, featured, playlists }
})

// A poster opens into the dialog rather than a page: the rails are for
// browsing, and browsing shouldn't cost a page you have to come back from.
// A series opens the same way — the dialog carries its seasons.
const picked = ref<EpisodeWithShow | null>(null)
const opening = ref(false)

async function open(show: Show): Promise<void> {
  opening.value = true
  try {
    const detail = await catalogue.show(show.key)
    // The dialog is opened with an episode and works out the rest: for a film
    // that's the whole thing, for a series it's where its season picker starts.
    const [episode] = detail.episodes
    if (!episode) return void navigateTo(`/shows/${show.key}`)
    const { episodes: _episodes, ...bare } = detail
    picked.value = { ...episode, show: bare }
  } finally {
    opening.value = false
  }
}

/** How far in, as words. The tile has no room for a bar and no need of one. */
function howFar(ratio: number | null): string {
  if (ratio === null) return 'resume'
  return `${Math.min(99, Math.max(1, Math.round(ratio * 100)))}% in`
}

function subtitle(show: { episode_count: number; playable_count: number }): string {
  if (show.episode_count === 1) return show.playable_count ? 'film' : 'film · no stream'
  return `${show.episode_count} eps`
}
</script>

<template>
  <div>
    <StateNote v-if="pending" message="Reading the catalogue…" class="lead-note" />
    <StateNote v-else-if="error" tone="error" :message="error.message" class="lead-note" />

    <template v-else-if="data">
      <HeroBanner
        v-if="data.featured"
        :show="data.featured"
        :episodes="data.featured.episodes"
        :kicker="data.featured.episodes.length > 1 ? 'Most of anything here' : 'Latest in'"
      />

      <CardRail v-if="data.going.length" title="Continue watching" to="/search">
        <EpisodeCard
          v-for="entry in data.going"
          :key="entry.episode_id"
          :episode="entry.episode"
          :subtitle="howFar(entry.ratio)"
          @pick="navigateTo(`/watch/${entry.episode.id}`)"
        />
      </CardRail>

      <CardRail
        v-if="data.recent.items.length"
        :title="`Newest · ${data.recent.total} titles`"
        to="/shows"
      >
        <ShowCard
          v-for="show in data.recent.items"
          :key="show.key"
          :show="show"
          :subtitle="subtitle(show)"
          pickable
          @pick="open"
        />
      </CardRail>

      <CardRail v-if="data.series.items.length" :title="`Series · ${data.series.total}`" to="/shows">
        <ShowCard
          v-for="show in data.series.items"
          :key="show.key"
          :show="show"
          :subtitle="subtitle(show)"
          pickable
          @pick="open"
        />
      </CardRail>

      <CardRail v-if="data.films.items.length" :title="`Films · ${data.films.total}`" to="/shows">
        <ShowCard
          v-for="show in data.films.items"
          :key="show.key"
          :show="show"
          :subtitle="subtitle(show)"
          pickable
          @pick="open"
        />
      </CardRail>

      <section class="section">
        <div class="section-head">
          <h2 class="section-title">Playlists</h2>
          <NuxtLink to="/playlists" class="section-link">View all →</NuxtLink>
        </div>

        <div v-if="data.playlists.length" class="card-grid">
          <PlaylistCard
            v-for="playlist in data.playlists"
            :key="playlist.id"
            :playlist="playlist"
          />
        </div>
        <StateNote v-else tone="empty" message="No playlists yet — build one from a show." />
      </section>
    </template>

    <EpisodeDialog v-if="picked" :episode="picked" @close="picked = null" />
  </div>
</template>

<style scoped lang="scss">
.lead-note {
  margin: var(--space-8);
}
</style>
