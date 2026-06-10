# Mon Peya Super App

A Flutter super-app for the **N'TERI** ecosystem in Côte d'Ivoire. Mon Peya unifies wallet and payments (**PeyaPay**), third-party service modules (Billetterie, Mr Immo), subscriptions, and user onboarding in a single mobile shell.

| | |
|---|---|
| **Package** | `mon_peya_super_app` |
| **Version** | 1.0.0+1 |
| **SDK** | Dart `^3.10.8` |
| **UI language** | French |

---

## Table of contents

- [Overview](#overview)
- [Features](#features)
- [Screenshots](#screenshots)
- [Architecture](#architecture)
- [Getting started](#getting-started)
- [Demo credentials](#demo-credentials)
- [User flows](#user-flows)
- [Project structure](#project-structure)
- [Tech stack](#tech-stack)
- [Platform support & permissions](#platform-support--permissions)
- [Development notes](#development-notes)
- [Roadmap](#roadmap)

---

## Overview

Mon Peya is a **super-app shell** that hosts multiple services behind one account and navigation experience. Users can:

- Browse a personalized home dashboard with news and service shortcuts
- Manage a digital wallet, send money, pay bills, and link funding sources via **PeyaPay**
- Open integrated service modules (ticketing, real estate, and more) through the **N'TERI** menu
- Register with phone + OTP, complete identity verification, and secure the app with a PIN

The project is a **Flutter port** of an existing React Native app. PeyaPay and the home experience are largely implemented; several service modules and backend integrations still use mock data and placeholder screens.

---

## Features

### Core shell

| Feature | Description |
|---------|-------------|
| **Splash** | Branded logo animation, then routes to onboarding |
| **Onboarding** | 4-slide carousel introducing the super-app (French copy) |
| **Main tabs** | Bottom navigation: **HOME**, **PEYAPAY**, **MY SUBS** |
| **App stack** | Nested navigation for opening service modules without losing tab context |
| **N'TERI menu** | Overlay grid to jump between dashboard, services, and settings |

### Authentication & account

| Feature | Description |
|---------|-------------|
| **Phone input** | Country picker (+225 default), 10-digit validation, OTP sheet (mock) |
| **Registration** | 3-step flow: ID photo, identity form, 4-digit PIN |
| **Login PIN** | Shuffled keypad PIN entry |
| **Settings** | Profile info, biometrics toggle (UI only), logout |
| **Reset PIN** | Placeholder screen |

### Home

| Feature | Description |
|---------|-------------|
| **Dashboard** | Balance card, news carousel, services grid |
| **Mon Peya space** | Personal services hub (registration required) |
| **Mr Immo** | Expandable folder: Rental, Construction, Collection |
| **Billetterie** | Ticketing module entry point |
| **Deposit shortcut** | Quick path to PeyaPay add-money flow |

### PeyaPay (wallet & payments)

| Feature | Description |
|---------|-------------|
| **Dashboard** | Balance, quick actions, news, recent transactions |
| **Transfer** | Contact picker → amount → review → confirm |
| **Bill payments** | CIE / SODECI utilities, assurance overlay |
| **Source of funds** | Link CI banks and debit cards (15 banks, 3 card brands) |
| **Add money** | Top-up after linking a funding source |
| **Transactions** | Full payment history |
| **Payment review / success** | Confirmation screens for completed payments |

### Services & subscriptions

| Feature | Description |
|---------|-------------|
| **My Subs** | Subscription list and generic module launcher |
| **Billetterie** | Electronic ticketing module (`billetterie_electronique` package) — events, cars, Peya Pay checkout |
| **Mr Immo** | Rental, Construction, Collection (`mr_immo` package) — rental UI ported from React Native |
| **ServiceModule** | Generic loader by `moduleId` + `bundleUrl` (WebView / asset bundle) |

Embedded modules run as overlays on the app stack. Mon Peya provides auth and payments through **host bridges**; the packages do not import the shell directly.

---

## Screenshots

> Add screenshots here once available.

```
assets/screenshots/
├── splash.png
├── home.png
├── peyapay.png
└── transfer.png
```

---

## Architecture

### Workspace layout

Mon Peya is the **host shell**. Mr Immo and Billetterie live in this same repository under `packages/`:

```
mon_peya_super_app/           # GitLab repo root (Mon Peya shell)
├── packages/
│   ├── mr_immo/              # Rental, Construction, Collection
│   └── billetterie_electronique/  # Ticketing (events + cars)
├── lib/
├── assets/
└── pubspec.yaml
```

Each module has its own `pubspec.yaml` and no `main.dart` — they run only inside Mon Peya via path dependencies.

### Module integration

At startup the shell registers host adapters (`lib/app/app.dart`):

| Package | Bridge | Mon Peya provides |
|---------|--------|-------------------|
| `mr_immo` | `ImmoHostBridge` | Phone/PIN auth, JWT sync, exit to home |
| `billetterie_electronique` | `BilletterieHostBridge` | Peya Pay review/payment flow, exit to home |

Modules are opened from **Mes services** or the home grid. `AppStackScreen` pushes them onto an internal stack (overlay on home tabs). Use `AppStackScope.goBack()` / bridge `exitModule()` — not `Navigator.pop()` at the root — to return to Mon Peya home.

```
MonPeyaSuperApp
└── AppStackScreen
    ├── AppStackController — module stack + N'TERI menu
    ├── MainTabsShell (HOME | PEYAPAY | MY SUBS)
    └── Module overlay (cached)
        ├── BilletterieModuleScreen   ← billetterie_electronique
        ├── MrImmoRentalScreen        ← mr_immo
        ├── MrImmoConstructionScreen
        └── MrImmoCollectionScreen
```

### Navigation layers

```
MaterialApp (named routes)
└── AppStackScreen
    ├── AppStackController (ValueNotifier) — service module stack + N'TERI menu
    └── MainTabsShell
        ├── HOME tab navigator
        ├── PEYAPAY tab navigator
        └── MY SUBS tab navigator
```

**Root routes** (`lib/app/routing/routes.dart`):

| Route | Path |
|-------|------|
| Splash | `/splash` |
| Onboarding | `/onboarding` |
| Phone input | `/phone` |
| Registration | `/registration-flow` |
| Login PIN | `/login-pin` |
| Settings | `/settings` |
| Reset PIN | `/reset-pin` |
| App stack | `/app` |

PeyaPay and service screens are pushed inside tab navigators or the app stack — they are not top-level named routes.

### State management

No Riverpod, Bloc, or Provider. The app uses:

| Pattern | Usage |
|---------|-------|
| `StatefulWidget` + `setState` | Most feature screens |
| `ValueNotifier` | `AppStackController` for module stack and menu visibility |
| `InheritedWidget` | `AppStackScope` exposes the controller to descendants |
| `SharedPreferences` | Session persistence via `AuthStore` |

### Theme

- Material 3 with brand seed color `#006D56`
- Light and dark themes, `ThemeMode.system`
- Global text scale: `0.90` via `MediaQuery`

---

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) compatible with Dart `^3.10.8`
- Android Studio / Xcode (for mobile targets)
- A device or emulator

Verify your setup:

```bash
flutter doctor
```

### Install & run

```bash
cd mon_peya_super_app
flutter pub get
flutter run
```

Optional API endpoints (Mr Immo / Billetterie backends):

```powershell
flutter run `
  --dart-define=IMMO_API_URL=http://YOUR_IP:8081 `
  --dart-define=BILLETTERIE_API_URL=http://YOUR_IP:8089/api/billetterie-electronique
```

Run on a specific device:

```bash
flutter devices
flutter run -d <device_id>
```

### Run tests

```bash
flutter test
```

### Build release

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Windows
flutter build windows --release
```

---

## Demo credentials

A built-in demo account is available for testing login without completing registration:

| Field | Value |
|-------|-------|
| Phone (local) | `0777146737` |
| Phone (full) | `+2250777146737` |
| PIN | `1234` |

To force guest mode during debug builds, set `AuthStore.forceGuestInDebug = true` in `lib/app/storage/auth_store.dart`.

---

## User flows

### Cold start

```
Splash → Onboarding (4 slides) → Main app (guest mode)
```

### Guest → registered user

```
Phone input → OTP (mock) → Registration (ID + identity + PIN)
                         or Login PIN (if account exists)
```

### PeyaPay transfer

```
PeyaPay tab → Transfer → Pick contact → Enter amount → Review → Confirm
```

### Bill payment (CIE / SODECI)

```
PeyaPay → Payments & services → Select provider → Reference lookup (mock)
        → Amount & method → Review → Success
```

### Top-up wallet

```
PeyaPay → Banks & insurance → Link bank or card → Add money → Review
```

### Open a service module

```
Home grid or Mes services → App stack pushes module overlay
                          → MonPeyaModuleGate (registration check)
                          → mr_immo / billetterie_electronique UI
Exit module → host bridge → AppStackScope.goBack() → Mon Peya home
```

### Billetterie payment

```
Billetterie → checkout → BilletterieHostBridge.requestPayment()
           → PeyaPay review screen → confirm → back to Billetterie
```

---

## Project structure

```
mon_peya_super_app/
├── packages/
│   ├── mr_immo/                 # Mr Immo module (rental, construction, collection)
│   └── billetterie_electronique/ # Billetterie module
├── android/                     # Android build (READ_CONTACTS)
├── ios/                         # iOS build (contacts usage description)
├── windows/                     # Windows desktop
├── linux/                       # Linux desktop
├── macos/                       # macOS desktop
├── assets/
│   ├── images/                  # Onboarding photos, SVGs
│   ├── logo/
│   │   ├── banks/               # CI bank logos
│   │   └── cards/               # Card brand assets
│   └── modules/                 # Bundled module assets (WebView)
├── lib/
│   ├── main.dart                # App entry point
│   ├── app/
│   │   ├── app.dart             # MaterialApp, theme, host adapter registration
│   │   ├── routing/routes.dart  # Named routes
│   │   ├── storage/             # AuthStore, PrefsKeys
│   │   ├── modules/             # Bundled module catalog
│   │   └── widgets/             # Shared UI (PIN keypad, scaffolds)
│   ├── modules/
│   │   ├── adapters/            # Immo + Billetterie host bridges
│   │   ├── immo_module_registry.dart
│   │   └── billetterie_module_registry.dart
│   ├── widgets/
│   │   └── mon_peya_module_gate.dart
│   └── screens/
│       ├── splash/
│       ├── onboarding/
│       ├── auth/                # Phone, registration, login PIN
│       ├── settings/
│       ├── reset_pin/
│       └── app_stack/           # Shell, tabs, PeyaPay, services
├── test/
├── pubspec.yaml
└── analysis_options.yaml
```

### Key directories

| Path | Purpose |
|------|---------|
| `lib/screens/app_stack/tabs/peyapay/` | Wallet module (screens, widgets, models) |
| `lib/screens/app_stack/services/` | Re-exports Billetterie + Mr Immo entry screens |
| `lib/modules/adapters/` | Wires AuthStore / Peya Pay into module host bridges |
| `lib/app/storage/` | Local session and auth persistence |
| `assets/logo/banks/` | Bank logos for source-of-funds linking |

### Path dependencies (`pubspec.yaml`)

```yaml
dependencies:
  mr_immo:
    path: packages/mr_immo
  billetterie_electronique:
    path: packages/billetterie_electronique
```

---

## Tech stack

| Category | Choice |
|----------|--------|
| Framework | Flutter |
| Language | Dart `^3.10.8` |
| UI | Material 3 |
| Persistence | `shared_preferences` |
| HTTP | `http` (Mr Immo API client) |
| WebView | `webview_flutter` (+ platform implementations) |
| SVG assets | `flutter_svg` |
| Contacts | `flutter_contacts` |
| ID photo capture | `image_picker` |
| Embedded modules | `mr_immo`, `billetterie_electronique` (path packages) |
| Linting | `flutter_lints` |

**Not yet integrated:** Firebase, Supabase, go_router, Riverpod/Bloc, centralized `.env` config.

---

## Platform support & permissions

### Supported platforms

| Platform | Status |
|----------|--------|
| Android | Primary mobile target |
| iOS | Supported |
| Windows | Supported (build artifacts present) |
| Linux | Scaffolded |
| macOS | Scaffolded |
| Web | Not scaffolded |

### Permissions

| Permission | Platform | Used by |
|------------|----------|---------|
| `READ_CONTACTS` | Android | Transfer contact picker |
| `NSContactsUsageDescription` | iOS | Transfer contact picker |
| Camera / photo library | Registration (`image_picker`) | May require additional iOS plist keys for production |

---

## Development notes

### Mock data

Backend APIs are not wired yet. The following use hardcoded or static data:

- OTP verification
- Wallet balance and transactions
- Bill reference lookup (CIE / SODECI)
- Bank and card linking

Look for `TODO` comments in PeyaPay screens when integrating real APIs.

### Legacy code in `main.dart`

`lib/main.dart` contains a large commented-out block (~1000 lines) from an earlier monolithic version. The active entry point is:

```dart
void main() => runApp(const MonPeyaSuperApp());
```

### Service module loader

`ServiceModuleScreen` accepts `moduleId` and `bundleUrl` parameters. A future webview or native runtime loader will fetch and render external module bundles.

### Shared preferences keys

| Key | Purpose |
|-----|---------|
| `seenOnboarding` | User completed onboarding carousel |
| `isRegistered` | User has a registered account |
| `phoneNumber` | Stored phone number |
| `biometricEnabled` | Biometrics preference (UI only) |
| `pin:<phone>` | PIN hash per phone number |

---

## Roadmap

- [x] Embed Mr Immo and Billetterie as path packages with host bridges
- [x] Monorepo — `packages/mr_immo` and `packages/billetterie_electronique` in same GitLab repo
- [ ] Backend API integration (auth, wallet, payments, bills)
- [ ] Service module bundle loader (webview / native runtime)
- [ ] Reset PIN flow
- [ ] Prepaid card feature
- [ ] Native biometrics integration
- [ ] iOS camera / photo library permission strings
- [ ] Web target
- [ ] Remove legacy commented code in `main.dart`

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit your changes
4. Push and open a pull request

Follow existing conventions: Material 3 styling, French UI copy, feature-based folder layout under `lib/screens/`.

---

## License

This project is not published to pub.dev (`publish_to: 'none'`). Add a license file if you plan to open-source or distribute the app.
