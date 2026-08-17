// Turning catalogue rows into words. Auto-imported: these are used in nearly
// every template, and threading an import through each one buys nothing.

import type { Episode } from '~/types/catalogue'

type Numbered = Pick<Episode, 'season' | 'episode' | 'episode_end'>

function pad(value: number): string {
  return String(value).padStart(2, '0')
}

/** `S01E07`, or `S02E13-14` when two aired as one. */
export function episodeCode(episode: Numbered): string {
  const end = episode.episode_end ? `-${pad(episode.episode_end)}` : ''
  return `S${pad(episode.season)}E${pad(episode.episode)}${end}`
}

/**
 * The episode's own name, or null when it hasn't got one.
 *
 * Half the sources title an episode with nothing but its numbering — the rows in
 * data/simpsonsua.jsonl are literally `"S30E07"`. The code is already on the
 * tile, so printing "S30E07 · S30E07" is noise; callers fall back to the code.
 */
export function episodeName(episode: Pick<Episode, 'title'> & Numbered): string | null {
  const plain = `s${pad(episode.season)}e${pad(episode.episode)}`
  const normalized = episode.title.toLowerCase().replace(/\s+/g, ' ').trim()
  return normalized.endsWith(plain) ? null : episode.title
}

/** What to put where a title goes, whichever of the two the source left us. */
export function episodeHeading(episode: Pick<Episode, 'title'> & Numbered): string {
  return episodeName(episode) ?? episodeCode(episode)
}

/** Seasons present, ascending. */
export function seasonsOf(episodes: Numbered[]): number[] {
  return [...new Set(episodes.map((episode) => episode.season))].sort((a, b) => a - b)
}

export function countLabel(count: number, one: string, many = `${one}s`): string {
  return `${count} ${count === 1 ? one : many}`
}

/** A show with one episode is a film. The catalogue has one table for both. */
export function isFilm(episodes: Numbered[]): boolean {
  return episodes.length === 1
}

/** `178000` -> `178K`. Vote counts are context, not quantities to read exactly. */
export function compactCount(value: number): string {
  if (value >= 1_000_000) return `${(value / 1_000_000).toFixed(1).replace(/\.0$/, '')}M`
  if (value >= 1_000) return `${Math.round(value / 1_000)}K`
  return String(value)
}

export function formatDate(iso: string): string {
  return new Intl.DateTimeFormat('en-GB', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  }).format(new Date(iso))
}
