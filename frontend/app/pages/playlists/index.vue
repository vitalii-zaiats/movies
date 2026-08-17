<script setup lang="ts">
// Playlists, and the two ways the API makes one: empty, or filled from a show.

import type { Playlist, ShowSummary } from '~/types/catalogue'

// How many titles the picker holds at once. The catalogue has thousands, so the
// list is a search result rather than the catalogue itself.
const PICKER = 50

const catalogue = useCatalogue()

const playlists = ref<Playlist[]>([])
const shows = ref<ShowSummary[]>([])
const showTotal = ref(0)
const lookup = ref('')
const name = ref('')
const from = ref({ show: '', season: '' })
const busy = ref(false)
const problem = ref<string | null>(null)
const ready = ref(false)

async function guard<T>(work: () => Promise<T>): Promise<T | undefined> {
  busy.value = true
  problem.value = null
  try {
    return await work()
  } catch (cause) {
    problem.value = (cause as Error).message
    return undefined
  } finally {
    busy.value = false
  }
}

async function refresh(): Promise<void> {
  await guard(async () => {
    playlists.value = await catalogue.playlists()
  })
}

async function findShows(): Promise<void> {
  await guard(async () => {
    const page = await catalogue.shows({
      q: lookup.value.trim() || undefined,
      order: 'title',
      limit: PICKER,
    })
    shows.value = page.items
    showTotal.value = page.total
    // Keep a choice that's still on the list; otherwise take the first match.
    if (!page.items.some((show) => show.key === from.value.show)) {
      from.value.show = page.items[0]?.key ?? ''
    }
  })
}

let timer: ReturnType<typeof setTimeout> | undefined

watch(lookup, () => {
  clearTimeout(timer)
  timer = setTimeout(findShows, 250)
})

onMounted(async () => {
  await findShows()
  await refresh()
  ready.value = true
})

async function create(): Promise<void> {
  const label = name.value.trim()
  if (!label) return
  const detail = await guard(() => catalogue.createPlaylist(label))
  if (detail) {
    name.value = ''
    await refresh()
  }
}

async function fill(): Promise<void> {
  const season = from.value.season.trim()
  const detail = await guard(() =>
    catalogue.playlistFromShow(from.value.show, season === '' ? undefined : Number(season)),
  )
  if (detail) await navigateTo(`/playlists/${detail.id}`)
}
</script>

<template>
  <div>
    <section class="section">
      <div class="section-head">
        <h2 class="section-title">Playlists</h2>
        <span class="section-link">{{ countLabel(playlists.length, 'queue') }}</span>
      </div>

      <StateNote v-if="problem" tone="error" :message="problem" class="gap" />
      <StateNote v-else-if="!ready" message="Reading playlists…" class="gap" />

      <div v-if="playlists.length" class="card-grid">
        <PlaylistCard v-for="playlist in playlists" :key="playlist.id" :playlist="playlist" />
      </div>
      <StateNote
        v-else-if="ready"
        tone="empty"
        message="Nothing queued yet. Build one from a show below."
      />
    </section>

    <section class="section">
      <div class="section-head">
        <h2 class="section-title">New</h2>
      </div>

      <div class="forms">
        <form class="form" @submit.prevent="create">
          <h6>Empty</h6>
          <div class="field">
            <label for="name">Name</label>
            <input id="name" v-model="name" class="input" placeholder="Sunday night" >
          </div>
          <button type="submit" class="btn btn-secondary" :disabled="busy || !name.trim()">
            Create
          </button>
        </form>

        <form class="form" @submit.prevent="fill">
          <h6>From a show</h6>
          <div class="field">
            <label for="lookup">Find a title</label>
            <input id="lookup" v-model="lookup" class="input" placeholder="e.g. дюна" >
          </div>
          <div class="pair">
            <div class="field">
              <label for="show">
                Show
                <span v-if="showTotal > shows.length" class="hint">
                  — first {{ shows.length }} of {{ showTotal }}
                </span>
              </label>
              <select id="show" v-model="from.show" class="input">
                <option v-for="show in shows" :key="show.key" :value="show.key">
                  {{ show.title }}
                </option>
              </select>
            </div>
            <div class="field narrow">
              <label for="season">Season</label>
              <input id="season" v-model="from.season" class="input" inputmode="numeric" placeholder="all" >
            </div>
          </div>
          <!-- The server picks the episodes and the order; it's the side that
               knows which ones have a stream. -->
          <button type="submit" class="btn btn-primary" :disabled="busy || !from.show">
            Build it
          </button>
        </form>
      </div>
    </section>
  </div>
</template>

<style scoped lang="scss">
.gap {
  margin-bottom: var(--space-4);
}

.forms {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: var(--space-8);
  max-width: 900px;
}

.form {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
  align-items: flex-start;
  padding: var(--space-6);
  border: 2px solid var(--color-divider);

  h6 {
    margin: 0;
    color: var(--color-accent);
  }

  .field {
    width: 100%;
  }
}

.pair {
  display: flex;
  gap: var(--space-3);
  width: 100%;
}

.narrow {
  max-width: 96px;
}
</style>
