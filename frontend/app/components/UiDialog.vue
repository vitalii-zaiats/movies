<script setup lang="ts">
// The modal shell: a scrim, a surface, and the two ways out everyone expects.
// What goes inside is the caller's; this owns nothing but the behaviour.

withDefaults(defineProps<{ width?: string }>(), { width: 'min(1240px, 94vw)' })

const emit = defineEmits<{ close: [] }>()

function onKey(event: KeyboardEvent): void {
  if (event.key === 'Escape') emit('close')
}

onMounted(() => {
  document.addEventListener('keydown', onKey)
  // The page behind must not scroll under the scrim — on a phone it otherwise
  // takes the dialog with it.
  document.body.style.overflow = 'hidden'
})

onBeforeUnmount(() => {
  document.removeEventListener('keydown', onKey)
  document.body.style.overflow = ''
})
</script>

<template>
  <Teleport to="body">
    <div class="dialog-backdrop" @click="emit('close')">
      <div
        class="dialog elev-lg shell"
        role="dialog"
        aria-modal="true"
        :style="{ width }"
        @click.stop
      >
        <slot />
      </div>
    </div>
  </Teleport>
</template>

<style scoped lang="scss">
.shell {
  max-height: 88vh;
  padding: 0;
  overflow: auto;
}
</style>
