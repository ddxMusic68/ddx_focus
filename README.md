## Description

**ddx_focus** is a pomodoro timer and habit app built with Flutter. It's inspired by *Atomic Habits* — the idea is to chain small habits together so you get more done and reclaim time for the things you want to do.

Each focus/rest cycle is recorded, tagged, rated and reviewed, giving you a clear picture of how you spend your time.

## Features

- **Pomodoro timer** — run a focus + rest cycle with either the default timer or a custom timer you define on the home screen.
- **Custom timers** — create, edit and delete timer configurations with your own focus and rest lengths.
- **Tags** — tag a session with one or more labels so you can group and filter your work later.
- **Session review** — after a cycle, rate your focus (1–5), note what you accomplished, and reflect on why you rated it that way.
- **History** — browse past sessions, and add, edit or delete sessions directly from the list.
- **Stats** — see a pie chart of focus vs. rest time (or time per tag) over the last week, month, or year, plus total focus time.
- **Settings** — switch between system/light/dark themes.
- **Import / export** — back up all sessions, timers and tags to a JSON file of your choosing, or restore them from one.
- **Clear local data** — wipe all locally stored data with a confirmation prompt.
- **About** — learn a little about the app and visit related links.
- **Safe local storage** — on Windows, data lives in a `storage` folder next to the executable to avoid anti-virus/Defender flagging writes to your Documents directory.

## Dropbox Sync Setup

Dropbox sync requires your own Dropbox app credentials. No API keys are baked into the app.

1. Go to [Dropbox App Console](https://www.dropbox.com/developers/apps).
2. Click **Create app** and choose **Scoped access** → **Full Dropbox** (or App folder).
3. Under the **Permissions** tab, enable `files.content.write` and `files.content.read`, then click **Submit**.
4. Copy the **App key** from the app's overview page.
5. In ddx_focus, open **Settings** → **Dropbox Sync** → **Connect**.
6. Enter your App key, then authorize the app in your browser and paste the authorization code back into the app.

Once connected, use **Sync Now** in settings to sync manually. Auto-sync runs on app startup when enabled.

## Architecture

The app follows a simple layered structure: UI screens, providers (state + persistence), and models.

```
lib/
  main.dart                    # App entry point, theming, shell navigation
  models/                      # Immutable data models (session, timer)
    session_model.dart
    timer_model.dart
  providers/                   # ChangeNotifier state + JSON persistence
    sessions_provider.dart     # Sessions (history + stats data)
    timer_provider.dart        # Custom timer configs
    tags_provider.dart         # Tag names
    settings_provider.dart     # Theme preference
  screens/                     # UI
    home_screen.dart           # Timer list + entry
    timer_page.dart            # The running focus/rest timer
    session_review_screen.dart # Post-cycle review form
    history_screen.dart        # Session list (view/add/edit/delete)
    session_edit_screen.dart   # Add/edit a session
    stats_screen.dart          # Pie-chart stats
    settings_screen.dart       # Settings hub
    data_screen.dart           # Import / export
    about_screen.dart          # App info + links
    wip_screen.dart            # Placeholder for not-yet-built features
  widgets/                     # Reusable widgets
    timer_card.dart
    add_timer_sheet.dart
  services/                    # Pure logic
    data_export_import.dart    # Import/export JSON serialization
  utils/
    constants.dart             # App colors
    storage_path.dart          # Resolves the storage directory
```

State is held by `ChangeNotifier` providers exposed through `Provider`/`Provider.of`, and each provider persists its data to a local JSON file.

## Dependencies

| Package | Purpose |
|---|---|
| `provider` | State management (ChangeNotifier wiring) |
| `path_provider` | Resolving platform storage directories (non-Windows) |
| `file_picker` | Choosing export directories / import files |
| `url_launcher` | Opening external links from the About screen |
| `package_info_plus` | Reading the app version for the Settings screen |
| `fl_chart` | Rendering the Stats pie charts |

## Development

```bash
flutter pub get       # Install dependencies
flutter run            # Run the app
flutter analyze        # Lint check (uses flutter_lints)
```

Tests live in the `test/` directory and run with `flutter test`.

## Platform Support

| Platform | Status |
|---|---|
| Android | Supported |
| iOS | Unknown |
| Web | Unsupported |
| Linux | Unknown |
| macOS | Unknown |
| Windows | Supported |

## Contributing

1. Fork the repository.
2. Create a feature branch.
3. Run `flutter analyze` before committing.
4. Open a pull request with a description of your changes.

## Todo

## Changelog
### Version 1.0.2


### Version 1.0.1
- [X] make app work minimized (use datetime instead of timer)


### Version 1.0.0
created base app with home, satistics, history page

- [X] change name to ddxFocus instead of ddx_focus
- [X] finish readme
- [X] move windows storage dir to a exe
- [X] create about me page
- [X] add import/export
- [X] add clear local data
- [X] create icon
- [X] add custom alarm