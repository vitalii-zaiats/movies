// Client for apps/api. Same origin everywhere: Vite proxies /api in dev, nginx
// proxies it in the image. One origin means one ngrok tunnel and no CORS.

const BASE = '/api'

export interface Show {
  id: number
  key: string
  title: string
  poster: string | null
}

export interface Episode {
  id: number
  season: number
  episode: number
  episode_end: number | null
  title: string
  poster: string | null
  vod_id: number | null
  vod_url: string | null
  /** `{vod_url}/index.m3u8` — the only URL a player needs. */
  playlist: string | null
  show: Show
}

export interface PlaylistItem {
  id: number
  position: number
  episode: Episode
}

export interface Playlist {
  id: number
  name: string
  created_at: string
  count: number
}

export interface PlaylistDetail extends Playlist {
  items: PlaylistItem[]
}

export interface EpisodePage {
  total: number
  limit: number
  offset: number
  items: Episode[]
}

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(`${BASE}${path}`, {
    ...init,
    headers: init?.body ? { 'content-type': 'application/json' } : undefined,
  })
  if (!response.ok) {
    const detail = await response.json().catch(() => null)
    throw new Error(detail?.detail ?? `${response.status} ${response.statusText}`)
  }
  return response.status === 204 ? (undefined as T) : ((await response.json()) as T)
}

export const api = {
  shows: () => request<Show[]>('/shows'),

  episodes: (params: Record<string, string | number | boolean | undefined> = {}) => {
    const query = new URLSearchParams()
    for (const [key, value] of Object.entries(params)) {
      if (value !== undefined && value !== '') query.set(key, String(value))
    }
    return request<EpisodePage>(`/episodes?${query}`)
  },

  playlists: () => request<Playlist[]>('/playlists'),
  playlist: (id: number) => request<PlaylistDetail>(`/playlists/${id}`),

  createPlaylist: (name: string) =>
    request<PlaylistDetail>('/playlists', { method: 'POST', body: JSON.stringify({ name }) }),

  createFromShow: (show: string, season?: number, name?: string) =>
    request<PlaylistDetail>('/playlists/from-show', {
      method: 'POST',
      body: JSON.stringify({ show, season, name }),
    }),

  deletePlaylist: (id: number) => request<void>(`/playlists/${id}`, { method: 'DELETE' }),

  addItem: (id: number, episodeId: number) =>
    request<PlaylistDetail>(`/playlists/${id}/items`, {
      method: 'POST',
      body: JSON.stringify({ episode_id: episodeId }),
    }),

  removeItem: (id: number, itemId: number) =>
    request<PlaylistDetail>(`/playlists/${id}/items/${itemId}`, { method: 'DELETE' }),

  reorder: (id: number, itemIds: number[]) =>
    request<PlaylistDetail>(`/playlists/${id}/order`, {
      method: 'PUT',
      body: JSON.stringify({ item_ids: itemIds }),
    }),
}
