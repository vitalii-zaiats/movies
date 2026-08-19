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

## Five screens

**Welcome** is shown once, on a device with no session yet, and exists because
of the television. Two ways in: be a guest — one call, no decisions — or sign in
from a phone. The second draws a QR of `/link?code=…` and a code big enough to
read from a sofa, then polls every two seconds until somebody, elsewhere,
approves it. The same flow is reachable later from the account screen, which is
where a guest who skipped it ends up.

The QR is only as scannable as `KINO_HTTP` is reachable: the server hands out a
path, because it has no idea what address this device reached it on, and a
loopback that only the emulator's host understands makes a QR nobody can use.

**Home** becomes somebody first — `whoAmI` mints a guest server-side and the
token is kept on the device, so "continue watching" has something to be about
before anyone has signed up. Then a search box, a series filter, and the
catalogue paged as you scroll.

**Show** is what the crawl knew: original title, IMDb score and votes, year,
runtime, age rating, genres as language-neutral keys, the synopsis, and every
episode with a note against the ones that were never packaged.

**Player** takes the whole screen, sideways: its own transport, a scrubber, the
voices when a source published more than one dub, and chrome that leaves after
four seconds — though not while paused, because nobody pauses in order to look
at the picture. It opens where it was left and reports its position every ten
seconds and on the way out.

Leaving it puts the device back upright. `DeviceOrientation.values` alone does
not do that — it *allows* every orientation, and a screen already sideways has
no reason to turn back — so portrait is asked for first and everything is
allowed again a moment later.

**Account** is who you are and how to stop being a guest. Registering is
`claim`: an email and a password written onto the row you already are, so
nothing watched so far is lost. Also sign-in from another device, sign-out, a
second guest for the shared TV, and the light/dark choice.

## Icons, and the two themes

The icons are drawn rather than imported — see `widgets/glyph.dart`. Material's
are rounded and soft-capped, which is a good set and the wrong one beside square
corners, hairline rules and a display face at 800; and the obvious replacements
(Lucide, Feather, Phosphor) all cap their strokes round too. These are the
fifteen this app uses, on a 24-unit grid, stroked at 2 with square caps and
mitred joins.

Dark mode is not an invention either. `frontend` already describes a dark
surface — `--color-ink*`, and the `.on-ink` rules that lighten the accent,
because `#ec3013` on ink reads as maroon. Dark is that mode applied to the whole
page rather than to a caption. `System` follows the phone; the choice is kept
between launches.

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
- In the player, OK is play/pause, ◀ ▶ seek ten seconds, and Back leaves —
  the same three actions the on-screen transport has, so there is one player
  rather than a second one written for televisions.

Verified on a phone emulator and an iPhone simulator: guest minted, catalogue
browsed and paged, a film played, and it reappearing under "continue watching"
afterwards.

Verified on the 1080p television emulator too — `dumpsys uimode` reporting
`mCurUiMode=0x24`, so this is the leanback path and not a large phone. The whole
pairing was driven from a remote: focus down, Select, a code on screen, a
browser elsewhere approving it, and the catalogue opening as the account that
approved — still that account after a restart.

```bash
flutter test        # boots the app against a gRPC server in the same process
```
