// The fixture client.
//
// It answers the same questions apps/api does and answers them the same way —
// the ordering, the paging, the 404s and the dense playlist positions are all
// copied from the server rather than invented here. That is the point: when the
// real client takes over, no page above it has to change.

import { CatalogueError, type CatalogueClient } from './client'
import { fixtures } from './fixtures'
import type {
  DeviceLinkStatus,
  EpisodePage,
  EpisodeQuery,
  EpisodeWithShow,
  Health,
  Playlist,
  PlaylistDetail,
  HistoryEntry,
  HistoryPage,
  Identity,
  PlaylistItem,
  Progress,
  ProgressReport,
  Show,
  ShowPage,
  ShowQuery,
  ShowSummary,
  ShowWithEpisodes,
  User,
} from '~/types/catalogue'

// Enough for a spinner to be worth drawing. Loading states that are never seen
// in development are the ones that break in production.
const LATENCY = 140

function answer<T>(value: T): Promise<T> {
  return new Promise((resolve) => {
    setTimeout(() => resolve(structuredClone(value)), LATENCY)
  })
}

function fail(message: string, status = 404): never {
  throw new CatalogueError(message, status)
}

/** `Show.key, Episode.season, Episode.episode` — the server's order, verbatim. */
function inCatalogueOrder(a: EpisodeWithShow, b: EpisodeWithShow): number {
  return (
    a.show.key.localeCompare(b.show.key) || a.season - b.season || a.episode - b.episode
  )
}

function bare(episode: EpisodeWithShow): Omit<EpisodeWithShow, 'show'> {
  const { show: _show, ...rest } = episode
  return rest
}

/** The counts the server does in SQL, done here by walking the fixtures. */
function withCounts(show: Show): ShowSummary {
  const episodes = fixtures.episodes.filter((episode) => episode.show.key === show.key)
  return {
    ...show,
    episode_count: episodes.length,
    playable_count: episodes.filter((episode) => episode.vod_id !== null).length,
  }
}

/** What's been watched, newest first, with the episode each row is about. */
function entries(): HistoryEntry[] {
  return [...watched.values()]
    .sort((a, b) => b.last_watched_at.localeCompare(a.last_watched_at))
    .flatMap((progress) => {
      const episode = fixtures.episodes.find((candidate) => candidate.id === progress.episode_id)
      return episode ? [{ ...progress, episode }] : []
    })
}

function inShowOrder(order: ShowQuery['order']): (a: ShowSummary, b: ShowSummary) => number {
  if (order === 'title') return (a, b) => a.title.localeCompare(b.title)
  // Newest first, id as the tiebreak — a seed run stamps a whole batch at once.
  if (order === 'added') return (a, b) => b.created_at.localeCompare(a.created_at) || b.id - a.id
  return (a, b) => a.key.localeCompare(b.key)
}

// A guest, exactly as the API hands one out on first contact: no email, a name
// it made up, and a history that works anyway.
const stamp = '2026-08-01T12:00:00Z'
let viewer: User = {
  public_id: 'fixture-guest',
  display_name: 'Guest',
  email: null,
  role: 'user',
  is_guest: true,
  created_at: stamp,
  last_seen_at: stamp,
}

/** Progress lives as long as the tab does, which is long enough to develop against. */
const watched = new Map<number, Progress>()

// Playlists are the only thing here that changes, so they get their own state.
const playlists: PlaylistDetail[] = structuredClone(fixtures.playlists)
let nextPlaylistId = playlists.length + 1
let nextItemId = 10_000

/** Positions are rewritten from the array on every mutation, never patched. */
function renumber(playlist: PlaylistDetail): PlaylistDetail {
  playlist.items.forEach((item, index) => {
    item.position = index
  })
  playlist.count = playlist.items.length
  return playlist
}

function find(id: number): PlaylistDetail {
  return playlists.find((playlist) => playlist.id === id) ?? fail(`no playlist ${id}`)
}

function summary(playlist: PlaylistDetail): Playlist {
  const { items: _items, ...rest } = playlist
  return rest
}

export function createMockClient(): CatalogueClient {
  return {
    mocked: true,

    health: (): Promise<Health> =>
      answer({ status: 'ok', shows: fixtures.shows.length, episodes: fixtures.episodes.length }),

    shows: (query: ShowQuery = {}): Promise<ShowPage> => {
      const limit = query.limit ?? 50
      const offset = query.offset ?? 0
      const needle = query.q?.trim().toLowerCase()

      const matched = fixtures.shows
        .map(withCounts)
        .filter((show) => {
          if (needle && !show.title.toLowerCase().includes(needle)) return false
          if (query.series !== undefined && show.episode_count > 1 !== query.series) return false
          return true
        })
        .sort(inShowOrder(query.order))

      return answer({
        total: matched.length,
        limit,
        offset,
        items: matched.slice(offset, offset + limit),
      })
    },

    show: (key: string): Promise<ShowWithEpisodes> => {
      const show = fixtures.shows.find((candidate) => candidate.key === key) ?? fail(`no show ${key}`)
      const episodes = fixtures.episodes
        .filter((episode) => episode.show.key === key)
        .sort((a, b) => a.season - b.season || a.episode - b.episode)
        .map(bare)
      // The fixture catalogue knows a title and nothing else about it; these
      // exist so the dialog reads the same shape either way.
      return answer({
        ...show,
        original_title: null,
        year: null,
        description: null,
        duration: null,
        age_rating: null,
        genres: null,
        countries: null,
        directors: null,
        starring: null,
        imdb_id: null,
        imdb_rating: null,
        imdb_votes: null,
        imdb_url: null,
        episodes,
      })
    },

    episodes: (query: EpisodeQuery = {}): Promise<EpisodePage> => {
      const limit = query.limit ?? 50
      const offset = query.offset ?? 0
      const needle = query.q?.trim().toLowerCase()

      const matched = fixtures.episodes
        .filter((episode) => {
          if (query.show && episode.show.key !== query.show) return false
          if (query.season !== undefined && episode.season !== query.season) return false
          if (needle && !episode.title.toLowerCase().includes(needle)) return false
          if (query.playable !== undefined && (episode.vod_id !== null) !== query.playable) {
            return false
          }
          return true
        })
        .sort(inCatalogueOrder)

      return answer({
        total: matched.length,
        limit,
        offset,
        items: matched.slice(offset, offset + limit),
      })
    },

    episode: (id: number): Promise<EpisodeWithShow> =>
      answer(fixtures.episodes.find((episode) => episode.id === id) ?? fail(`no episode ${id}`)),

    me: (): Promise<User> => answer(viewer),

    register: (email: string, _password: string, displayName?: string): Promise<Identity> => {
      // Claiming keeps the same person — the guest becomes the account, which
      // is exactly what the API does and why history survives signing up.
      viewer = { ...viewer, email, display_name: displayName || email, is_guest: false }
      return answer({ token: 'fixture-token', user: viewer })
    },

    signIn: (email: string): Promise<Identity> => {
      viewer = { ...viewer, email, display_name: email, is_guest: false }
      return answer({ token: 'fixture-token', user: viewer })
    },

    signOut: async (): Promise<void> => {
      viewer = { ...viewer, email: null, display_name: 'Guest', is_guest: true }
      watched.clear()
      await answer(null)
    },

    // The fixtures can't have a television waiting on the other end, so an
    // unknown code is the honest answer to everything except the one below.
    deviceLink: (code: string): Promise<DeviceLinkStatus> =>
      code.toUpperCase() === 'DEMO42'
        ? answer({ code: 'DEMO42', device_name: 'Android TV (fixture)', approved: false, expires_in: 600 })
        : Promise.reject(new CatalogueError('no such code', 404)),

    approveDevice: (code: string): Promise<DeviceLinkStatus> =>
      answer({ code: code.toUpperCase(), device_name: 'Android TV (fixture)', approved: true, expires_in: 600 }),

    progress: (episodeId: number): Promise<Progress | null> =>
      answer(watched.get(episodeId) ?? null),

    report: (episodeId: number, report: ProgressReport): Promise<Progress> => {
      const duration = report.duration_seconds ?? watched.get(episodeId)?.duration_seconds ?? null
      const entry: Progress = {
        episode_id: episodeId,
        position_seconds: report.position_seconds,
        duration_seconds: duration,
        completed: report.completed ?? watched.get(episodeId)?.completed ?? false,
        ratio: duration ? Math.min(1, report.position_seconds / duration) : null,
        last_watched_at: new Date().toISOString(),
      }
      watched.set(episodeId, entry)
      return answer(entry)
    },

    history: (limit = 50, offset = 0): Promise<HistoryPage> => {
      const rows = entries()
      return answer({
        total: rows.length,
        limit,
        offset,
        items: rows.slice(offset, offset + limit),
      })
    },

    continueWatching: (limit = 20): Promise<HistoryEntry[]> =>
      answer(entries().filter((entry) => !entry.completed).slice(0, limit)),

    playlists: (): Promise<Playlist[]> => answer(playlists.map(summary)),

    playlist: (id: number): Promise<PlaylistDetail> => answer(find(id)),

    createPlaylist: (name: string): Promise<PlaylistDetail> => {
      const playlist: PlaylistDetail = {
        id: nextPlaylistId++,
        name,
        visibility: 'private',
        mine: true,
        created_at: new Date().toISOString(),
        count: 0,
        items: [],
      }
      playlists.push(playlist)
      return answer(playlist)
    },

    playlistFromShow: (key: string, season?: number, name?: string): Promise<PlaylistDetail> => {
      const show = fixtures.shows.find((candidate) => candidate.key === key) ?? fail(`no show ${key}`)
      const chosen = fixtures.episodes
        .filter(
          (episode) =>
            episode.show.key === key &&
            episode.vod_id !== null &&
            (season === undefined || episode.season === season),
        )
        .sort((a, b) => a.season - b.season || a.episode - b.episode)

      if (!chosen.length) fail('nothing playable to put in it', 400)

      const playlist: PlaylistDetail = {
        id: nextPlaylistId++,
        name: name || (season === undefined ? show.title : `${show.title} — season ${season}`),
        visibility: 'private',
        mine: true,
        created_at: new Date().toISOString(),
        count: 0,
        items: chosen.map((episode, index) => ({ id: nextItemId++, position: index, episode })),
      }
      playlists.push(playlist)
      return answer(renumber(playlist))
    },

    deletePlaylist: (id: number): Promise<void> => {
      const at = playlists.findIndex((playlist) => playlist.id === id)
      if (at < 0) fail(`no playlist ${id}`)
      playlists.splice(at, 1)
      return answer(undefined)
    },

    addItem: (id: number, episodeId: number): Promise<PlaylistDetail> => {
      const playlist = find(id)
      const episode =
        fixtures.episodes.find((candidate) => candidate.id === episodeId) ??
        fail(`no episode ${episodeId}`)
      // The server has a unique constraint on it, and says so with a 409.
      if (playlist.items.some((item) => item.episode.id === episodeId)) {
        fail('already in this playlist', 409)
      }
      playlist.items.push({ id: nextItemId++, position: playlist.items.length, episode })
      return answer(renumber(playlist))
    },

    removeItem: (id: number, itemId: number): Promise<PlaylistDetail> => {
      const playlist = find(id)
      const at = playlist.items.findIndex((item) => item.id === itemId)
      if (at < 0) fail(`no item ${itemId}`)
      playlist.items.splice(at, 1)
      return answer(renumber(playlist))
    },

    reorder: (id: number, itemIds: number[]): Promise<PlaylistDetail> => {
      const playlist = find(id)
      const byId = new Map(playlist.items.map((item) => [item.id, item]))
      if (itemIds.length !== byId.size || itemIds.some((itemId) => !byId.has(itemId))) {
        fail('the new order has to be a permutation of the old one', 400)
      }
      playlist.items = itemIds.map((itemId) => byId.get(itemId) as PlaylistItem)
      return answer(renumber(playlist))
    },
  }
}
