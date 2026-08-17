<script setup lang="ts">
// Search is the API's own: `q` is a substring of the title and the server does
// the matching, so nothing has to be held in memory here. The query lives in the
// URL too — a search is a thing worth sending to someone.

import type { EpisodeWithShow } from '~/types/catalogue'

const LIMIT = 24

const catalogue = useCatalogue()
const route = useRoute()
const router = useRouter()

const query = ref(String(route.query.q ?? ''))
const playableOnly = ref(true)

const items = ref<EpisodeWithShow[]>([])
const total = ref(0)
const busy = ref(false)
const problem = ref<string | null>(null)
const picked = ref<EpisodeWithShow | null>(null)

async function load(offset = 0): Promise<void> {
  busy.value = true
  problem.value = null
  try {
    const page = await catalogue.episodes({
      q: query.value.trim() || undefined,
      playable: playableOnly.value ? true : undefined,
      limit: LIMIT,
      offset,
    })
    // Paging appends; a new query replaces.
    items.value = offset ? [...items.value, ...page.items] : page.items
    total.value = page.total
  } catch (cause) {
    problem.value = (cause as Error).message
  } finally {
    busy.value = false
  }
}

// Typing shouldn't cost a request per keystroke, and the URL shouldn't collect a
// history entry per keystroke either — hence the delay and the replace.
let timer: ReturnType<typeof setTimeout> | undefined
watch([query, playableOnly], () => {
  clearTimeout(timer)
  timer = setTimeout(() => {
    const q = query.value.trim()
    void router.replace({ query: q ? { q } : {} })
    void load(0)
  }, 220)
})

onMounted(() => load(0))
onBeforeUnmount(() => clearTimeout(timer))

const more = computed(() => items.value.length < total.value)
</script>

<template>
  <section class="section">
    <div class="section-head">
      <h2 class="section-title">Search</h2>
      <span class="section-link">{{ countLabel(total, 'match', 'matches') }}</span>
    </div>

    <div class="controls">
      <div class="field">
        <label for="q">Episode or film title</label>
        <input id="q" v-model="query" class="input" placeholder="e.g. rhode island" >
      </div>

      <div class="seg" role="group" aria-label="Filter">
        <label class="seg-opt">
          <input v-model="playableOnly" type="radio" name="playable" :value="true" >
          Playable
        </label>
        <label class="seg-opt">
          <input v-model="playableOnly" type="radio" name="playable" :value="false" >
          Everything
        </label>
      </div>
    </div>

    <StateNote v-if="problem" tone="error" :message="problem" />
    <StateNote v-else-if="busy && !items.length" message="Searching…" />
    <StateNote v-else-if="!items.length" tone="empty" message="Nothing matched." />

    <template v-else>
      <div class="card-grid">
        <EpisodeCard
          v-for="episode in items"
          :key="episode.id"
          :episode="episode"
          @pick="picked = $event"
        />
      </div>

      <div v-if="more" class="more">
        <button type="button" class="btn btn-secondary" :disabled="busy" @click="load(items.length)">
          {{ busy ? 'Loading…' : `Load ${Math.min(LIMIT, total - items.length)} more` }}
        </button>
      </div>
    </template>

    <EpisodeDialog v-if="picked" :episode="picked" @close="picked = null" />
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
