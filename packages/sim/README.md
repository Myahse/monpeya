# SIM Assurances module

Flutter package for SIM Assurances Partner API v1 inside Mon Peya.

## Flow (Option B)

1. `POST /devis` — quote
2. `POST /souscriptions` — pending subscription + KYC
3. PeyaPay wallet payment via `SimHostBridge.requestPayment`
4. `POST .../confirmer-paiement` — declare collection to SIM

## Config

Set `SIM_API_KEY` (and optionally `SIM_API_URL`, `SIM_WEBHOOK_SECRET`) in
`app/config/env.json`, then build with
`flutter run --dart-define-from-file=config/env.json`.
`AppConfig` reads them and `MonPeyaEnv.load()` applies them at startup.

Never commit the key. A key compiled into the app can be extracted from the
binary — production calls should go through the Mon Peya backend.

## Docs

See `docs/sim-assurances/` in the monorepo root.
