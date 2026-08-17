<script setup lang="ts">
// One episode as a line rather than a tile. A season of 22 reads as a list; the
// same 22 as tiles is a wall.

import type { Episode } from '~/types/catalogue'

defineProps<{
  episode: Episode
  /** A film is its own single episode; numbering it says nothing. */
  film?: boolean
}>()

defineEmits<{ queue: [episode: Episode] }>()
</script>

<template>
  <div class="row" :class="{ dead: !episode.playlist }">
    <span v-if="!film" class="code mono">{{ episodeCode(episode) }}</span>

    <span class="name">
      {{ episodeName(episode) ?? '—' }}
      <span v-if="!episode.playlist" class="tag tag-neutral">no stream</span>
    </span>

    <span class="tools">
      <button type="button" class="btn btn-ghost" @click="$emit('queue', episode)">Queue</button>
      <NuxtLink v-if="episode.playlist" :to="`/watch/${episode.id}`" class="btn btn-secondary">
        Play
      </NuxtLink>
    </span>
  </div>
</template>

<style scoped lang="scss">
.row {
  display: grid;
  grid-template-columns: auto 1fr auto;
  gap: var(--space-4);
  align-items: center;
  padding: var(--space-3) var(--space-2);
  border-bottom: 1px solid var(--color-divider);

  &:hover {
    background: color-mix(in srgb, var(--color-text) 4%, transparent);
  }
}

.dead {
  color: color-mix(in srgb, var(--color-text) 55%, transparent);
}

.code {
  font-weight: 700;
  color: var(--color-accent-700);
}

.name {
  display: flex;
  gap: var(--space-3);
  align-items: center;
  min-width: 0;
  font-size: 14px;
  font-weight: 600;
}

.tools {
  display: flex;
  gap: var(--space-2);
  align-items: center;
}

@media (max-width: 640px) {
  .row {
    grid-template-columns: 72px 1fr;
    row-gap: var(--space-2);
  }

  .tools {
    grid-column: 1 / -1;
    justify-content: flex-end;
  }
}
</style>
