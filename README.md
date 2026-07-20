# Mon Peya

N'TERI super-app monorepo — Flutter clean architecture.

## Structure

```
Mon Peya/
├── app/                        # Shell application (auth, navigation, module launcher)
├── packages/
│   ├── peyapay/                # Wallet & payments
│   ├── immo/                   # Rental, construction, collection
│   ├── billetterie/            # Electronic ticketing
│   └── leadway/                # Leadway Assurance
├── melos.yaml
└── README.md
```

Each package follows clean architecture with typed file names:

```
lib/
├── <package_name>.dart         # Public API
└── src/
    ├── screens/                # *.screen.dart
    ├── types/                  # *.types.dart
    ├── services/               # *.service.dart
    ├── models/                 # *.model.dart
    ├── widgets/                # *.widget.dart
    ├── controllers/            # *.controller.dart
    └── ...
```

Examples: `home.screen.dart`, `app_stack.types.dart`, `auth.store.dart`, `rental_api.service.dart`

## Prerequisites

- Flutter SDK (Dart `^3.10.8`)
- Optional: [Melos](https://melos.invertase.dev/) for workspace management

## Run

```bash
cd app
flutter pub get
flutter run
```

Or with Melos:

```bash
dart pub global activate melos
melos bootstrap
cd app && flutter run
```

Optional API URLs:

```bash
flutter run \
  --dart-define=IMMO_API_URL=http://YOUR_IP:8081 \
  --dart-define=BILLETTERIE_API_URL=http://YOUR_IP:8090
```

See [app/README.md](app/README.md) for full documentation.
