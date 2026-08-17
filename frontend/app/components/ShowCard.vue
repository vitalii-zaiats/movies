<script setup lang="ts">
import type { Show } from '~/types/catalogue'

const props = defineProps<{
  show: Show
  /** Whatever the caller could find out — a count, a season, a date. */
  subtitle?: string
  /**
   * Open into a dialog instead of walking to the show's own page. A rail full of
   * posters is a place you're browsing, and browsing shouldn't cost a page load
   * you then have to come back from; a grid you arrived at deliberately is the
   * other case, and there a link is right — it opens in a tab, it can be shared.
   */
  pickable?: boolean
}>()

defineEmits<{ pick: [show: Show] }>()

// A button when it opens a dialog, a link when it goes somewhere: the tag has to
// match what the tile does, or the keyboard and the context menu both lie.
const tile = computed(() => (props.pickable ? 'button' : resolveComponent('NuxtLink')))
</script>

<template>
  <component
    :is="tile"
    class="tile"
    :type="pickable ? 'button' : undefined"
    :to="pickable ? undefined : `/shows/${show.key}`"
    @click="pickable && $emit('pick', show)"
  >
    <ArtFrame :art-key="show.key" :poster="show.poster" variant="stripes" drained />
    <div class="body">
      <div class="row">
        <span class="name">{{ show.title }}</span>
        <span v-if="subtitle" class="count">{{ subtitle }}</span>
      </div>
    </div>
  </component>
</template>

<style scoped lang="scss">
.tile {
  // No width of its own: the rail sets one and a grid cell stretches it. Giving
  // a width here beat the rail's rule and turned one card into the whole row.
  display: block;
  padding: 0;
  font: inherit;
  color: inherit;
  text-align: left;
  cursor: pointer;
  text-decoration: none;
  background: var(--color-bg);
  border: 2px solid var(--color-divider);

  &:hover,
  &:focus-visible {
    border-color: var(--color-accent);
  }
}

.body {
  padding: var(--space-4);
  border-top: 2px solid var(--color-divider);
}

.row {
  display: flex;
  gap: var(--space-3);
  align-items: baseline;
  justify-content: space-between;
}

.name {
  overflow: hidden;
  font-size: 15px;
  font-weight: 700;
  line-height: 1.25;
  // One line: at eight thousand tiles, a title that wraps makes the grid ragged.
  text-overflow: ellipsis;
  white-space: nowrap;
}

.count {
  font-size: 13px;
  font-weight: 700;
  color: var(--color-accent-700);
  white-space: nowrap;
}
</style>
