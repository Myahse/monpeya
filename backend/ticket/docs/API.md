# Ticketing API Reference

Base URL (local): `http://localhost:8090`

Interactive docs: [Swagger UI](http://localhost:8090/swagger-ui.html) · [OpenAPI JSON](http://localhost:8090/v3/api-docs)

---

## Conventions

| Rule | Detail |
|------|--------|
| HTTP method | All endpoints are **POST** |
| Content-Type | `application/json` |
| Request envelope | `{ "data": { ... } }` |
| Identity | Peya `codeClient` — no local user registration |
| Success flag | `hasError: false` |
| Single result | `item` |
| List result | `items` + `count` |
| Status | `status.code` + `status.message` |

### Standard response shape

```json
{
  "hasError": false,
  "status": { "code": "800", "message": "..." },
  "item": { },
  "items": [ ],
  "count": 1
}
```

### Error response shape

```json
{
  "hasError": true,
  "status": { "code": "925", "message": "data introuvable: ..." }
}
```

Common status codes: `900` (empty field), `905` (invalid data), `925` (not found), `926` (disallowed), payment errors on buy.

---

## Typical workflow

```
1. POST /v1/clients/get          → validate creator codeClient
2. POST /v1/events/create        → event DRAFT
3. POST /v1/tickets/generate       → tickets GENERATED
4. POST /v1/events/publish       → event PUBLISHED, tickets FOR_SALE
5. POST /v1/events/public         → buyers browse events
6. POST /v1/tickets/buy           → ticket SOLD + order PAID
7. POST /v1/tickets/verify        → check QR at gate (optional)
8. POST /v1/tickets/consume        → ticket CONSUMED
```

---

## Health

### `POST /v1/ping`

Health check (API + DB).

**Request** — body optional:

```json
{ "data": {} }
```

**Response** `item`:

| Field | Type | Description |
|-------|------|-------------|
| `pingId` | integer | Ping counter from DB |

---

## Clients

### `POST /v1/clients/get`

Resolve Peya client by `codeClient`.

**Request `data`:**

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `codeClient` | yes | string | Peya client code |

```json
{
  "data": {
    "codeClient": "YOUR_PEYA_CODE"
  }
}
```

**Response `item` (`WClientsDto`):**

| Field | Type | Description |
|-------|------|-------------|
| `codeClient` | string | Client code |
| `nomClient` | string | Display name |
| `gsmPrincipale` | string | Phone |
| `email` | string | Email |
| `login` | string | Login |
| `codeBanque` | string | Bank code |
| `accountId` | string | Account id |
| `numerocomptecomplet` | string | Full account number |
| `soldeDispo` | number | Available balance |

---

## Events

### `POST /v1/events/create`

Create event in **DRAFT** status.

**Request `data`:**

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `codeClient` | yes | string | Creator Peya code |
| `name` | yes | string | Event title |
| `category` | yes | string | e.g. `CONCERT`, `SPORT` |
| `startAt` | yes | datetime | ISO-8601 local, e.g. `2026-07-01T20:00:00` |
| `endAt` | yes | datetime | End datetime |
| `ticketPrice` | yes | number | Price per ticket |
| `maxTickets` | yes | integer | Capacity (> 0) |
| `venueName` | no | string | Venue |
| `address` | no | string | Street address |
| `city` | no | string | City |
| `country` | no | string | Country |
| `latitude` | no | number | GPS |
| `longitude` | no | number | GPS |

```json
{
  "data": {
    "codeClient": "YOUR_PEYA_CODE",
    "name": "Summer Fest",
    "category": "CONCERT",
    "venueName": "Palais de la Culture",
    "city": "Abidjan",
    "country": "CI",
    "startAt": "2026-07-01T20:00:00",
    "endAt": "2026-07-01T23:00:00",
    "ticketPrice": 5000,
    "maxTickets": 100
  }
}
```

**Response `item` (`EventDto`):** includes `eventCode` (e.g. `EVT-2026-A1B2C3D4`), `status`=`DRAFT`, counters at 0, `createdAt`.

---

### `POST /v1/events/publish`

Publish a **DRAFT** event (creator only).

**Request `data`:**

| Field | Required | Type |
|-------|----------|------|
| `eventCode` | yes | string |
| `codeClient` | yes | string |

```json
{
  "data": {
    "eventCode": "EVT-2026-A1B2C3D4",
    "codeClient": "YOUR_PEYA_CODE"
  }
}
```

**Response:** `item` with `status`=`PUBLISHED`, `publishedAt` set. Generated tickets move to **FOR_SALE**.

---

### `POST /v1/events/public`

List all **PUBLISHED** events (no filter).

**Request:** optional empty body or `{ "data": {} }`

**Response:** `items` array of `EventDto`, `count`.

---

### `POST /v1/events/get`

Get one event by **event code**.

**Request `data`:**

| Field | Required | Type |
|-------|----------|------|
| `eventCode` | yes | string |

```json
{ "data": { "eventCode": "EVT-2026-A1B2C3D4" } }
```

**Response:** `item` (`EventDto`).

---

## Tickets

Tickets are identified by **`ticketCode`** (e.g. `TKT-A1B2C3D4`). They support multiple **purposes** — not only events.

### Ticket purposes

| Purpose | Description |
|---------|-------------|
| `EVENT` | Linked to an event (`eventCode` required on generate) |
| `TRANSPORT` | Standalone e.g. conductor / bus pass |
| `PASS` | Generic pass |
| `GENERIC` | Other standalone tickets |

### `POST /v1/tickets/generate`

**Event tickets** — set `eventCode`:

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `eventCode` | yes* | string | Event code |
| `codeClient` | yes | string | Issuer / creator code |
| `quantity` | yes | integer | Count (> 0, ≤ remaining capacity) |
| `ticketType` | no | string | Default `STANDARD` |

```json
{
  "data": {
    "eventCode": "EVT-2026-A1B2C3D4",
    "codeClient": "YOUR_PEYA_CODE",
    "quantity": 10,
    "ticketType": "STANDARD"
  }
}
```

**Standalone tickets** (conductor, pass, etc.) — omit `eventCode`, set `purpose` + details:

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `purpose` | yes | string | `TRANSPORT`, `PASS`, or `GENERIC` |
| `codeClient` | yes | string | Issuer code |
| `quantity` | yes | integer | Count |
| `title` | yes | string | Display label (route name, pass type, …) |
| `validFrom` | yes | datetime | Validity start |
| `price` | yes | number | Ticket price |
| `place` | no | string | Location / route |
| `ticketType` | no | string | Defaults to purpose name |

```json
{
  "data": {
    "codeClient": "CONDUCTOR_CODE",
    "purpose": "TRANSPORT",
    "quantity": 5,
    "title": "Abidjan — Yamoussoukro",
    "place": "Gare routière",
    "validFrom": "2026-06-29T06:00:00",
    "price": 2500,
    "ticketType": "BUS"
  }
}
```

Standalone tickets are **FOR_SALE** immediately after generation.

**Response:** `items` (`TicketDto[]`), `count`. Each ticket has `ticketCode`, `purpose`. Build the QR on the client (see **QR codes** below).

---

## QR codes (Flutter generates, server validates)

Tickets do **not** ship a ready-to-scan QR from the API. The mobile app builds it with `SecureQRGenerator` (same as Mon peya / `GENERATEUR_CODE_QR`), using `QR_ENCRYPT_KEY` from `.env`.

**Suggested inner payload** (`QRData.payload`):

| Key | Example | Description |
|-----|---------|-------------|
| `ticketCodeKey` | `TKT-A1B2C3D4` | Required — looked up on verify/consume |
| `eventCodeKey` | `EVT-…` or `""` | Optional |
| `purposeKey` | `EVENT` | `EVENT`, `TRANSPORT`, `PASS`, `GENERIC` |
| `titleKey` | `Concert VIP` | Display |
| `userTypeKey` | `TKT` | Distinguishes ticket QRs |

```dart
final qr = await SecureQRGenerator(GeneratorConfig(
  secretKey: qrEncryptKey,
  enableEncryption: true,
  enableSignature: true,
  validityDuration: const Duration(days: 365),
  dataVersion: 1,
  idPrefix: 'TKT-',
)).generateQR(QRData(payload: {
  'ticketCodeKey': ticket.ticketCode,
  'eventCodeKey': ticket.eventCode ?? '',
  'purposeKey': ticket.purpose,
  'titleKey': ticket.title,
  'userTypeKey': 'TKT',
}));
// qr.qrContent → send to POST /v1/tickets/verify or /consume as qrPayload
```

**Server validation** (`SecureQrValidatorService`):

1. Base64-decode → AES-CBC decrypt (IV = first 16 bytes, key = `QR_ENCRYPT_KEY.padRight(32)`)
2. HMAC-SHA256 on JSON **without** the `signature` field (full key bytes, not padded)
3. Resolve `ticketCodeKey` → load ticket from DB
4. Legacy `TKT|{code}|{context}|{hmac}` QRs still accepted for old tickets

`ticketing.qr.check-expiration=false` by default (tickets are not 5-minute merchant QRs).

---

### `POST /v1/tickets/get`

Get ticket by **ticket code**.

```json
{ "data": { "ticketCode": "TKT-A1B2C3D4" } }
```

---

### `POST /v1/tickets/buy`

Purchase a **FOR_SALE** ticket by `ticketCode`. Event tickets require the linked event to be **PUBLISHED**.

**Request `data`:**

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `ticketCode` | yes | string | e.g. `TKT-A1B2C3D4` |
| `codeClient` | yes | string | Buyer Peya code |
| `paymentMethod` | no | string | Default `PEYA_WALLET` |

```json
{
  "data": {
    "ticketCode": "TKT-A1B2C3D4",
    "codeClient": "BUYER_CODE",
    "paymentMethod": "PEYA_WALLET"
  }
}
```

**Response `item`:** ticket with `status`=`SOLD`, `orderRef`, `paymentReference`. Build QR on the client after purchase.

---

### `POST /v1/tickets/verify`

Verify QR without consuming.

**Request `data`:**

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `qrPayload` | yes | string | Base64 SecureQR from Flutter scan |

```json
{ "data": { "qrPayload": "..." } }
```

**Response:** `item` (`TicketDto`) if decryption, signature, and ticket lookup succeed.

---

### `POST /v1/tickets/consume`

Mark ticket as used at venue.

**Request `data`:**

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `qrPayload` | yes | string | Base64 SecureQR from Flutter scan |
| `scannerCodeClient` | yes | string | Scanner Peya code |
| `consumedPlace` | no | string | Gate / zone name |
| `scannerDeviceId` | no | string | Device id |

```json
{
  "data": {
    "qrPayload": "...",
    "scannerCodeClient": "SCANNER_CODE",
    "consumedPlace": "Main entrance",
    "scannerDeviceId": "device-01"
  }
}
```

**Response:** `item` with `status`=`CONSUMED`, `consumedAt` set.

---

### `POST /v1/tickets/my`

Buyer's purchased tickets.

**Request `data`:**

| Field | Required | Type |
|-------|----------|------|
| `codeClient` | yes | string |

**Response:** `items` (`TicketDto[]`), newest first.

---

## Creator dashboard

### `POST /v1/dashboard/creator/summary`

**Request `data`:** `{ "codeClient": "..." }`

**Response `item` (`CreatorDashboardResultDto`):**

| Field | Type |
|-------|------|
| `events` | `EventDto[]` |
| `totalTicketsGenerated` | long |
| `totalTicketsSold` | long |
| `totalTicketsConsumed` | long |

---

### `POST /v1/dashboard/creator/tickets`

All tickets for creator's events.

**Request `data`:** `{ "codeClient": "..." }`

**Response:** `items` (`TicketDto[]`), `count`.

---

## Data models

### EventStatus

`DRAFT` · `PUBLISHED` · `CLOSED` · `CANCELLED`

### TicketStatus

`GENERATED` · `FOR_SALE` · `SOLD` · `CONSUMED` · `CANCELLED`

### EventDto (response)

| Field | Type |
|-------|------|
| `eventCode` | string (public identifier, e.g. `EVT-2026-A1B2C3D4`) |
| `codeClient` | string (creator) |
| `creatorName` | string |
| `creatorPhone` | string |
| `name` | string |
| `category` | string |
| `venueName`, `address`, `city`, `country` | string |
| `latitude`, `longitude` | number |
| `startAt`, `endAt` | datetime |
| `ticketPrice` | number |
| `maxTickets` | integer |
| `ticketsGenerated`, `ticketsSold`, `ticketsConsumed` | integer |
| `status` | EventStatus |
| `createdAt`, `publishedAt` | datetime |

### TicketDto (response)

| Field | Type |
|-------|------|
| `ticketCode` | string (public identifier, e.g. `TKT-A1B2C3D4`) |
| `qrPayload` | string |
| `purpose` | TicketPurpose (`EVENT`, `TRANSPORT`, `PASS`, `GENERIC`) |
| `eventCode` | string (null for standalone tickets) |
| `orderRef` | string |
| `title` | string (event name or standalone label) |
| `place` | string |
| `validFrom` | datetime |
| `ticketType` | string |
| `price`, `amountPaid` | number |
| `builtByCodeClient`, `builtByName` | string |
| `buyerCodeClient`, `buyerName`, `buyerPhone` | string |
| `generatedAt`, `purchasedAt`, `consumedAt` | datetime |
| `paymentReference`, `referOp` | string |
| `consumedPlace`, `consumedByCodeClient`, `consumedByName` | string |
| `scannerDeviceId` | string |
| `status` | TicketStatus |

---

## cURL examples

```bash
# Ping
curl -X POST http://localhost:8090/v1/ping -H "Content-Type: application/json" -d "{\"data\":{}}"

# Create event (peya profile + valid codeClient)
curl -X POST http://localhost:8090/v1/events/create \
  -H "Content-Type: application/json" \
  -d "{\"data\":{\"codeClient\":\"CODE\",\"name\":\"Fest\",\"category\":\"CONCERT\",\"startAt\":\"2026-07-01T20:00:00\",\"endAt\":\"2026-07-01T23:00:00\",\"ticketPrice\":5000,\"maxTickets\":100}}"
```

On Windows PowerShell, prefer a JSON file: `curl.exe ... -d "@request.json"`.
