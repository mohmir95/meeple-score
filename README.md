# Board Game Score Sheet

A client-side Flutter web app for keeping score while playing board games with friends. Each game has its own score sheet and scoring rules. Shared pieces — players, totals, history, dialogs, and navigation — stay reusable.

The first version runs entirely in the browser. There is no account system, no backend, and no cloud sync. An in-progress game is stored on the device so a refresh or restart does not wipe it.

Live hosting is intended for **GitHub Pages**, which is free.

## Run locally

You need [Flutter](https://docs.flutter.dev/get-started/install) 3.11+ (Dart 3.11+). This project targets **web only**.

```bash
flutter pub get
flutter run -d chrome --web-port=8080
```

Use a fixed port so the browser can keep scores in local storage. A new random port looks like a different website to the browser, so saved games would not show up.

Other useful commands:

```bash
flutter analyze
flutter test
flutter build web --release --base-href /
```

To try a GitHub Pages-style subpath locally:

```bash
flutter build web --release --base-href /board-game-score-sheet/
```

Then serve `build/web` with any static file server.

## Architecture

The app uses a small feature-oriented layout with three layers:

| Layer | Where | Responsibility |
| --- | --- | --- |
| Presentation | `lib/features/`, `lib/shared/`, game `*_sheet.dart` / `*_setup.dart` | Screens, shared widgets, game-specific UI |
| Domain | `lib/domain/`, game `*_scoring.dart` / `*_state.dart` | Game contract, models, scoring rules |
| Data | `lib/data/` | Local persistence |

**Design choices:**

- **One `BoardGame` contract.** Every game supplies a name, icon, config, state, scoring, and its own score sheet widget. Shared screens never switch on a game id.
- **Colocate each game.** A new game lives in `lib/games/<id>/`. Existing games are not edited when you add another one. The only shared registration point is `GameRegistry`.
- **Pure scoring, Flutter UI.** Scoring and JSON live in Dart classes that widgets call. Widget tests cover screens; unit tests cover math.
- **No extra state-management package.** `PlaySession` is a `ChangeNotifier`. That is enough for a hobby score sheet and works the same later on Android/iOS.
- **Local persistence only.** `shared_preferences` maps to `localStorage` on web and to platform storage on mobile, so the same repository works when you add Android/iOS later.
- **Web now, mobile later.** The project was created with `--platforms=web`. Adding Android/iOS later is `flutter create --platforms=android,ios .` without changing the game architecture.
- **Free hosting.** GitHub Actions builds `build/web` with `--base-href /<repo>/` so assets load under `https://<user>.github.io/<repo>/`.

```
lib/
  main.dart
  app/                         # MaterialApp, theme
  domain/                      # BoardGame contract, models, registry
  data/                        # Session repository
  shared/                      # Players, buttons, dialogs, layout
  features/
    home/                      # Game list
    setup/                     # Players + game config
    play/                      # Shared play chrome around a game sheet
  games/
    great_western_trail/       # Great Western Trail First Edition
```

## Shared components

Use these instead of inventing new chrome for each game:

| Component | Use it for |
| --- | --- |
| `PlayerEditor` | Adding, removing, and naming players |
| `ScoreBoard` | Current totals / leader highlight |
| `ScoreHistoryList` | Round or event history |
| `ScoreStepper` | Point input on mobile and desktop |
| `PrimaryButton` | Main actions |
| `showConfirmDialog` | Reset, finish, delete |
| `AppPage` | Responsive page shell with a max width |
| `GameIconBadge` | Game identity on the home screen |

The play screen already hosts reset, finish, player editing, persistence, and the score header. A game sheet should only render **that game’s** inputs and history.

## Add a new board game

1. Create `lib/games/my_game/`.
2. Add:
   - `my_game_config.dart` — options such as a target score
   - `my_game_state.dart` — players, status, history, `toJson` / `fromJson`
   - `my_game_scoring.dart` — totals, winners, end conditions (no Flutter imports)
   - `my_game_setup.dart` — config editor (optional)
   - `my_game_sheet.dart` — the score sheet widget
   - `my_game_game.dart` — a `BoardGame` subclass that wires the pieces together
3. Register it in `lib/domain/game_registry.dart`:

```dart
GameRegistry({List<BoardGame>? games})
    : games = List.unmodifiable(
        games ?? const [GreatWesternTrailGame(), MyGame()],
      );
```

4. Prefer shared widgets for players, totals, history, and dialogs.
5. Add unit tests for scoring and JSON round-trips.

Do not put game-specific `if (game.id == ...)` checks in `HomeScreen`, `SetupScreen`, or `PlayScreen`. If the shared screens need a new hook, add a method to `BoardGame` instead.

Player count, colors, and scoring stay on the game class. Great Western Trail is 2–4 players with Red, Blue, Yellow, and White.

### Great Western Trail (First Edition)

The score pad follows the official 1st-edition notepad (11 scoring rows plus total):

| Pad row | What to enter | Rule |
| --- | --- | --- |
| Coins | Dollars on hand | 5 dollars = 1 VP; leftover dollars do not score |
| Buildings | VP | Private building tiles on the trail |
| Deliveries | VP (can be negative) | City crests; each Kansas City disc is −6 |
| Stations | VP | Printed next to stations with your disc |
| Hazards | VP | Collected hazard tiles |
| Cattle | VP | VP cattle in draw stack, hand, and discard |
| Objectives | VP (can be negative) | Fulfilled cards score positive; unmet cards subtract |
| Station masters | VP | Station master tile tasks |
| Player board | VP | 4 VP per worker on the 5th or 6th space of a worker row |
| 3-VP disc | 0 or 3 | Official pad: 3 VP if you cleared that disc space. Leave empty if unused |
| End-game token | 0 or 2 | The player who takes the job market token when the game ends scores 2 VP |

Only one player can hold the end-game token. Highest total wins; ties are shared.

## Tests

```bash
flutter test
```

That runs:

- Great Western Trail scoring tests
- Persistence tests (local storage)
- Widget tests for the home → setup → play path, including resume after a restart of the widget tree

## Deploy to GitHub Pages

The workflow in `.github/workflows/ci.yml`:

1. Installs Flutter dependencies
2. Runs `flutter analyze --fatal-infos`
3. Runs `flutter test`
4. On push to `main`, builds `flutter build web --release --base-href /<repository-name>/`
5. Uploads `build/web` and deploys with official GitHub Pages actions

One-time GitHub settings (required before the first deploy works):

1. Open the repo on GitHub → **Settings → Pages**.
2. Under **Build and deployment → Source**, choose **GitHub Actions** (not “Deploy from a branch”).
3. Re-run the failed **CI** workflow, or push to `main` again.

If deploy fails with `Get Pages site failed` / `HttpError: Not Found`, Pages is still off or still set to a branch. The Actions token cannot turn Pages on for you. After you switch the source, look at the **Actions** run: the `github-pages` environment may wait for you to click **Review deployments**.

The public URL will be:

```text
https://<username>.github.io/<repository-name>/
```

`--base-href` uses the repository name, so renaming the repo means the next deploy picks up the new path. GitHub Pages URLs are case-sensitive.

The site is static files only. No paid GitHub feature is required for public repositories.

## Adding Android or iOS later

```bash
flutter create --platforms=android,ios .
```

Keep using `GameSessionRepository` and the `BoardGame` contract. Do not add a second scoring model for mobile.
