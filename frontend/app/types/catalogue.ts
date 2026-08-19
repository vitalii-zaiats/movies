// The catalogue's DTOs, exactly as apps/api hands them out — snake_case and
// all. Nothing here is renamed on the way in: when a field moves on the server
// this file is the one that has to change, and the compiler finds the rest.

export interface Show {
  id: number
  key: string
  title: string
  poster: string | null
  created_at: string
  /** One episode and no more. The catalogue has one table for both shapes. */
  is_film: boolean
}

/** A show in a browse list: the server counts its episodes so the UI needn't ask. */
export interface ShowSummary extends Show {
  episode_count: number
  /** How many of those have a stream behind them. */
  playable_count: number
}

/** One way to hear an episode. More than one means somebody dubbed it twice. */
export interface Track {
  vod_id: number
  /** The studio, when the source named it. */
  audio: string | null
  playlist: string
}

export interface Episode {
  id: number
  season: number
  episode: number
  /** Set when two were aired as one — "13-14". */
  episode_end: number | null
  title: string
  poster: string | null
  source_url: string
  vod_id: number | null
  vod_url: string | null
  /** `{vod_url}/index.m3u8` — the only URL a player needs. Null until seeded. */
  playlist: string | null
  /** Every dub of this episode; the default one is `playlist`. */
  tracks: Track[]
}

export interface EpisodeWithShow extends Episode {
  show: Show
}

/**
 * What the crawl knew about a title. Only the detail route carries it: a
 * synopsis inside every row of every listing is prose nobody asked for.
 */
export interface ShowDetails extends Show {
  original_title: string | null
  year: number | null
  description: string | null
  duration: string | null
  age_rating: string | null
  /** Language-neutral keys — `action`, `sci-fi`. Naming them is this app's job. */
  genres: string[] | null
  countries: string[] | null
  directors: string[] | null
  starring: string[] | null
  imdb_id: string | null
  imdb_rating: number | null
  imdb_votes: number | null
  imdb_url: string | null
}

export interface ShowWithEpisodes extends ShowDetails {
  episodes: Episode[]
}

export interface Playlist {
  id: number
  name: string
  visibility: 'private' | 'public'
  created_at: string
  count: number
  /** Whether the API will let *this* caller change it: owner, or an admin. */
  mine: boolean
}

export interface PlaylistItem {
  id: number
  /** Dense and 0-based; the server rewrites it on every mutation. */
  position: number
  episode: EpisodeWithShow
}

export interface PlaylistDetail extends Playlist {
  items: PlaylistItem[]
}

export interface Page {
  total: number
  limit: number
  offset: number
}

export interface EpisodePage extends Page {
  items: EpisodeWithShow[]
}

export interface ShowPage extends Page {
  items: ShowSummary[]
}

/** The query string of `GET /shows`, as an object. */
export interface ShowQuery {
  /** Substring of the title. */
  q?: string
  /** True: more than one episode. False: exactly one, which is how a film looks. */
  series?: boolean
  /**
   * `newest`/`oldest` are by release year — the fact — rather than by when a
   * row happened to be synced, which a bulk rebuild makes meaningless.
   */
  order?: 'key' | 'added' | 'title' | 'newest' | 'oldest'
  limit?: number
  offset?: number
}

export interface Health {
  status: string
  shows: number
  episodes: number
}

/**
 * Who's watching. Everybody is somebody here: the API mints a guest on first
 * contact, so history and progress work before anyone signs up, and claiming an
 * account keeps the same row rather than starting a new one.
 */
export interface User {
  public_id: string
  display_name: string
  email: string | null
  role: 'user' | 'admin'
  is_guest: boolean
  created_at: string
  last_seen_at: string
}

/** A user with the token that proves it — handed out once, when a session starts. */
export interface Identity {
  token: string
  user: User
}

/**
 * A device asking to be signed in, as seen by the browser about to say yes.
 *
 * No secret here on purpose. The code is enough to *approve*; collecting the
 * session needs the secret, which never leaves the device that asked.
 */
export interface DeviceLinkStatus {
  code: string
  device_name: string | null
  approved: boolean
  expires_in: number
}

export interface Progress {
  episode_id: number
  position_seconds: number
  duration_seconds: number | null
  completed: boolean
  /** How far in, 0–1. Null until a duration is known. */
  ratio: number | null
  last_watched_at: string
}

export interface HistoryEntry extends Progress {
  episode: EpisodeWithShow
}

export interface HistoryPage extends Page {
  items: HistoryEntry[]
}

/** What the player reports back. Everything but the position is optional. */
export interface ProgressReport {
  position_seconds: number
  duration_seconds?: number
  completed?: boolean
}

/** The query string of `GET /episodes`, as an object. */
export interface EpisodeQuery {
  show?: string
  season?: number
  /** Substring of the title. */
  q?: string
  /** Only the ones with a VOD behind them. */
  playable?: boolean
  limit?: number
  offset?: number
}
