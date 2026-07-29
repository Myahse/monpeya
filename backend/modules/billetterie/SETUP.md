# Setup guide

> **Main documentation:** see [README.md](README.md)

## Prerequisites

Java 17 · Maven · Docker Desktop

## Environment (`.env`)

All secrets live in **`.env`** in this directory (never commit — use `.env.example` as template).

```bash
cp .env.example .env
# Edit .env — fill PEYA_APP_ADMIN_* and remote Oracle if needed
```

The app loads `.env` automatically on startup (`DotenvLoader`).

| Variable | Purpose |
|----------|---------|
| `ENCRYPT_KEY` / `QR_ENCRYPT_KEY` | QR HMAC signing (Mon peya parity) |
| `DATASOURCE_*` | Local Docker Oracle |
| `ORACLE_PASSWORD` | Oracle XE container admin |
| `PEYA_APP_ADMIN_USERNAME` / `PASSWORD` | Peya API auth (profile `peya`) |
| `PEYA_ORACLE_*` | Remote Oracle (profile `peya-oracle`, VPN) |
| `SPRINGDOC_*` | Disable Swagger in production |

## Quick start

```bash
cd backend/ticketing
./mvnw spring-boot:run -Dspring-boot.run.profiles=peya
```

- API: http://localhost:8090
- Swagger: http://localhost:8090/swagger-ui.html

## Profiles

| Profile | Database | Client lookup |
|---------|----------|---------------|
| default | Local Docker | `W_CLIENTS` |
| `peya` | Local Docker | Peya test1 API |
| `peya,peya-oracle` | Remote Peya Oracle (VPN) | Peya API |

## Troubleshooting

### `ORA-00942`

```powershell
Get-Content "docker\oracle\init\00-connect-ticketing.sql", "docker\oracle\init\02-ticketing-schema.sql" |
  docker exec -i ticketing-oracle sqlplus -s ticketing/ticketing@XEPDB1
```

Or: `docker compose down -v && docker compose up -d`

### Missing Peya credentials

Set `PEYA_APP_ADMIN_USERNAME` and `PEYA_APP_ADMIN_PASSWORD` in `.env`.

### Keys with `#`

Always quote in `.env`: `ENCRYPT_KEY='2024#@#...'`
