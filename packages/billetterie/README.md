# Billetterie (Mon Peya package)

Independent Flutter module for electronic ticketing inside the Mon Peya super app.

## Apps

Like Mr Immo, Billetterie exposes **two native apps** in the Mon Peya grid:

| App | Screen | API client |
|-----|--------|------------|
| Billetterie Transport | `BilletterieTransportModuleScreen` | `BilletterieTransportApiService` |
| Billetterie Événements | `BilletterieEventModuleScreen` | `BilletterieEventApiService` |

## API

Two ticketing clients (same envelope: `POST /v1/*` + `{ "data": { ... } }`):

| Client | Purpose | Env |
|--------|---------|-----|
| `BilletterieTransportApiService` | Transport / conductor tickets | `BILLETTERIE_TRANSPORT_API_URL` → falls back to `BILLETTERIE_API_URL` |
| `BilletterieEventApiService` | Event tickets & public events | `BILLETTERIE_EVENT_API_URL` → falls back to `BILLETTERIE_API_URL` |

| Setting | Example |
|---------|---------|
| `BILLETTERIE_API_URL` | `http://10.0.2.2:8090` (Android emulator, shared host) |
| `BILLETTERIE_TRANSPORT_API_URL` | optional dedicated transport host |
| `BILLETTERIE_EVENT_API_URL` | optional dedicated event host |
| `BILLETTERIE_WS_URL` | optional WebSocket (`ws://host:8090/ws` by default) |
| `QR_ENCRYPT_KEY` | Same as PeyaPay (via `app/.env`) |

Realtime: the app connects to `BILLETTERIE_WS_URL` and silent-refreshes lists on JSON events such as `ticket.created`, `ticket.sold`, `event.published`, `dashboard.changed` (optionally wrapped in `{ "data": { ... } }`). If the socket is down, it retries quietly — no skeleton flash.

Docs: `http://localhost:8090/swagger-ui.html`

## Run

From `app/`:

```bash
flutter run
```

Override API URL:

```bash
flutter run --dart-define=BILLETTERIE_API_URL=http://HOST:8090
```

## Structure

Same layout as `packages/immo`:

```
lib/
  billetterie.dart
  src/
    core/           host bridge, brand, module keys
    shared/         config, HTTP client, shared models/widgets
    features/
      transport/    screens, widgets, models, services
      event/        screens, models, services
```

## Host bridge

Mon Peya registers `BilletterieHostBridge.resolveClient` (Peya `codeClient`) and optional PeyaPay payment for checkout.
