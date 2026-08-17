<script setup lang="ts">
// Loading, empty and failed all look the same shape and differ only in tone —
// one component so no page invents its own way of saying nothing is here.

withDefaults(
  defineProps<{
    tone?: 'loading' | 'empty' | 'error'
    message?: string
  }>(),
  { tone: 'loading', message: '' },
)
</script>

<template>
  <p class="note" :class="`note-${tone}`">
    <span v-if="tone === 'loading'" class="pulse" aria-hidden="true" />
    <span>{{ message || (tone === 'loading' ? 'Loading…' : 'Nothing here.') }}</span>
  </p>
</template>

<style scoped lang="scss">
.note {
  display: flex;
  gap: var(--space-3);
  align-items: center;
  padding: var(--space-4);
  margin: 0;
  font-size: 13px;
  font-weight: 600;
  color: color-mix(in srgb, var(--color-text) 60%, transparent);
  border: 2px solid var(--color-divider);
}

.note-error {
  color: var(--color-accent-700);
  border-color: var(--color-accent);
}

.pulse {
  width: 10px;
  height: 10px;
  background: var(--color-accent);
  animation: blink 1s steps(2, end) infinite;
}

@keyframes blink {
  50% {
    opacity: 0.2;
  }
}

@media (prefers-reduced-motion: reduce) {
  .pulse {
    animation: none;
  }
}
</style>
