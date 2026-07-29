# Monpeya Backend — Auth & Subscriptions

## What this backend owns

1. **PeyaPay auth** — lookup/login call Peya and upsert **`MP_USER`** / **`MP_ACCOUNT`**.
2. **Monpeya session** — access/refresh tokens on `MP_SESSION`.
3. **Access gates** — guest / auth / subscription (+ CLIENT vs BUSINESS role).
4. **Subscriptions** — per service + role (mock pay). Dual-role services except Leadway.
5. **Service profiles** — everyone starts CLIENT; BUSINESS via documents or PeyaPay merchant.

Wallet / profile proxies are **not** owned here.

## Dual role model

| Service type | Example | Roles |
|--------------|---------|--------|
| **CLIENT_AND_BUSINESS** | Billetterie / Immo | Start as **CLIENT**. Upgrade in settings (ID docs) or if already **PeyaPay merchant** → then subscribe as **BUSINESS** (conductor / owner / company). Client ticket use → subscribe as **CLIENT**. |
| **CLIENT_ONLY** | **Leadway**, home, PeyaPay | Everyone is client only — no business upgrade / business subscribe. |

Flow:

1. Login as PeyaPay client (both sides).
2. Use service as **CLIENT** (subscribe as CLIENT when needed).
3. Settings → business version → upload docs **or** PeyaPay merchant shortcut → `APPROVED`.
4. Subscribe as **BUSINESS** for that service.

**PeyaPay merchant detection** (from `/wClients/rechercheclient`): any `datasCompte.typcpt = "S"`
(supplier account + `numerocomptecomplet`). Pure clients only have `typcpt = "P"`.
Cached on `MP_USER.IS_PEYAPAY_MERCHANT` at login/lookup; returned as `isPeyapayMerchant` on auth user.

## Auth

| Path | Effect |
|------|--------|
| `POST /v1/auth/lookup` | Upsert user |
| `POST /v1/auth/login` | PIN → session |
| `POST /v1/auth/otp/send` / `verify` | OTP |
| `POST /v1/auth/me` / `refresh` / `logout` | Session |

## Catalog & access

| Path | Effect |
|------|--------|
| `POST /v1/modules/catalog` | Services: `name`, `roleModel`, `parameters[{key,value}]`, actions (`requiredRole`) |
| `POST /v1/access/check` | Guest / AUTH / SUBSCRIPTION + role check |

## Service profiles & business upgrade

| Path | Body highlights | Effect |
|------|-----------------|--------|
| `POST /v1/services/profiles/me` | `accessToken` | All profiles (auto CLIENT) |
| `POST /v1/services/profiles/get` | `accessToken`, `moduleCode` | One profile |
| `POST /v1/services/business/upgrade` | `moduleCode`, `upgradePath`: `DOCUMENTS` \| `PEYAPAY_MERCHANT` | Start upgrade (merchant mock-approves) |
| `POST /v1/services/business/documents` | `moduleCode`, `docType`, `fileRef` | Register ID doc (mock accept) |

`docType`: `ID_CARD_FRONT` \| `ID_CARD_BACK` \| `BUSINESS_REG` \| `OTHER`

## Subscriptions

| Path | Effect |
|------|--------|
| `POST /v1/plans` | Monpeya access plans — **prices from `.env`** (not ticket prices) |
| `POST /v1/subscriptions/me` | Active subs |
| `POST /v1/subscriptions/subscribe` | **CLIENT only** — straight debit if **déplafonné** |
| `POST /v1/subscriptions/requests/deplafonnement` | CLIENT not déplafonné → request first |
| `POST /v1/subscriptions/requests/business` | **BUSINESS** — debit now + plan/amount → wait approval |
| `POST /v1/subscriptions/requests/me` | My requests |
| `POST /v1/subscriptions/requests/review` | `decision`: `APPROVE` \| `REJECT` \| `ON_REVIEW` |

### Flows

**CLIENT**
1. Must be Peya **déplafonné** — root field `deplafonner` on `/wClients/rechercheclient` item
   (e.g. `"deplafonner": false` → not allowed to subscribe until approved). Not inferred from `dateDeplafonner`.
2. If not → `requests/deplafonnement` → status `WAITING_FOR_APPROVAL` → `ON_REVIEW` / `APPROVED` / `REJECTED`.
3. When déplafonné → `subscribe` debits straight (mock) and activates sub.

**BUSINESS**
1. Identity upgrade first (docs or PeyaPay merchant `typcpt=S`).
2. `requests/business` with `planCode` (+ optional `amount`) → **debited at launch** → `WAITING_FOR_APPROVAL`.
3. Review → `ON_REVIEW` / `APPROVED` (activates BUSINESS sub) / `REJECTED`.

Request statuses: `WAITING_FOR_APPROVAL` \| `ON_REVIEW` \| `APPROVED` \| `REJECTED`.

**Pricing:** set in `.env` / `application.properties` (not ticketing fares):

```
SUBSCRIPTION_CURRENCY=XOF
SUBSCRIPTION_CLIENT_PRICE=1000
SUBSCRIPTION_BUSINESS_PRICE=5000
SUBSCRIPTION_CLIENT_PLAN_CODE=CLIENT_ACCESS
SUBSCRIPTION_BUSINESS_PLAN_CODE=BUSINESS_ACCESS
```

## Tables

| Table | Role |
|-------|------|
| `MP_MODULE` | Services + `ROLE_MODEL` |
| `MP_MODULE_PARAM` | Key/value for mobile |
| `MP_SERVICE_ACTION` | Actions + `REQUIRED_ROLE` |
| `MP_SERVICE_PROFILE` | User × service role / business status |
| `MP_BUSINESS_DOCUMENT` | Upgrade documents |
| `MP_SUBSCRIPTION` | Active sub per `MODULE_ID` + `ROLE` |
| `MP_SUBSCRIPTION_REQUEST` | BUSINESS debit+approval / CLIENT déplafonnement |
| `MP_PLAN` | Monpeya access plans (not ticket prices) |
| `MP_USER.IS_DEPLAFONNE` | From Peya `deplafonner` |
