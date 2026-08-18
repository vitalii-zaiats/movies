# kino_app

The catalogue on a phone, and — with the same binary — on a television.
Everything it knows comes through [`kino_api`](../kino_api) over gRPC; the only
HTTP it makes is the video player fetching the stream.

```bash
flutter run                                    # emulator: talks to 10.0.2.2
flutter run --dart-define=KINO_HOST=192.168.0.10 \
            --dart-define=KINO_HTTP=http://192.168.0.10
```

| define            | default              | what                                   |
|-------------------|-----------------------|-----------------------------------------|
| `KINO_HOST`       | `10.0.2.2`            | where `api-grpc` is                     |
| `KINO_GRPC_PORT`  | `50061`               |                                         |
| `KINO_HTTP`       | `http://10.0.2.2`     | where nginx is — posters and streams     |

Two addresses because there are two: gRPC has a port of its own, and the server
hands out paths (`/vod/7455/index.m3u8`) rather than URLs, since it has no idea
what address the phone reached it on.

## Three screens

**Home** becomes somebody first — `whoAmI` mints a guest server-side and the
token is kept on the device, so "continue watching" has something to be about
before anyone has signed up. Then a search box, a series filter, and the
catalogue paged as you scroll.

**Show** is what the crawl knew: original title, IMDb score and votes, year,
runtime, age rating, genres as language-neutral keys, the synopsis, and every
episode with a note against the ones that were never packaged.

**Player** opens where it was left, reports its position every ten seconds and
on the way out, and offers the voices when a source published more than one dub.

## Android TV

The same app. What differs is how it's driven: a remote moves focus and presses
it, which in Flutter means `NavigationMode.directional`, and once that's on
whatever is focused has to *look* focused.

- `MainActivity` answers "is this a television" from `UiModeManager` rather than
  from the screen size — a landscape tablet looks identical to a layout and
  behaves nothing like one.
- The manifest declares `leanback` and `touchscreen` as `required="false"`. The
  second matters more than it looks: a TV has no touchscreen, and that feature
  defaults to required, which alone is enough to hide an app from a TV.
- In the player, OK is play/pause, ◀ ▶ seek ten seconds, and Back leaves. The
  floating button is hidden there — a button nobody can reach is worse than no
  button.

Verified on a phone emulator, end to end: guest, browse, play, and the film
reappearing under "continue watching". **Not** verified on a television — the TV
emulator wouldn't start here, and none of the leanback path has been seen
running.

```bash
flutter test        # boots the app against a gRPC server in the same process
```
