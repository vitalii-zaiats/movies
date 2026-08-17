<script setup lang="ts">
// The list endpoint hands out a name, a count and a date and nothing else — no
// items, so no thumbnails. The tile is honest about that and leans on the
// generated ground instead of faking a stack of covers.

import type { Playlist } from '~/types/catalogue'

defineProps<{ playlist: Playlist }>()
</script>

<template>
  <NuxtLink :to="`/playlists/${playlist.id}`" class="tile">
    <ArtFrame :art-key="playlist.name" ratio="21 / 9" variant="stripes" drained>
      <span class="count">{{ playlist.count }}</span>
    </ArtFrame>
    <div class="body">
      <span class="name">{{ playlist.name }}</span>
      <span class="sub">{{ countLabel(playlist.count, 'episode') }} · {{ formatDate(playlist.created_at) }}</span>
    </div>
  </NuxtLink>
</template>

<style scoped lang="scss">
.tile {
  display: block;
  color: inherit;
  text-decoration: none;
  border: 2px solid var(--color-divider);

  &:hover,
  &:focus-visible {
    border-color: var(--color-accent);
  }
}

.count {
  position: absolute;
  top: 0;
  left: 0;
  padding: 4px 10px;
  font-size: 12px;
  font-weight: 700;
  color: var(--color-ink-text);
  background: var(--color-accent);
}

.body {
  padding: var(--space-4);
  border-top: 2px solid var(--color-divider);
}

.name {
  display: block;
  font-size: 16px;
  font-weight: 700;
}

.sub {
  display: block;
  margin-top: 4px;
  font-size: 13px;
  color: color-mix(in srgb, var(--color-text) 55%, transparent);
}
</style>
