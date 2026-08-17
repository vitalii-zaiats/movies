<script setup lang="ts">
import type { EpisodeWithShow } from '~/types/catalogue'

const props = withDefaults(
  defineProps<{
    episode: EpisodeWithShow
    /** Off inside a show's own page, where repeating its title is noise. */
    withShow?: boolean
    /** Overrides the second line — a rail that knows better can say so. */
    subtitle?: string
  }>(),
  { withShow: true, subtitle: '' },
)

defineEmits<{ pick: [episode: EpisodeWithShow] }>()

// The corner badge already carries the numbering, so nothing else may repeat it.
// Half these episodes have no name of their own — for those the show's name is
// the most useful thing to put where a title goes.
const name = computed(() => episodeName(props.episode))
const heading = computed(() => name.value ?? props.episode.show.title)
// A film is its own single episode, so its numbering says nothing: no badge, and
// the second line has to find something better to be.
const film = computed(() => props.episode.show.is_film)
const caption = computed(() => {
  if (props.subtitle) return props.subtitle
  if (film.value) return 'Film'
  if (name.value && props.withShow) return props.episode.show.title
  return `Season ${props.episode.season}`
})
</script>

<template>
  <button type="button" class="tile" @click="$emit('pick', episode)">
    <ArtFrame :art-key="`${episode.show.key}-${episode.season}`" :poster="episode.poster ?? episode.show.poster">
      <span class="shade" />
      <span v-if="!film" class="badge code">{{ episodeCode(episode) }}</span>
      <!-- Nothing to play is a fact about the row, and the tile says so up front
           rather than letting someone click into a dead player. -->
      <span v-if="!episode.playlist" class="badge missing">no stream</span>
      <span class="caption">
        <span class="title">{{ heading }}</span>
        <span class="sub">{{ caption }}</span>
      </span>
    </ArtFrame>
  </button>
</template>

<style scoped lang="scss">
.tile {
  position: relative;
  display: block;
  // No width of its own: the rail sets one, and in a grid the cell does.
  padding: 0;
  color: var(--color-ink-text);
  text-align: left;
  background: none;
  border: 0;
  outline: 3px solid transparent;
  outline-offset: 3px;
  transition:
    outline-color 0.15s,
    transform 0.2s;

  &:hover,
  &:focus-visible {
    z-index: 5;
    outline-color: var(--color-accent);
    transform: scale(1.04);
  }
}

.shade {
  position: absolute;
  inset: 0;
  background: linear-gradient(
    to top,
    rgb(20 18 17 / 88%) 0%,
    rgb(20 18 17 / 25%) 50%,
    transparent 70%
  );
}

.badge {
  position: absolute;
  top: 0;
  padding: 4px 10px;
  font-size: 12px;
  font-weight: 700;
}

.code {
  left: 0;
  color: var(--color-ink-text);
  background: var(--color-accent);
}

.missing {
  right: 0;
  color: var(--color-ink-text);
  background: var(--color-neutral-900);
}

.caption {
  position: absolute;
  right: 0;
  bottom: 0;
  left: 0;
  display: block;
  padding: var(--space-4);
}

.title {
  display: -webkit-box;
  overflow: hidden;
  font-size: 17px;
  font-weight: 700;
  line-height: 1.2;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
}

.sub {
  display: block;
  margin-top: 3px;
  overflow: hidden;
  font-size: 12.5px;
  color: var(--color-ink-muted);
  text-overflow: ellipsis;
  white-space: nowrap;
}

@media (prefers-reduced-motion: reduce) {
  .tile {
    transition: outline-color 0.15s;
  }

  .tile:hover,
  .tile:focus-visible {
    transform: none;
  }
}
</style>
