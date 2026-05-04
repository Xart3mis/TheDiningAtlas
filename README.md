# The Dining Atlas

A Flutter restaurant discovery app for exploring curated city guides, stories, and trip plans.

## What’s inside

- **Atlas**: browse curated restaurant picks and collections
- **For You**: personalized-style recommendations (sample data)
- **Stories**: short editorial/story cards
- **Trips**: plan a multi-stop food itinerary by day
- **Restaurant details**: ratings, tags, status, and quick actions

> Note: This repo currently uses local/sample data (see `lib/models/models.dart`) and is set up as a UI-first prototype.

## Requirements

- Flutter `>= 3.10.0`
- Dart `>= 3.0.0`

## Run locally

```bash
flutter pub get
flutter run
```

## Useful commands

```bash
flutter test
flutter analyze
dart format .
```

## Build

```bash
flutter build apk
flutter build ios
flutter build web
```

## Project structure

- `lib/main.dart` — app entry + bottom navigation shell
- `lib/screens/` — app screens (Atlas, Trips, Profile, etc.)
- `lib/models/models.dart` — models + sample content
- `lib/theme/app_theme.dart` — colors/typography/theme
- `lib/widgets/shared_widgets.dart` — shared UI components

## License

No license file is included yet. Add a `LICENSE` if you plan to distribute this publicly.
