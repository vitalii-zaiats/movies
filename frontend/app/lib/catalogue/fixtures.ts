// The stand-in catalogue.
//
// Shaped after what the crawlers actually produce, not after what would flatter
// the UI: posters are usually missing, some episodes never got a stream, and one
// show's episode "titles" are just the codes the source page had — which is
// exactly what data/simpsonsua.jsonl looks like. If the front end survives this,
// it survives the real thing.

import type { EpisodeWithShow, PlaylistDetail, Show } from '~/types/catalogue'

interface Seed {
  key: string
  title: string
  poster: string | null
  /** Episodes per season, in order. */
  seasons: number[]
  /** Cycled to name episodes. Empty means the source only left a code. */
  titles: string[]
  /** Every nth episode arrives without a stream. Omit and they all have one. */
  unplayableEvery?: number
  /** `[season, episode, end]` — one pair aired as a single entry. */
  pair?: [number, number, number]
  origin: (season: number, episode: number) => string
}

const SEEDS: Seed[] = [
  {
    key: 'family-guy',
    title: 'Family Guy',
    poster: null,
    seasons: [7, 21, 22],
    titles: [
      'Death Has a Shadow',
      'I Never Met the Dead Man',
      'Chitty Chitty Death Bang',
      'Mind Over Murder',
      'A Hero Sits Next Door',
      'The Son Also Draws',
      'Brian: Portrait of a Dog',
      'Peter, Peter, Caviar Eater',
      'Holy Crap',
      'Da Boom',
      'Brian in Love',
      'Love Thy Trophy',
      'Fifteen Minutes of Shame',
      'Road to Rhode Island',
      'Let’s Go to the Hop',
      'Dammit Janet!',
      'There’s Something About Paulie',
      'He’s Too Sexy for His Fat',
      'E. Peterbus Unum',
      'The Story on Page One',
      'Wasted Talent',
    ],
    unplayableEvery: 11,
    origin: (season, episode) =>
      `https://simpsonsua.tv/family-guy-sezon-${season}/${1000 + season * 100 + episode}-family-guy-${season}-sezon-${episode}-seriya.html`,
  },
  {
    key: 'the-simpsons',
    title: 'The Simpsons',
    poster: null,
    // No titles at all: the listing page numbers its episodes and nothing else.
    seasons: [13, 22, 24],
    titles: [],
    unplayableEvery: 7,
    pair: [2, 13, 14],
    origin: (season, episode) =>
      `https://simpsonsua.tv/lgbt/${3000 + season * 30 + episode}-${season}-sezon-${episode}-seriya.html`,
  },
  {
    key: 'rick-and-morty',
    title: 'Rick and Morty',
    poster: null,
    seasons: [11, 10],
    titles: [
      'Pilot',
      'Lawnmower Dog',
      'Anatomy Park',
      'M. Night Shaym-Aliens!',
      'Meeseeks and Destroy',
      'Rick Potion #9',
      'Raising Gazorpazorp',
      'Rixty Minutes',
      'Something Ricked This Way Comes',
      'Close Rick-Counters of the Rick Kind',
      'Ricksy Business',
    ],
    origin: (season, episode) =>
      `https://simpsonsua.tv/rick-and-morty-sezon-${season}/${2000 + season * 50 + episode}-rick-and-morty-${season}-sezon-${episode}-seriya.html`,
  },
  {
    key: 'futurama',
    title: 'Futurama',
    poster: null,
    seasons: [9, 20],
    titles: [
      'Space Pilot 3000',
      'The Series Has Landed',
      'I, Roommate',
      'Love’s Labours Lost in Space',
      'Fear of a Bot Planet',
      'A Fishful of Dollars',
      'My Three Suns',
      'A Big Piece of Garbage',
      'Hell Is Other Robots',
    ],
    unplayableEvery: 5,
    origin: (season, episode) =>
      `https://simpsonsua.tv/futurama-sezon-${season}/${4000 + season * 40 + episode}-futurama-${season}-sezon-${episode}-seriya.html`,
  },
]

/** Films: one show, one season, one episode. The kinoukr crawler's whole output. */
const FILMS: { key: string; title: string; poster: string | null; url: string }[] = [
  {
    key: 'test-na-teshchu-2',
    title: 'Тест на тещу 2',
    poster: 'https://kinoukr.tv/uploads/mini/short/0/6e6085371a6efd19fc873b763fd414.jpg',
    url: 'https://kinoukr.tv/9153-test-na-teshchu-2.html',
  },
  {
    key: 'myachi-dogory',
    title: 'М’ячі догори',
    poster: 'https://kinoukr.tv/uploads/mini/short/e/a35f99cf4024207bccdc7a19fdf01b.jpg',
    url: 'https://kinoukr.tv/9152-myachi-dogory.html',
  },
  {
    key: 'goryly-attenboro',
    title: 'Горили: Історія від Девіда Аттенборо',
    poster: null,
    url: 'https://kinoukr.tv/9151-goryly-istoriya-vid-devida-attenboro.html',
  },
  {
    key: 'ostannya-zmina',
    title: 'Остання зміна',
    poster: null,
    url: 'https://kinoukr.tv/9148-ostannya-zmina.html',
  },
]

// Fixed, so "recently added" means the same thing on every reload and two runs
// of the app can be compared. One row an hour, oldest first.
const EPOCH = Date.parse('2026-05-01T09:00:00Z')

function stamp(step: number): string {
  return new Date(EPOCH + step * 3_600_000).toISOString()
}

export interface Fixtures {
  shows: Show[]
  /** Every episode, with its show attached — the shape `GET /episodes` returns. */
  episodes: EpisodeWithShow[]
  playlists: PlaylistDetail[]
}

function build(): Fixtures {
  const shows: Show[] = []
  const episodes: EpisodeWithShow[] = []

  let showId = 0
  let episodeId = 0
  let vodId = 0
  let step = 0

  const add = (
    show: Show,
    season: number,
    number: number,
    title: string,
    origin: string,
    playable: boolean,
    end: number | null,
  ): void => {
    const vod = playable ? ++vodId : null
    episodes.push({
      id: ++episodeId,
      season,
      episode: number,
      episode_end: end,
      title,
      // The crawlers hardly ever find one per episode; the tiles are drawn from
      // the key instead, which is why the design leans on generated art.
      poster: null,
      source_url: origin,
      vod_id: vod,
      vod_url: vod === null ? null : `/vod/${vod}`,
      playlist: vod === null ? null : `/vod/${vod}/index.m3u8`,
      // One voice, unnamed: these sources say nothing about who dubbed what,
      // and inventing a second one would only exercise a control that lies.
      tracks: vod === null ? [] : [{ vod_id: vod, audio: null, playlist: `/vod/${vod}/index.m3u8` }],
      show,
    })
  }

  for (const seed of SEEDS) {
    const show: Show = {
      id: ++showId,
      key: seed.key,
      title: seed.title,
      is_film: false,
      poster: seed.poster,
      created_at: stamp(step),
    }
    shows.push(show)

    let named = 0
    const pair = seed.pair
    seed.seasons.forEach((count, index) => {
      const season = index + 1
      for (let number = 1; number <= count; number++) {
        const opensPair = pair !== undefined && pair[0] === season && pair[1] === number
        // The second half of a pair has no row of its own — the first one covers
        // both, which is what `episode_end` is for.
        const closesPair = pair !== undefined && pair[0] === season && pair[2] === number
        if (closesPair) continue

        const title = seed.titles.length
          ? (seed.titles[named++ % seed.titles.length] as string)
          : // What the source page called it, which is nothing but the numbers.
            `${seed.key} S${String(season).padStart(2, '0')}E${String(number).padStart(2, '0')}`
        const playable = !seed.unplayableEvery || (number + season) % seed.unplayableEvery !== 0

        add(
          show,
          season,
          number,
          title,
          seed.origin(season, number),
          playable,
          opensPair ? pair[2] : null,
        )
        step++
      }
    })
  }

  for (const film of FILMS) {
    const show: Show = {
      id: ++showId,
      key: film.key,
      title: film.title,
      is_film: true,
      poster: film.poster,
      created_at: stamp(step),
    }
    shows.push(show)
    // A film is an episode too — the catalogue has one table for both.
    add(show, 1, 1, film.title, film.url, true, null)
    step++
  }

  return { shows, episodes, playlists: seedPlaylists(episodes) }
}

function seedPlaylists(episodes: EpisodeWithShow[]): PlaylistDetail[] {
  const playable = (key: string, season?: number): EpisodeWithShow[] =>
    episodes.filter(
      (episode) =>
        episode.show.key === key &&
        episode.playlist !== null &&
        (season === undefined || episode.season === season),
    )

  const of = (id: number, name: string, created: string, items: EpisodeWithShow[]): PlaylistDetail => ({
    id,
    name,
    // The fixture catalogue is one person's, so these are theirs to edit — the
    // published-by-somebody-else case is what the real API is for.
    visibility: 'private',
    mine: true,
    created_at: created,
    count: items.length,
    items: items.map((episode, index) => ({ id: id * 1000 + index, position: index, episode })),
  })

  return [
    of(1, 'Family Guy — season 1', stamp(400), playable('family-guy', 1)),
    of(2, 'Sunday night', stamp(420), [
      ...playable('rick-and-morty', 1).slice(0, 4),
      ...playable('futurama', 1).slice(0, 3),
    ]),
    of(3, 'Films', stamp(440), FILMS.flatMap((film) => playable(film.key))),
  ]
}

/** One dataset per page load; the mock client is free to mutate its playlists. */
export const fixtures: Fixtures = build()
