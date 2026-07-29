# Monpeya — backend unifié

**Un seul processus JVM** (`modules/server`) sur le port **8082**, modules DDD :

```
backend/
├── pom.xml                 # Parent Maven
├── compose.yaml            # Oracle + server unifié
├── Dockerfile              # Build multi-stage du server
├── docker/oracle/init/     # Schémas Oracle (monpeya, ticketing, immo)
└── modules/
    ├── shared-kernel/      # Auth session partagée
    ├── platform/           # Auth, abonnements
    ├── billetterie/        # Tickets, événements
    ├── immo/               # Mr Immo rental
    └── server/             # Point d'entrée unifié ← lancer celui-ci
```

## URLs

| Module | Chemin | Exemple |
|--------|--------|---------|
| Platform | `/api/platform/v1/*` | `POST /v1/auth/login` |
| Billetterie | `/api/billetterie/v1/*` | `POST /v1/tickets/buy` |
| Immo | `/api/immo/*` | `POST /api/biens/getByCriteria` |

## Démarrage rapide (Docker)

```bash
cd backend
cp .env.example .env
docker compose up -d
```

- API : http://localhost:8082
- Swagger : http://localhost:8082/swagger-ui.html
- Ping platform : `POST http://localhost:8082/api/platform/v1/ping`
- Ping billetterie : `POST http://localhost:8082/api/billetterie/v1/ping`
- Health immo : `GET http://localhost:8082/api/immo/health`

## Démarrage local (dev)

```bash
# Terminal 1 — Oracle
cd backend && docker compose up -d oracle

# Terminal 2 — Server unifié
cd backend
cp .env.example .env
mvn -pl modules/server spring-boot:run
```

Modules **standalone** (debug isolé) :

```bash
cd backend/modules/platform && ./mvnw spring-boot:run
cd backend/modules/billetterie && ./mvnw spring-boot:run -Dspring-boot.run.profiles=peya
```

## Build

```bash
cd backend
mvn -pl modules/server -am package -DskipTests
java -jar modules/server/target/server-0.0.1-SNAPSHOT.jar
```

## Mobile (`.env`)

```env
MONPEYA_API_URL=http://10.0.2.2:8082/api/platform
BILLETTERIE_API_URL=http://10.0.2.2:8082/api/billetterie
IMMO_API_URL=http://10.0.2.2:8082/api/immo
```

## Architecture technique

- **Multi-datasource JPA** : schémas `monpeya`, `ticketing`, `immo` sur 1 Oracle
- **Path prefixes** : `/api/platform`, `/api/billetterie`, `/api/immo` via `ModulePathConfig`
- **Auth unifiée** : token Mon Peya (Bearer) pour immo et billetterie
- **Spring Modulith** : `@ApplicationModule` + `@Modulith` sur chaque module
- **Immo enrichi** : contrats location + paiements récurrents
