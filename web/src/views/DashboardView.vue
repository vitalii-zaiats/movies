<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { api } from '../lib/api'
import type { Episode, Playlist, PlaylistDetail, Show } from '../lib/api'

const shows = ref<Show[]>([])
const playlists = ref<Playlist[]>([])
const current = ref<PlaylistDetail | null>(null)
const found = ref<Episode[]>([])
const busy = ref(false)
const problem = ref<string | null>(null)

const form = ref({ show: '', season: '', name: '' })
const search = ref({ q: '', show: '' })

const total = computed(() => current.value?.items.length ?? 0)

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
    playlists.value = await api.playlists()
  })
}

async function open(id: number): Promise<void> {
  await guard(async () => {
    current.value = await api.playlist(id)
  })
}

async function fromShow(): Promise<void> {
  const season = form.value.season.trim()
  const detail = await guard(() =>
    api.createFromShow(
      form.value.show,
      season === '' ? undefined : Number(season),
      form.value.name.trim() || undefined,
    ),
  )
  if (detail) {
    current.value = detail
    form.value.name = ''
    await refresh()
  }
}

async function drop(id: number): Promise<void> {
  await guard(() => api.deletePlaylist(id))
  if (current.value?.id === id) current.value = null
  await refresh()
}

async function remove(itemId: number): Promise<void> {
  if (!current.value) return
  const detail = await guard(() => api.removeItem(current.value!.id, itemId))
  if (detail) {
    current.value = detail
    await refresh()
  }
}

/** Up/down rather than drag-and-drop: it works with a thumb and never mis-drops. */
async function move(index: number, delta: number): Promise<void> {
  if (!current.value) return
  const ids = current.value.items.map((item) => item.id)
  const target = index + delta
  if (target < 0 || target >= ids.length) return
  ;[ids[index], ids[target]] = [ids[target], ids[index]]

  const detail = await guard(() => api.reorder(current.value!.id, ids))
  if (detail) current.value = detail
}

async function find(): Promise<void> {
  const page = await guard(() =>
    api.episodes({ q: search.value.q, show: search.value.show, playable: true, limit: 25 }),
  )
  if (page) found.value = page.items
}

async function add(episode: Episode): Promise<void> {
  if (!current.value) return
  const detail = await guard(() => api.addItem(current.value!.id, episode.id))
  if (detail) {
    current.value = detail
    await refresh()
  }
}

onMounted(async () => {
  await guard(async () => {
    shows.value = await api.shows()
    form.value.show = shows.value[0]?.key ?? ''
    search.value.show = ''
  })
  await refresh()
})
</script>

<template>
  <section class="dash">
    <header class="head">
      <h1>Playlists</h1>
      <p class="hint">
        Built here, played by the screen. <RouterLink to="/">Display</RouterLink>
      </p>
    </header>

    <p v-if="problem" class="fault">{{ problem }}</p>

    <div class="grid">
      <aside class="panel">
        <h2>Build from a show</h2>
        <form class="build" @submit.prevent="fromShow">
          <select v-model="form.show" aria-label="show">
            <option v-for="show in shows" :key="show.key" :value="show.key">
              {{ show.title }}
            </option>
          </select>
          <input v-model="form.season" placeholder="season (all)" inputmode="numeric" />
          <input v-model="form.name" placeholder="name (optional)" />
          <button type="submit" :disabled="busy || !form.show">Create</button>
        </form>

        <h2>All playlists</h2>
        <ul class="list">
          <li v-for="playlist in playlists" :key="playlist.id">
            <button
              class="row"
              :class="{ 'row--on': current?.id === playlist.id }"
              type="button"
              @click="open(playlist.id)"
            >
              <span>{{ playlist.name }}</span>
              <span class="count">{{ playlist.count }}</span>
            </button>
          </li>
          <li v-if="!playlists.length" class="empty">nothing yet</li>
        </ul>
      </aside>

      <main class="panel">
        <template v-if="current">
          <div class="head">
            <h2>{{ current.name }} · {{ total }}</h2>
            <button class="danger" type="button" @click="drop(current.id)">delete</button>
          </div>

          <ol class="items">
            <li v-for="(item, index) in current.items" :key="item.id" class="item">
              <span class="item__pos">{{ index + 1 }}</span>
              <span class="item__title">{{ item.episode.title }}</span>
              <span v-if="!item.episode.playlist" class="item__warn">no vod</span>
              <span class="item__tools">
                <button type="button" :disabled="index === 0" @click="move(index, -1)">↑</button>
                <button
                  type="button"
                  :disabled="index === total - 1"
                  @click="move(index, 1)"
                >
                  ↓
                </button>
                <button type="button" @click="remove(item.id)">✕</button>
              </span>
            </li>
            <li v-if="!total" class="empty">empty — add episodes below</li>
          </ol>

          <h2>Add episodes</h2>
          <form class="build" @submit.prevent="find">
            <input v-model="search.q" placeholder="search titles" />
            <input v-model="search.show" placeholder="show key (any)" />
            <button type="submit" :disabled="busy">Search</button>
          </form>

          <ul class="list">
            <li v-for="episode in found" :key="episode.id">
              <button class="row" type="button" @click="add(episode)">
                <span>{{ episode.title }}</span>
                <span class="count">add</span>
              </button>
            </li>
          </ul>
        </template>

        <p v-else class="empty">pick a playlist on the left, or build one from a show</p>
      </main>
    </div>
  </section>
</template>

<style scoped lang="scss">
@use '../styles/tokens' as *;

.dash {
  max-width: 68rem;
  margin: 0 auto;
  padding: $gap-lg;
}

.head {
  display: flex;
  gap: $gap-sm;
  align-items: baseline;
  justify-content: space-between;
}

h1 {
  margin: 0;
  font-size: 1.3rem;
}

h2 {
  margin: $gap-lg 0 $gap-sm;
  font-size: 0.85rem;
  font-weight: 600;
  color: $muted;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

.hint {
  margin: 0;
  color: $muted;
  font-size: 0.85rem;

  a {
    color: $accent;
  }
}

.grid {
  display: grid;
  grid-template-columns: minmax(16rem, 22rem) 1fr;
  gap: $gap-lg;
  margin-top: $gap-lg;

  @media (width < 52rem) {
    grid-template-columns: 1fr;
  }
}

.panel {
  padding: $gap-lg;
  background: $surface;
  border: 1px solid $line;
  border-radius: $radius-lg;

  > h2:first-child {
    margin-top: 0;
  }
}

.build {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;

  input,
  select {
    flex: 1 1 7rem;
    min-width: 0;
    padding: 0.55rem 0.7rem;
    color: inherit;
    font: inherit;
    background: $bg;
    border: 1px solid $line;
    border-radius: $radius-sm;
  }

  button {
    padding: 0.55rem 1rem;
    color: $bg;
    font: inherit;
    font-weight: 600;
    background: $accent;
    border: none;
    border-radius: $radius-sm;

    &:disabled {
      opacity: 0.5;
    }
  }
}

.list,
.items {
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
  margin: 0;
  padding: 0;
  list-style: none;
}

.row {
  display: flex;
  gap: $gap-sm;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  padding: 0.6rem 0.8rem;
  color: inherit;
  font: inherit;
  text-align: left;
  background: $bg;
  border: 1px solid $line;
  border-radius: $radius-sm;

  &--on {
    border-color: $accent;
  }
}

.count {
  color: $muted;
  font-family: $mono;
  font-size: 0.78rem;
}

.item {
  display: flex;
  gap: 0.6rem;
  align-items: center;
  padding: 0.5rem 0.7rem;
  background: $bg;
  border: 1px solid $line;
  border-radius: $radius-sm;

  &__pos {
    min-width: 2rem;
    color: $muted;
    font-family: $mono;
    font-size: 0.8rem;
  }

  &__title {
    flex: 1;
    overflow-wrap: anywhere;
  }

  &__warn {
    color: $danger;
    font-size: 0.75rem;
  }

  &__tools button {
    margin-left: 0.25rem;
    padding: 0.25rem 0.5rem;
    color: $muted;
    font: inherit;
    background: transparent;
    border: 1px solid $line;
    border-radius: 6px;

    &:disabled {
      opacity: 0.35;
    }
  }
}

.empty {
  margin: 0;
  color: $muted;
  font-size: 0.9rem;
}

.danger {
  padding: 0.35rem 0.7rem;
  color: $danger;
  font: inherit;
  font-size: 0.8rem;
  background: transparent;
  border: 1px solid $line;
  border-radius: $radius-sm;
}

.fault {
  margin: $gap-sm 0 0;
  color: $danger;
}
</style>
