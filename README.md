# Mon Peya — Mobile

Super-app Flutter pour l'écosystème **N'TERI** en Côte d'Ivoire.

## Structure

```
.
├── app/                    # Shell principal (auth, navigation, abonnements)
├── apps/                   # Applications pro Mr Immo Construction (une par rôle)
│   ├── immo_chantier/      # Chef de chantier
│   ├── immo_superviseur/   # Superviseur — validation des demandes
│   ├── immo_achats/        # Moyens généraux — commandes fournisseurs
│   └── immo_fournisseur/   # Fournisseur — livraisons
├── packages/
│   ├── peyapay/            # Wallet & paiements
│   ├── billetterie/        # Billetterie électronique
│   ├── immo/               # Immobilier (Mr Immo)
│   ├── leadway/            # Assurance Leadway
│   ├── sim/                # SIM Assurances
│   ├── grenier/            # Mon Grenier (prix produits)
│   └── mocks/              # Données / auth simulées (dev, QA)
└── melos.yaml              # Gestion du monorepo Flutter
```

## Prérequis

- Flutter SDK ≥ 3.10 (Dart ^3.10.8)
- Android Studio / Xcode pour les builds natifs

## Installation

```bash
cd app
cp config/env.example.json config/env.json   # puis renseigner les clés
flutter pub get
flutter run --dart-define-from-file=config/env.json
```

## Configuration (`app/config/env.json`)

Toute la configuration passe par `--dart-define` (lue dans
`app/lib/src/core/config/app_config.dart`). `config/env.json` est ignoré par
git — **ne jamais committer de clé**. Voir `config/env.example.json` pour la
liste complète.

| Variable | Description | Défaut |
|----------|-------------|--------|
| `MONPEYA_API_URL` | Backend auth/abonnements | `http://10.0.2.2:8081` |
| `IMMO_API_URL` / `IMMO_WS_URL` | Backend Mr Immo | `http://10.0.2.2:8082` |
| `BILLETTERIE_API_URL` / `BILLETTERIE_WS_URL` | Backend ticketing | `http://10.0.2.2:8090` |
| `GRENIER_API_URL` / `GRENIER_WS_URL` | Backend Mon Grenier | `http://10.0.2.2:8083` |
| `PEYAPAY_API_URL` | API Peya wallet | test1 |
| `PEYAPAY_APP_USERNAME` / `PEYAPAY_APP_PASSWORD` | Identifiants applicatifs PeyaPay | — |
| `ENCRYPT_KEY` / `QR_ENCRYPT_KEY` | Crypto QR (parité backend) | — |
| `SIM_API_KEY` | Clé partenaire SIM Assurances | — |
| `MAPBOX_ACCESS_TOKEN` | Tuiles / itinéraires cartes | — |

Sur émulateur Android, `10.0.2.2` pointe vers la machine hôte. Sur téléphone
physique, `tool/sync_dev_lan_host.ps1` met à jour `env.json` avec l'IP LAN du PC.

## Applications pro Mr Immo Construction (`apps/`)

Chaque rôle du circuit des matériaux a sa propre application, avec sa propre connexion
comme Mon Peya (code client = numéro de téléphone du compte, puis code PIN à 4 chiffres) :
chef de chantier → superviseur → moyens généraux → fournisseur. Les écrans sont ceux de `packages/immo`
(`ConstructionRoleApp`) ; un compte d'un autre rôle est refusé à la connexion.

```bash
cd apps/immo_superviseur
flutter pub get
flutter run --dart-define=IMMO_API_URL=http://<IP du PC>:8082
```

Comptes de démo (backend lancé avec `SEED_DEMO_DATA=true`, code PIN `1234`) : codes client
`0700000202` (chef), `0700000203` (superviseur), `0700000204` (moyens généraux),
`0700000301` (fournisseur). Un compte se donne un code PIN avec `POST /api/auth/pin`
(email + mot de passe web + PIN) ; 5 PIN faux bloquent le compte 15 minutes.

## Monorepo (Melos)

```bash
dart pub global activate melos
melos bootstrap
```

## Documentation

- [app/README.md](app/README.md) — guide complet de la super-app
