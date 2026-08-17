<script setup lang="ts">
// What a tile opens into: the title, what the crawl learned about it, and the
// two things worth doing with it — play it, or queue it.
//
// The dialog is opened with one episode but is about the *show*, so it fetches
// the detail route on mount. That's where the year, the genres and the IMDb
// score live, and for a series it's also where the episodes are: choosing a
// season and an episode is a modal's job here, not a page's.

import type { Episode, EpisodeWithShow, Playlist, ShowWithEpisodes } from '~/types/catalogue'

const props = defineProps<{ episode: EpisodeWithShow }>()
const emit = defineEmits<{ close: [] }>()

const catalogue = useCatalogue()

const show = ref<ShowWithEpisodes | null>(null)
const playlists = ref<Playlist[]>([])
const target = ref<number | null>(null)
const status = ref<string | null>(null)
const busy = ref(false)

// Which episode Play means. Starts as the one that was clicked; a series lets
// you move it.
const chosen = ref<Episode>({ ...props.episode })
const season = ref<number | null>(props.episode.season)

onMounted(async () => {
  const [detail, lists] = await Promise.all([
    catalogue.show(props.episode.show.key).catch(() => null),
    catalogue.playlists().catch(() => [] as Playlist[]),
  ])
  show.value = detail
  // Only the ones this viewer may write to. Offering somebody else's published
  // list would produce a 404 the moment it was used.
  playlists.value = lists.filter((list) => list.mine)
  target.value = playlists.value[0]?.id ?? null
})

/** No list to add to yet — a guest has none until they make one. */
async function startList(): Promise<void> {
  busy.value = true
  status.value = null
  try {
    const created = await catalogue.createPlaylist('My list')
    playlists.value = [{ ...created, count: created.items.length }]
    target.value = created.id
    await queue()
  } catch (cause) {
    status.value = (cause as Error).message
  } finally {
    busy.value = false
  }
}

// A synopsis runs to a thousand characters and the dialog is not an article.
// Three lines, then the reader asks for the rest.
const expanded = ref(false)

const film = computed(() => props.episode.show.is_film)
const episodes = computed(() => show.value?.episodes ?? [])
const seasons = computed(() => seasonsOf(episodes.value))
const inSeason = computed(() =>
  episodes.value.filter((entry) => season.value === null || entry.season === season.value),
)

/** IMDb, as a line. Votes matter: a 9.9 from four people is not a 9.9. */
const rating = computed(() => {
  const score = show.value?.imdb_rating
  if (!score) return null
  const votes = show.value?.imdb_votes
  return votes ? `${score.toFixed(1)} · ${compactCount(votes)} votes` : score.toFixed(1)
})

const facts = computed(() => {
  const detail = show.value
  if (!detail) return []
  return [
    detail.year ? String(detail.year) : null,
    detail.duration,
    detail.age_rating,
    detail.countries?.length ? detail.countries.join(', ') : null,
  ].filter((fact): fact is string => Boolean(fact))
})

function pick(entry: Episode): void {
  chosen.value = entry
}

async function queue(): Promise<void> {
  if (target.value === null) return
  busy.value = true
  status.value = null
  try {
    const detail = await catalogue.addItem(target.value, chosen.value.id)
    status.value = `Queued in “${detail.name}” — ${countLabel(detail.count, 'item')}.`
  } catch (cause) {
    status.value = (cause as Error).message
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <UiDialog @close="emit('close')">
    <div class="split">
      <div class="text">
        <span v-if="show?.original_title" class="tag tag-accent kicker">
          {{ show.original_title }}
        </span>

        <h2 class="title">{{ episode.show.title }}</h2>

        <div class="meta">
          <a
            v-if="rating"
            class="imdb"
            :href="show?.imdb_url ?? undefined"
            target="_blank"
            rel="noreferrer"
          >
            <span class="star">★</span> {{ rating }}
          </a>
          <span v-for="fact in facts" :key="fact">{{ fact }}</span>
          <span v-if="!film && episodes.length">{{ countLabel(episodes.length, 'episode') }}</span>
          <span v-if="!chosen.playlist" class="tag-rule">no stream</span>
        </div>

        <div v-if="show?.genres?.length" class="genres">
          <span v-for="genre in show.genres" :key="genre" class="tag">{{ genre }}</span>
        </div>

        <template v-if="show?.description">
          <p class="lede" :class="{ clamped: !expanded }">{{ show.description }}</p>
          <button type="button" class="more" @click="expanded = !expanded">
            {{ expanded ? 'Less' : 'More' }}
          </button>
        </template>
        <p v-else-if="show" class="lede muted">No synopsis — the source page carried none.</p>

        <dl v-if="show?.directors?.length || show?.starring?.length" class="facts">
          <template v-if="show?.directors?.length">
            <dt>Director</dt>
            <dd>{{ show.directors.join(', ') }}</dd>
          </template>
          <template v-if="show?.starring?.length">
            <dt>Cast</dt>
            <dd>{{ show.starring.slice(0, 5).join(', ') }}</dd>
          </template>
        </dl>

        <!-- A series is chosen from, not just played: pick the season, then the
             episode, and Play follows whatever is picked. -->
        <div v-if="!film && episodes.length" class="episodes">
          <SeasonTabs v-if="seasons.length > 1" v-model="season" :seasons="seasons" />

          <ul class="list">
            <li v-for="entry in inSeason" :key="entry.id">
              <button
                type="button"
                class="entry"
                :class="{ on: entry.id === chosen.id, dead: !entry.playlist }"
                @click="pick(entry)"
              >
                <span class="mono code">{{ episodeCode(entry) }}</span>
                <span class="name">{{ episodeName(entry) ?? '—' }}</span>
                <span v-if="!entry.playlist" class="tag tag-neutral">no stream</span>
              </button>
            </li>
          </ul>
        </div>

        <div class="queue">
          <template v-if="playlists.length">
            <label class="visually-hidden" for="queue-target">Playlist</label>
            <select id="queue-target" v-model="target" class="input">
              <option v-for="playlist in playlists" :key="playlist.id" :value="playlist.id">
                {{ playlist.name }} · {{ playlist.count }}
              </option>
            </select>
            <button type="button" class="btn btn-secondary" :disabled="busy" @click="queue">
              Add
            </button>
          </template>
          <button v-else type="button" class="btn btn-secondary" :disabled="busy" @click="startList">
            Add to my list
          </button>
        </div>
        <p v-if="status" class="status">{{ status }}</p>

        <div class="actions">
          <NuxtLink
            v-if="chosen.playlist"
            :to="`/watch/${chosen.id}`"
            class="btn btn-primary"
            @click="emit('close')"
          >
            {{ film ? 'Play' : `Play ${episodeCode(chosen)}` }}
          </NuxtLink>
          <button v-else type="button" class="btn btn-primary" disabled>Nothing to play</button>
          <NuxtLink
            :to="`/shows/${episode.show.key}`"
            class="btn btn-secondary"
            @click="emit('close')"
          >
            Open page
          </NuxtLink>
          <button type="button" class="btn btn-ghost close" @click="emit('close')">Close</button>
        </div>
      </div>

      <ArtFrame
        :art-key="episode.show.key"
        :poster="episode.poster ?? episode.show.poster"
        ratio="auto"
        variant="stripes"
        drained
        class="art"
      />
    </div>
  </UiDialog>
</template>

<style scoped lang="scss">
.split {
  display: grid;
  grid-template-columns: 1fr minmax(240px, 380px);
}

.text {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
  padding: var(--space-6);
  overflow-y: auto;
  max-height: min(82vh, 760px);
}

.kicker {
  align-self: flex-start;
}

.title {
  margin: 0;
  font-size: 28px;
  line-height: 1.05;
}

.meta {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-4);
  align-items: center;
  font-size: 14px;
  color: color-mix(in srgb, var(--color-text) 70%, transparent);
}

.imdb {
  font-weight: 700;
  color: inherit;
  text-decoration: none;

  .star {
    color: var(--color-accent);
  }

  &:hover {
    color: var(--color-accent);
  }
}

.genres {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
}

.lede {
  margin: 0;
  font-size: 14px;
  line-height: 1.45;
  white-space: pre-line;
}

// Three lines is a taste of it; the button is there for whoever wants the rest.
.clamped {
  display: -webkit-box;
  overflow: hidden;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 3;
}

.more {
  align-self: flex-start;
  padding: 0;
  font: inherit;
  font-size: 13px;
  font-weight: 700;
  color: var(--color-accent);
  cursor: pointer;
  background: none;
  border: 0;
}

.muted {
  color: color-mix(in srgb, var(--color-text) 60%, transparent);
}

.facts {
  display: grid;
  grid-template-columns: auto 1fr;
  gap: 2px var(--space-4);
  margin: 0;
  font-size: 13px;

  dt {
    font-weight: 700;
  }

  dd {
    margin: 0;
    color: color-mix(in srgb, var(--color-text) 75%, transparent);
  }
}

.episodes {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.list {
  display: flex;
  flex-direction: column;
  max-height: 210px;
  padding: 0;
  margin: 0;
  overflow-y: auto;
  list-style: none;
  border: 2px solid var(--color-divider);
}

.entry {
  display: flex;
  gap: var(--space-4);
  align-items: center;
  width: 100%;
  padding: var(--space-2) var(--space-3);
  font: inherit;
  font-size: 14px;
  color: inherit;
  text-align: left;
  cursor: pointer;
  background: none;
  border: 0;
  border-bottom: 1px solid var(--color-divider);

  &:hover {
    background: color-mix(in srgb, var(--color-text) 6%, transparent);
  }

  &.on {
    color: var(--color-bg);
    background: var(--color-accent);
  }

  &.dead .name {
    color: color-mix(in srgb, currentcolor 55%, transparent);
  }
}

.code {
  flex: none;
}

.name {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.queue {
  display: flex;
  gap: var(--space-3);
  align-items: center;
}

.status {
  margin: 0;
  font-size: 13px;
}

.actions {
  display: flex;
  gap: var(--space-3);
  align-items: center;
  margin-top: auto;
}

.close {
  margin-left: auto;
}

.art {
  align-self: stretch;
}

@media (max-width: 860px) {
  .split {
    grid-template-columns: 1fr;
  }

  .art {
    display: none;
  }
}
</style>
