/// Genres, in the reader's language.
///
/// The wire carries language-neutral keys — `action`, `sci-fi`, `war` — because
/// what a genre is *called* depends on who is reading, and the crawler has no
/// business deciding that. This is the other half of that decision: the keys the
/// catalogue actually holds, named.
///
/// A table rather than ARB messages, because the set is open: a new source can
/// introduce a key tomorrow, and an unknown one should arrive as a readable word
/// rather than as a missing-translation crash. `sci-fi` becomes "Sci fi" if
/// nobody has named it yet, which is wrong-ish and legible, in that order.
library;

/// Every key in the catalogue today, counted from the database — not a guess at
/// what a video site might publish.
const _ukrainian = <String, String>{
  'drama': 'драма',
  'thriller': 'трилер',
  'comedy': 'комедія',
  'action': 'бойовик',
  'crime': 'кримінал',
  'melodrama': 'мелодрама',
  'adventure': 'пригоди',
  'horror': 'жахи',
  'sci-fi': 'фантастика',
  'detective': 'детектив',
  'fantasy': 'фентезі',
  'family': 'сімейний',
  'biography': 'біографія',
  'history': 'історичний',
  'war': 'військовий',
  'cartoon': 'мультфільм',
  'sport': 'спорт',
  'documentary': 'документальний',
  'music': 'музика',
  'mystery': 'містика',
  'western': 'вестерн',
  'musical': 'мюзикл',
  'anime': 'аніме',
  'erotic': 'еротика',
  'reality-show': 'реаліті-шоу',
  'film': 'фільм',
  'adult': 'для дорослих',
  'short': 'короткометражний',
};

/// Only where the key is not already the English word. Everything else falls
/// through to the key itself, which is what it was named after.
const _english = <String, String>{
  'sci-fi': 'sci-fi',
  'reality-show': 'reality show',
};

String genreName(String key, String language) {
  final named = language == 'uk' ? _ukrainian[key] : _english[key];
  return named ?? _readable(key);
}

/// `reality-show` → `reality show`. Not title case: these sit in chips beside
/// each other, and the system already sets their case.
String _readable(String key) => key.replaceAll('-', ' ');
