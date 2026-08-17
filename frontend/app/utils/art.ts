// Artwork for things that haven't got any.
//
// Most crawled episodes come with `poster: null`, so every tile would be an
// empty box. Instead each one gets a figure derived from its key: the same show
// is the same colour on every page and across reloads, which is enough for the
// eye to navigate a rail by.

// The stripe pairs the design was drawn with — deep, desaturated, and drained
// further by .grayscale wherever the layout asks for it.
const PAIRS: readonly [string, string][] = [
  ['#3a3836', '#181614'],
  ['#48423e', '#201e1d'],
  ['#2e3234', '#141618'],
  ['#443c38', '#1c1a18'],
  ['#34383a', '#16181a'],
]

/** FNV-1a. Small, stable, and the same on every platform — which is the point. */
function hash(key: string): number {
  let value = 0x811c9dc5
  for (let index = 0; index < key.length; index++) {
    value ^= key.charCodeAt(index)
    value = Math.imul(value, 0x01000193)
  }
  return value >>> 0
}

export function artFor(key: string): { from: string; to: string } {
  const [from, to] = PAIRS[hash(key) % PAIRS.length] as [string, string]
  return { from, to }
}

/** The rail tile's ground: a soft diagonal. */
export function gradientFor(key: string): string {
  const { from, to } = artFor(key)
  return `linear-gradient(135deg, ${from}, ${to})`
}

/** The grid tile's ground: hard diagonal stripes, the system's louder option. */
export function stripesFor(key: string, band = 12): string {
  const { from, to } = artFor(key)
  return `repeating-linear-gradient(45deg, ${from} 0 ${band}px, ${to} ${band}px ${band * 2}px)`
}
