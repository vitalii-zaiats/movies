// The real client — apps/api over the same origin the app was served from.
//
// Nothing here is wired up until NUXT_PUBLIC_USE_MOCKS is false. It exists now
// so that the fixture client has something to be shaped like, and so the switch
// is a config change rather than a rewrite.

import { CatalogueError, type CatalogueClient } from './client'
import type {
  EpisodePage,
  EpisodeQuery,
  EpisodeWithShow,
  Health,
  HistoryEntry,
  HistoryPage,
  Identity,
  Playlist,
  PlaylistDetail,
  Progress,
  ProgressReport,
  ShowPage,
  ShowQuery,
  ShowWithEpisodes,
  User,
} from '~/types/catalogue'

export function createHttpClient(baseURL: string): CatalogueClient {
  const call = $fetch.create({
    baseURL,
    // The API's refusals all come back as `{"detail": "..."}` with a status that
    // means something (404, 409, 400). Keep both; the UI shows the one and
    // branches on the other.
    onResponseError({ response }) {
      const detail = (response._data as { detail?: string } | null)?.detail
      throw new CatalogueError(detail ?? `${response.status} ${response.statusText}`, response.status)
    },
  })

  return {
    mocked: false,

    health: () => call<Health>('/health'),

    shows: (query: ShowQuery = {}) => call<ShowPage>('/shows', { query }),
    show: (key) => call<ShowWithEpisodes>(`/shows/${encodeURIComponent(key)}`),

    episodes: (query: EpisodeQuery = {}) => call<EpisodePage>('/episodes', { query }),
    episode: (id) => call<EpisodeWithShow>(`/episodes/${id}`),

    // The session is a cookie the API sets, and this app is served from the same
    // origin it calls — so there is nothing to attach here and no token to keep.
    me: () => call<User>('/auth/me'),

    register: (email, password, displayName) =>
      call<Identity>('/auth/claim', {
        method: 'POST',
        body: { email, password, display_name: displayName },
      }),

    signIn: (email, password) =>
      call<Identity>('/auth/login', { method: 'POST', body: { email, password } }),

    signOut: async () => {
      await call('/auth/logout', { method: 'POST' })
    },

    progress: async (episodeId) => {
      try {
        return await call<Progress>(`/me/progress/${episodeId}`)
      } catch (cause) {
        // 404 is the API's way of saying "never started" — a fact, not a fault.
        if (cause instanceof CatalogueError && cause.status === 404) return null
        throw cause
      }
    },

    report: (episodeId, report: ProgressReport) =>
      call<Progress>(`/me/progress/${episodeId}`, { method: 'PUT', body: report }),

    history: (limit = 50, offset = 0) =>
      call<HistoryPage>('/me/history', { query: { limit, offset } }),

    continueWatching: (limit = 20) => call<HistoryEntry[]>('/me/continue', { query: { limit } }),

    playlists: () => call<Playlist[]>('/playlists'),
    playlist: (id) => call<PlaylistDetail>(`/playlists/${id}`),

    createPlaylist: (name) => call<PlaylistDetail>('/playlists', { method: 'POST', body: { name } }),

    playlistFromShow: (show, season, name) =>
      call<PlaylistDetail>('/playlists/from-show', {
        method: 'POST',
        body: { show, season, name },
      }),

    deletePlaylist: async (id) => {
      await call(`/playlists/${id}`, { method: 'DELETE' })
    },

    addItem: (id, episodeId) =>
      call<PlaylistDetail>(`/playlists/${id}/items`, {
        method: 'POST',
        body: { episode_id: episodeId },
      }),

    removeItem: (id, itemId) =>
      call<PlaylistDetail>(`/playlists/${id}/items/${itemId}`, { method: 'DELETE' }),

    reorder: (id, itemIds) =>
      call<PlaylistDetail>(`/playlists/${id}/order`, {
        method: 'PUT',
        body: { item_ids: itemIds },
      }),
  }
}
