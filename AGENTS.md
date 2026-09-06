# AGENTS.md — cotorra_app

Flutter/Dart mobile app for **Cotorra**, a student academic-resource sharing platform. It is a thin client over a FastAPI backend (PostgreSQL + JWT), talking REST only.

## Setup

- Requires **Flutter SDK + Dart SDK** (pubspec pins `sdk: ^3.11.4`). Verify the toolchain with `flutter doctor`.
- `flutter pub get`
- **Create `.env` before building or running.** `lib/main.dart` does `await dotenv.load(fileName: '.env')` (not optional) and `.env` is also listed as a pubspec asset, so a missing file crashes at startup and breaks `flutter run` / `flutter build`. Copy from `.env.example`. `.env` is gitignored — never commit real secrets.

## Commands

- Static analysis: `flutter analyze`
- Format: `dart format .`
- Run on a device: `flutter run` (list targets with `flutter devices`)
- Build APK: `flutter build apk`
- Tests: `flutter test` (runs the **entire** suite, including the network integration tests below — see split)

## Architecture

- **Entrypoint** `lib/main.dart`: wires a `MultiProvider` (the `provider` package) with 6 providers, then routes to `AuthScreen` or `MainScreen` based on auth status. Navigation is plain `MaterialPageRoute` — there is **no router package** (go_router/auto_route).
- **API client** `lib/services/api_service.dart` (`ApiService`) uses the **`http`** package. `dio` is used *only* in `image_cache_service.dart` and `pdf_cache_service.dart` — do not assume a single HTTP client across the codebase.
- **Models** are hand-written Dart classes in `lib/models/*.dart`, re-exported from `lib/models/models.dart`, with manual `fromJson`/`toJson`.
- **`openapi.json` is a reference contract only — there is NO codegen.** No `build_runner`, `json_serializable`, OpenAPI generator, or retrofit in dependencies. When the backend changes, update `ApiService` and the model classes **by hand** to match `openapi.json`; nothing regenerates them.
- **Theming**: light/dark via `ThemeMode.system` in `lib/themes/theme.dart`. Env access goes through `lib/config/env.dart` (the `Env` class, which has safe default fallbacks).

## Tests — the split matters

- `test/services/api_service_test.dart` — **unit tests**, `mocktail` + `MockHttpClient`. No backend needed. Run in isolation: `flutter test test/services/api_service_test.dart`
- `test/services/api_service_integration_test.dart` — **integration tests that hit the real dev API** (default `apicotorra.deqa.com.ar` via `Env.baseUrl`). They need a running backend and a seeded test user (`TEST_USER_EMAIL` / `TEST_USER_PASSWORD` from `.env`, defaults `admin@gmail.com` / `123456`), and they perform **real writes** (create/update/delete documents). Bare `flutter test` executes these against the network and will fail without the backend.
- `test/widget_test.dart` — default Flutter smoke test.

## Notes

- `.atl/` and `openspec/` are agent/SDD tooling state, not application source — don't touch them as part of feature work.
