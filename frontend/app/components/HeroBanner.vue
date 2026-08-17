<script setup lang="ts">
// The top of the home page: one show, big, with the two things you can do to it.
//
// The design puts a synopsis here. The catalogue hasn't got one — nothing the
// crawlers collect includes a description — so the panel says what it does know:
// how much of the show is here and how much of it will actually play.

import type { Episode, Show } from '~/types/catalogue'

const props = defineProps<{
  show: Show
  episodes: Episode[]
  /** The line above the title. */
  kicker?: string
}>()

const seasons = computed(() => seasonsOf(props.episodes))
const playable = computed(() => props.episodes.filter((episode) => episode.playlist !== null))
const first = computed(() => playable.value[0] ?? null)
const film = computed(() => isFilm(props.episodes))
</script>

<template>
  <section class="hero">
    <ArtFrame
      :art-key="show.key"
      :poster="show.poster"
      variant="stripes"
      :band="28"
      ratio="auto"
      drained
      class="art"
    >
      <span class="scrim" />
    </ArtFrame>

    <div class="panel on-ink">
      <div class="kickers">
        <span v-if="kicker" class="tag tag-accent">{{ kicker }}</span>
      </div>

      <h1 class="title">{{ show.title }}</h1>

      <div class="meta">
        <span v-if="film" class="tag-rule">film</span>
        <template v-else>
          <span>{{ countLabel(seasons.length, 'season') }}</span>
          <span>{{ countLabel(episodes.length, 'episode') }}</span>
        </template>
        <span class="tag-rule">{{ playable.length }} playable</span>
        <span class="faint">added {{ formatDate(show.created_at) }}</span>
      </div>

      <p class="blurb">
        <template v-if="playable.length">
          Everything the crawlers found for this one, in order — {{ playable.length }} of
          {{ episodes.length }} have a stream behind them.
        </template>
        <template v-else>
          The catalogue knows about {{ countLabel(episodes.length, 'episode') }} here, but none of
          them have been packaged yet.
        </template>
      </p>

      <div class="actions">
        <NuxtLink v-if="first" :to="`/watch/${first.id}`" class="btn btn-primary btn-lg">
          {{ film ? 'Play' : `Play ${episodeCode(first)}` }}
        </NuxtLink>
        <button v-else type="button" class="btn btn-primary btn-lg" disabled>Nothing to play</button>
        <NuxtLink :to="`/shows/${show.key}`" class="btn btn-secondary btn-lg">All episodes</NuxtLink>
      </div>
    </div>
  </section>
</template>

<style scoped lang="scss">
.hero {
  position: relative;
  border-bottom: 2px solid var(--color-divider);
}

.art {
  height: 64vh;
  min-height: 420px;
  // On a desk monitor 64vh alone leaves the first rail below the fold, which
  // hides the one thing the page is for.
  max-height: 680px;
}

.scrim {
  position: absolute;
  inset: 0;
  background: linear-gradient(to top right, rgb(20 18 17 / 55%), transparent 60%);
}

.panel {
  position: absolute;
  bottom: 0;
  left: 0;
  max-width: 760px;
  padding: var(--space-8);
}

.kickers {
  display: flex;
  gap: var(--space-3);
  align-items: center;
  margin-bottom: var(--space-4);
}

.note {
  font-weight: 600;
  color: var(--color-ink-faint);
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.title {
  margin: 0 0 var(--space-4);
  font-size: 64px;
  font-weight: 800;
  line-height: 1;
  letter-spacing: -0.01em;
}

.meta {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-4);
  align-items: center;
  margin-bottom: var(--space-4);
  font-size: 15px;
  font-weight: 600;
}

.faint {
  color: var(--color-ink-faint);
}

.blurb {
  max-width: 600px;
  margin: 0 0 var(--space-6);
  font-size: 16px;
  line-height: 1.55;
  color: var(--color-ink-muted);
  text-wrap: pretty;
}

.actions {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-3);
}

@media (max-width: 900px) {
  .art {
    height: 46vh;
    min-height: 300px;
  }

  .panel {
    position: static;
    max-width: none;
    padding: var(--space-6) var(--space-4);
  }

  .title {
    font-size: 40px;
  }
}
</style>
