<script setup lang="ts">
// One queue. Every mutation answers with the whole playlist, so the page never
// patches its own copy — it replaces it with what the server says it is.

import type { PlaylistDetail } from '~/types/catalogue'

const route = useRoute()
const catalogue = useCatalogue()

const id = computed(() => Number(route.params.id))

const playlist = ref<PlaylistDetail | null>(null)
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

async function load(): Promise<void> {
  const detail = await guard(() => catalogue.playlist(id.value))
  if (detail) playlist.value = detail
  ready.value = true
}

onMounted(load)
watch(id, load)

const first = computed(
  () => playlist.value?.items.find((item) => item.episode.playlist !== null) ?? null,
)

async function move(index: number, delta: number): Promise<void> {
  const current = playlist.value
  if (!current) return

  const ids = current.items.map((item) => item.id)
  const target = index + delta
  if (target < 0 || target >= ids.length) return
  ;[ids[index], ids[target]] = [ids[target] as number, ids[index] as number]

  const detail = await guard(() => catalogue.reorder(current.id, ids))
  if (detail) playlist.value = detail
}

async function remove(itemId: number): Promise<void> {
  const current = playlist.value
  if (!current) return
  const detail = await guard(() => catalogue.removeItem(current.id, itemId))
  if (detail) playlist.value = detail
}

async function drop(): Promise<void> {
  const current = playlist.value
  if (!current) return
  // Deleting a queue takes the whole thing with it, so it gets asked out loud.
  if (!window.confirm(`Delete “${current.name}”?`)) return
  const gone = await guard(() => catalogue.deletePlaylist(current.id))
  if (gone !== undefined) await navigateTo('/playlists')
}
</script>

<template>
  <div>
    <StateNote v-if="!ready" message="Reading the queue…" class="pad" />
    <StateNote v-else-if="problem && !playlist" tone="error" :message="problem" class="pad" />

    <template v-else-if="playlist">
      <section class="section">
        <div class="section-head">
          <div>
            <h1 class="title">{{ playlist.name }}</h1>
            <div class="meta-line">
              <span>{{ countLabel(playlist.count, 'episode') }}</span>
              <span>made {{ formatDate(playlist.created_at) }}</span>
              <!-- Somebody else's published queue is yours to watch and not to
                   edit. The API answers 404 either way; this says so first. -->
              <span v-if="!playlist.mine">published — read only</span>
            </div>
          </div>

          <div class="actions">
            <NuxtLink
              v-if="first"
              :to="{ path: `/watch/${first.episode.id}`, query: { playlist: playlist.id } }"
              class="btn btn-primary"
            >
              Play all
            </NuxtLink>
            <button
              v-if="playlist.mine"
              type="button"
              class="btn btn-ghost"
              :disabled="busy"
              @click="drop"
            >
              Delete
            </button>
          </div>
        </div>

        <StateNote v-if="problem" tone="error" :message="problem" class="gap" />

        <ul v-if="playlist.items.length" class="queue">
          <QueueRow
            v-for="(item, index) in playlist.items"
            :key="item.id"
            :item="item"
            :first="index === 0"
            :last="index === playlist.items.length - 1"
            :editable="playlist.mine"
            @move="move(index, $event)"
            @remove="remove(item.id)"
          />
        </ul>
        <StateNote
          v-else
          tone="empty"
          :message="
            playlist.mine
              ? 'Empty. Add episodes from a show, or from any tile\'s dialog.'
              : 'Empty.'
          "
        />
      </section>
    </template>
  </div>
</template>

<style scoped lang="scss">
.pad {
  margin: var(--space-8);
}

.gap {
  margin-bottom: var(--space-4);
}

.title {
  margin: 0 0 var(--space-2);
  font-size: 32px;
}

.actions {
  display: flex;
  gap: var(--space-3);
  align-items: center;
}

.queue {
  padding: 0;
  margin: 0;
  list-style: none;
  border-top: 2px solid var(--color-divider);
}
</style>
