# Module Immo — Mr Immo (rental-app API)

Backend JPA complet, exposé sous `http://host:8082/api/immo`.

> **Note** : le repo source `rental-app` (React Native) n'est pas disponible ; ce module reproduit le contrat API attendu par `mobile/packages/immo`.

## Schéma Oracle (`immo`)

Tables : `CODE_PAYS`, `TYPE_BIENS`, `BIENS`, `LOCATAIRES`, `PAIEMENTS`, `MESSAGES`

Scripts : `backend/docker/oracle/init/30-create-immo-user.sql`, `31-immo-schema.sql`

## Endpoints

| Méthode | Chemin | Auth |
|---------|--------|------|
| GET | `/health` | Public |
| POST | `/api/auth/login` | Public (bridge Mon Peya) |
| POST | `/api/biens/getByCriteria` | Bearer Mon Peya |
| GET | `/api/biens/public/{id}` | Public |
| POST | `/api/biens/create` | Bearer |
| POST | `/api/locataires/getByCriteria` | Bearer |
| POST | `/api/locataires/create` | Bearer |
| POST | `/api/paiements/getByCriteria` | Bearer |
| POST | `/api/codePays/getByCriteria` | Bearer |
| GET | `/api/messages/conversations/{userId}` | Bearer |
| GET | `/api/messages/conversation` | Bearer |
| POST | `/api/messages` | Bearer |
| POST | `/api/upload/file` | Bearer |

## Auth

Token Mon Peya unique : `Authorization: Bearer <accessToken>`
