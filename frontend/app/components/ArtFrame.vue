<script setup lang="ts">
// A tile's picture. Draws the poster when there is one and a figure derived from
// the key when there isn't — which, with these sources, is most of the time.

const props = withDefaults(
  defineProps<{
    /** What the figure is derived from. The show key keeps a show one colour. */
    artKey: string
    poster?: string | null
    variant?: 'gradient' | 'stripes'
    ratio?: string
    /** Stripe width. Wider where the frame is bigger, or it reads as noise. */
    band?: number
    /**
     * Drain the *generated* figure, so a wall of them reads as one catalogue.
     * A real poster is never drained: it was drawn in colour on purpose, and
     * greying out eight thousand of them to match a fallback is backwards.
     */
    drained?: boolean
  }>(),
  { poster: null, variant: 'gradient', ratio: 'var(--poster-ratio)', band: 12, drained: false },
)

// A poster URL that 404s is the normal case, not the exception: sources move
// their uploads and nobody re-crawls. One failed load and this tile keeps its
// generated ground for good.
const broken = ref(false)
watch(
  () => props.poster,
  () => {
    broken.value = false
  },
)

const ground = computed(() =>
  props.variant === 'stripes' ? stripesFor(props.artKey, props.band) : gradientFor(props.artKey),
)

/** A real picture is showing, rather than the figure standing in for one. */
const showing = computed(() => Boolean(props.poster) && !broken.value)
</script>

<template>
  <div class="art" :style="{ aspectRatio: ratio }">
    <!-- Draining happens on this layer alone. Put it on the frame and it takes
         the badges and captions with it, and the accent stops being an accent. -->
    <div class="ground" :class="{ grayscale: drained && !showing }" :style="{ backgroundImage: ground }">
      <img v-if="showing" :src="poster!" alt="" loading="lazy" @error="broken = true" >
    </div>
    <slot />
  </div>
</template>

<style scoped lang="scss">
.art {
  position: relative;
  overflow: hidden;
  background: var(--color-neutral-900);
}

.ground {
  position: absolute;
  inset: 0;
  background-size: cover;

  img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }
}
</style>
