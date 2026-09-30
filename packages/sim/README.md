# SIM Assurances module

Flutter package for SIM Assurances Partner API v1 inside Mon Peya.

## Flow (Option B)

1. `POST /devis` — quote
2. `POST /souscriptions` — pending subscription + KYC
3. PeyaPay wallet payment via `SimHostBridge.requestPayment`
4. `POST .../confirmer-paiement` — declare collection to SIM

## Config

Set at startup in `app/lib/src/core/config/app_config.dart`:

```dart
static const simApiKey = 'sk_live_...';
```

Loaded automatically via `MonPeyaEnv.load()` in `main.dart`.

Optional override at build time: `--dart-define=SIM_API_KEY=sk_live_...`

## Docs

See `docs/sim-assurances/` in the monorepo root.
