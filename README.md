# Mon Peya

Monorepo **mobile + backend unifié**. Le mobile communique avec **un seul host** (`:8082`) via des chemins par module.

```
Mon Peya/
├── mobile/                     # Super-app Flutter + packages métier
│   ├── app/                    # Shell (auth globale, navigation)
│   └── packages/               # peyapay, billetterie, immo, leadway
└── backend/                    # Backend unifié (port 8082)
    ├── modules/
    │   ├── platform/           # Auth, abonnements → /api/platform
    │   ├── billetterie/        # Tickets, événements → /api/billetterie
    │   ├── immo/               # Mr Immo → /api/immo
    │   ├── shared-kernel/      # Auth session partagée
    │   └── server/             # Point d'entrée JVM unifié
    └── compose.yaml            # Stack complète
```

## Démarrage rapide

### Backend (tout-en-un)

```bash
cd backend
cp .env.example .env
docker compose up -d
```

- Gateway : http://localhost:8082

### Mobile

```bash
cd mobile/app
cp .env.example .env
flutter pub get
flutter run
```

## URLs mobile (`.env`)

```env
MONPEYA_API_URL=http://10.0.2.2:8082/api/platform
BILLETTERIE_API_URL=http://10.0.2.2:8082/api/billetterie
IMMO_API_URL=http://10.0.2.2:8082/api/immo
```

Documentation : [backend/README.md](backend/README.md) · [mobile/README.md](mobile/README.md)

## License

Propriétaire — Djogana.
