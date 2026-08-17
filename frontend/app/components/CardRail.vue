<script setup lang="ts">
// A titled band of tiles that scrolls sideways. It owns the heading row and the
// scroller; what goes in it is the caller's business.

defineProps<{
  title: string
  /** Where "view all" points. Omitted, and the link isn't drawn. */
  to?: string
}>()

const scroller = ref<HTMLElement | null>(null)

// Not quite a full page, so the tile at the edge stays half-visible and the rail
// keeps saying "there is more".
function nudge(direction: 1 | -1): void {
  const element = scroller.value
  if (element) element.scrollBy({ left: direction * element.clientWidth * 0.8, behavior: 'smooth' })
}
</script>

<template>
  <section class="section">
    <div class="section-head">
      <h2 class="section-title">{{ title }}</h2>
      <div class="tools">
        <button type="button" class="btn btn-secondary btn-icon" aria-label="Scroll left" @click="nudge(-1)">←</button>
        <button type="button" class="btn btn-secondary btn-icon" aria-label="Scroll right" @click="nudge(1)">→</button>
        <NuxtLink v-if="to" :to="to" class="section-link">View all →</NuxtLink>
      </div>
    </div>

    <div ref="scroller" class="scroller">
      <slot />
    </div>
  </section>
</template>

<style scoped lang="scss">
.tools {
  display: flex;
  gap: var(--space-2);
  align-items: center;
}

@media (max-width: 720px) {
  // A thumb scrolls the rail better than the buttons do.
  .tools .btn-icon {
    display: none;
  }
}
</style>
