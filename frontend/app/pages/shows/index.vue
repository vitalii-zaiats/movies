<script setup lang="ts">
// Everything the catalogue holds, one tile per show.
//
// Paged, because "everything" is eight thousand titles: the server matches the
// filter, counts the episodes and hands back a slice. Typing narrows it there
// too — the browser never holds the catalogue, only the page it is looking at.

import type { ShowSummary } from '~/types/catalogue'

const LIMIT = 48

const catalogue = useCatalogue()
const route = useRoute()
const router = useRouter()

const query = ref(String(route.query.q ?? ''))
const shape = ref<'all' | 'series' | 'films'>('all')

const items = ref<ShowSummary[]>([])
const total = ref(0)
const busy = ref(false)
const problem = ref<string | null>(null)

async function load(offset = 0): Promise<void> {
  busy.value = true
  problem.value = null
  try {
    const page = await catalogue.shows({
      q: query.value.trim() || undefined,
      series: shape.value === 'all' ? undefined : shape.value === 'series',
      order: query.value.trim() ? 'title' : 'newest',
      limit: LIMIT,
      offset,
    })
    // Paging appends; a new filter replaces.
    items.value = offset ? [...items.value, ...page.items] : page.items
    total.value = page.total
  } catch (cause) {
    problem.value = (cause as Error).message
  } finally {
    busy.value = false
  }
}

// Typing shouldn't cost a request per keystroke, nor a history entry per one.
let timer: ReturnType<typeof setTimeout> | undefined

watch(query, (value) => {
  clearTimeout(timer)
  timer = setTimeout(() => {
    router.replace({ query: value.trim() ? { q: value.trim() } : {} })
    load()
  }, 250)
})

watch(shape, () => load())

onMounted(() => load())

function subtitle(show: ShowSummary): string {
  if (show.episode_count === 1) return show.playable_count ? 'film' : 'film · no stream'
  return `${show.playable_count}/${show.episode_count} eps play`
}
</script>

<template>
  <section class="section">
    <div class="section-head">
      <h2 class="section-title">Shows</h2>
      <span class="section-link">{{ countLabel(total, 'title') }}</span>
    </div>

    <div class="controls">
      <div class="field">
        <label for="show-q">Title</label>
        <input id="show-q" v-model="query" class="input" placeholder="e.g. дюна" >
      </div>

      <div class="seg" role="group" aria-label="Shape">
        <label class="seg-opt">
          <input v-model="shape" type="radio" name="shape" value="all" >
          Everything
        </label>
        <label class="seg-opt">
          <input v-model="shape" type="radio" name="shape" value="series" >
          Series
        </label>
        <label class="seg-opt">
          <input v-model="shape" type="radio" name="shape" value="films" >
          Films
        </label>
      </div>
    </div>

    <StateNote v-if="problem" tone="error" :message="problem" />
    <StateNote v-else-if="busy && !items.length" message="Reading the catalogue…" />
    <StateNote v-else-if="!items.length" tone="empty" message="Nothing matches." />

    <div v-else class="card-grid">
      <ShowCard
        v-for="show in items"
        :key="show.key"
        :show="show"
        :subtitle="subtitle(show)"
      />
    </div>

    <div v-if="items.length < total" class="more">
      <button type="button" class="btn btn-secondary" :disabled="busy" @click="load(items.length)">
        {{ busy ? 'Loading…' : `Load ${Math.min(LIMIT, total - items.length)} more` }}
      </button>
    </div>
  </section>
</template>

<style scoped lang="scss">
.controls {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-6);
  align-items: flex-end;
  margin-bottom: var(--space-6);
}

.field {
  flex: 1;
  min-width: 260px;
  max-width: 520px;
}

.more {
  display: flex;
  justify-content: center;
  margin-top: var(--space-6);
}
</style>
