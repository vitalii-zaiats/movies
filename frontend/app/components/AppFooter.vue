<script setup lang="ts">
const { mocked } = useCatalogue()
</script>

<template>
  <footer class="foot">
    <span class="brand">LUMEN</span>
    <span>{{ mocked ? 'fixtures' : 'apps/api' }}</span>
    <a href="https://github.com" class="quiet">Devices</a>
    <a href="https://github.com" class="quiet">Help</a>
  </footer>
</template>

<style scoped lang="scss">
.foot {
  display: flex;
  gap: var(--space-6);
  align-items: center;
  padding: var(--space-6) var(--space-8);
  font-size: 12px;
  color: color-mix(in srgb, var(--color-text) 55%, transparent);
  border-top: 2px solid var(--color-divider);
}

.brand {
  font-weight: 700;
  color: var(--color-text);
}

.quiet {
  color: inherit;
  text-decoration: none;

  &:hover {
    color: var(--color-accent);
  }
}
</style>
