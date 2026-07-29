# Mon Peya — Mobile

Super-app Flutter pour l'écosystème **N'TERI** en Côte d'Ivoire.

## Structure

```
mobile/
├── app/                    # Shell principal (auth, navigation, abonnements)
├── packages/
│   ├── peyapay/            # Wallet & paiements
│   ├── billetterie/        # Billetterie électronique
│   ├── immo/               # Immobilier (Mr Immo)
│   └── leadway/            # Assurance Leadway
└── melos.yaml              # Gestion du monorepo Flutter
```

## Prérequis

- Flutter SDK ≥ 3.10 (Dart ^3.10.8)
- Android Studio / Xcode pour les builds natifs

## Installation

```bash
cd mobile/app
cp .env.example .env
flutter pub get
flutter run
```

## Configuration (`.env`)

| Variable | Description | Défaut |
|----------|-------------|--------|
| `MONPEYA_API_URL` | Backend auth/abonnements | `http://10.0.2.2:8082/api/platform` |
| `BILLETTERIE_API_URL` | Backend ticketing | `http://10.0.2.2:8082/api/billetterie` |
| `IMMO_API_URL` | Backend Mr Immo | `http://10.0.2.2:8082/api/immo` |
| `PEYAPAY_API_URL` | API Peya wallet | test1 |
| `ENCRYPT_KEY` / `QR_ENCRYPT_KEY` | Crypto QR (parité backend) | — |

Sur émulateur Android, `10.0.2.2` pointe vers la machine hôte. Sur iOS simulator, utiliser `localhost`.

## Monorepo (Melos)

```bash
dart pub global activate melos
cd mobile
melos bootstrap
```

## Documentation

- [app/README.md](app/README.md) — guide complet de la super-app
