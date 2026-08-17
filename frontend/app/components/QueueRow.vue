<script setup lang="ts">
// A line in a playlist. Up/down rather than drag-and-drop, for the same reason
// web/ does it that way: it works with a thumb and never mis-drops.

import type { PlaylistItem } from '~/types/catalogue'

defineProps<{
  item: PlaylistItem
  first: boolean
  last: boolean
  /** Somebody else's published queue is watchable, not editable. */
  editable?: boolean
}>()

defineEmits<{ move: [delta: number]; remove: [] }>()
</script>

<template>
  <li class="row">
    <span class="position mono">{{ String(item.position + 1).padStart(2, '0') }}</span>

    <ArtFrame
      :art-key="`${item.episode.show.key}-${item.episode.season}`"
      :poster="item.episode.poster ?? item.episode.show.poster"
      drained
      class="thumb"
    />

    <span class="what">
      <span class="name">{{ episodeHeading(item.episode) }}</span>
      <span class="sub">
        {{ item.episode.show.title }}
        <template v-if="!item.episode.show.is_film"> · {{ episodeCode(item.episode) }}</template>
      </span>
    </span>

    <span class="tools">
      <template v-if="editable">
        <button
          type="button"
          class="btn btn-secondary btn-icon"
          aria-label="Move up"
          :disabled="first"
          @click="$emit('move', -1)"
        >
          ↑
        </button>
        <button
          type="button"
          class="btn btn-secondary btn-icon"
          aria-label="Move down"
          :disabled="last"
          @click="$emit('move', 1)"
        >
          ↓
        </button>
      </template>
      <NuxtLink
        v-if="item.episode.playlist"
        :to="`/watch/${item.episode.id}`"
        class="btn btn-secondary"
      >
        Play
      </NuxtLink>
      <button
        v-if="editable"
        type="button"
        class="btn btn-ghost"
        @click="$emit('remove')"
      >
        Remove
      </button>
    </span>
  </li>
</template>

<style scoped lang="scss">
.row {
  display: grid;
  grid-template-columns: 32px 96px 1fr auto;
  gap: var(--space-4);
  align-items: center;
  padding: var(--space-3) 0;
  border-bottom: 1px solid var(--color-divider);
}

.position {
  font-weight: 700;
  color: color-mix(in srgb, var(--color-text) 50%, transparent);
}

.thumb {
  width: 96px;
}

.what {
  min-width: 0;
}

.name {
  display: block;
  overflow: hidden;
  font-size: 15px;
  font-weight: 700;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.sub {
  display: block;
  font-size: 13px;
  color: color-mix(in srgb, var(--color-text) 55%, transparent);
}

.tools {
  display: flex;
  gap: var(--space-2);
  align-items: center;
}

@media (max-width: 720px) {
  .row {
    grid-template-columns: 28px 72px 1fr;
  }

  .thumb {
    width: 72px;
  }

  .tools {
    grid-column: 1 / -1;
    justify-content: flex-end;
  }
}
</style>
