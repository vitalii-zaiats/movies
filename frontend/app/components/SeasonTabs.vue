<script setup lang="ts">
// The system's segmented control, over whatever seasons a show turned out to
// have. `null` is "all" — the catalogue never guarantees season 1 exists.

defineProps<{ seasons: number[] }>()

const chosen = defineModel<number | null>({ required: true })
</script>

<template>
  <div class="seg" role="group" aria-label="Season">
    <label class="seg-opt">
      <input v-model="chosen" type="radio" name="season" :value="null" >
      All
    </label>
    <label v-for="season in seasons" :key="season" class="seg-opt">
      <input v-model="chosen" type="radio" name="season" :value="season" >
      S{{ String(season).padStart(2, '0') }}
    </label>
  </div>
</template>

<style scoped lang="scss">
.seg {
  flex-wrap: wrap;
  max-width: 100%;
}
</style>
