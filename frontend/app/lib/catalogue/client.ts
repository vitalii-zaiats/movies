// The seam. Pages and components only ever see this interface, so swapping the
// fixtures for the real API is one line in the composable that picks an
// implementation — and nothing above it notices.

import type {
  EpisodePage,
  EpisodeQuery,
  EpisodeWithShow,
  Health,
  HistoryEntry,
  HistoryPage,
  DeviceLinkStatus,
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

export interface CatalogueClient {
  /** True when this is the fixture client. The UI says so rather than pretending. */
  readonly mocked: boolean

  health(): Promise<Health>

  /** Paged, and each row carries its episode counts — the catalogue is 8k titles. */
  shows(query?: ShowQuery): Promise<ShowPage>
  show(key: string): Promise<ShowWithEpisodes>

  episodes(query?: EpisodeQuery): Promise<EpisodePage>
  episode(id: number): Promise<EpisodeWithShow>

  // --- who's watching ------------------------------------------------------
  // Nobody has to sign in for any of this: the API answers `me()` with a guest
  // it mints on the spot, and that guest keeps a history like anyone else.
  // Registering claims the guest you already are, so nothing is left behind.

  me(): Promise<User>
  register(email: string, password: string, displayName?: string): Promise<Identity>
  signIn(email: string, password: string): Promise<Identity>
  signOut(): Promise<void>

  // --- signing in a television ---------------------------------------------
  // A device with no keyboard shows a code; this browser, where somebody is
  // already signed in, is the thing that says yes to it.

  deviceLink(code: string): Promise<DeviceLinkStatus>
  approveDevice(code: string): Promise<DeviceLinkStatus>

  /** Where to resume. Null when this episode was never started. */
  progress(episodeId: number): Promise<Progress | null>
  report(episodeId: number, report: ProgressReport): Promise<Progress>
  history(limit?: number, offset?: number): Promise<HistoryPage>
  /** Started and unfinished, newest first — the home screen's first rail. */
  continueWatching(limit?: number): Promise<HistoryEntry[]>

  playlists(): Promise<Playlist[]>
  playlist(id: number): Promise<PlaylistDetail>
  createPlaylist(name: string): Promise<PlaylistDetail>
  playlistFromShow(show: string, season?: number, name?: string): Promise<PlaylistDetail>
  deletePlaylist(id: number): Promise<void>
  addItem(id: number, episodeId: number): Promise<PlaylistDetail>
  removeItem(id: number, itemId: number): Promise<PlaylistDetail>
  reorder(id: number, itemIds: number[]): Promise<PlaylistDetail>
}

/** What the API answers with when it refuses; both clients throw this shape. */
export class CatalogueError extends Error {
  constructor(
    message: string,
    readonly status: number,
  ) {
    super(message)
    this.name = 'CatalogueError'
  }
}
