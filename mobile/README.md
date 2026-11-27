# Nirmal Mart — Android app (Flutter)

Customer shopping app for nirmalmart.in. It talks to the same backend as the website, so products,
orders, accounts and the admin panel are shared.

- App ID: `in.nirmalmart.app` (permanent — never change after the first Play upload)
- Design: `../nirmal-mart-app-design/` (tokens mapped in `lib/core/theme/`)
- API: `https://www.nirmalmart.in/api` by default

## Run

```bash
flutter pub get
flutter run                                                     # against the live API
flutter run --dart-define=API_URL=http://10.0.2.2:8010/api      # against a local backend (emulator)
flutter analyze && flutter test
```

Android builds need about 10 GB free disk space (Gradle caches).

## Layout

```
lib/
  main.dart                 app root: theme, English/Marathi, router
  router.dart               routes; four tabs (Home, Shop, Wishlist, Account) with their own stacks
  core/config.dart          API URL and store rules
  core/api/                 Dio client (token refresh, CDN-friendly catalogue reads), secure token storage
  core/theme/               design tokens and Material 3 light/dark themes
  l10n/app_en.arb, app_mr.arb   strings (code generated on build)
  shared/                   widgets used across screens
  features/<name>/          one folder per feature, added as screens are built
assets/fonts                Inter + Noto Sans Devanagari (OFL)
assets/images               logos, icon and splash sources
```

## Regenerate icons / splash

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Not in git (add locally)

- `android/key.properties` + the upload keystore (`.jks`) — release signing. **Back both up**; losing them
  means the Play Store app can never be updated.
- `android/app/google-services.json` — Firebase (push notifications).
