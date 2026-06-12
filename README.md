# Sentinel

**Plateforme d'alerting / monitoring d'infrastructure** bâtie sur une architecture
microservices événementielle. Des agents poussent des métriques vers la plateforme,
un moteur de règles évalue ces métriques en continu et déclenche des alertes qui sont
routées vers les canaux de notification configurés.

Ce dépôt est le **repo chapeau** : il agrège les 4 microservices et le front via des
submodules Git, et fournit l'infrastructure locale (PostgreSQL + Redis) via Docker.

---

## Architecture

```
                         ┌──────────────────┐
   Agents / sources ───▶ │  api-gateway     │ :8080   (Spring Cloud Gateway, réactif/Netty)
                         └────────┬─────────┘
              ┌───────────────────┼────────────────────┐
              ▼                   ▼                     ▼
   ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────────┐
   │ ingestion-service│ │  rules-engine    │ │ notification-service │
   │      :8081       │ │     :8082        │ │        :8083         │
   └──────────────────┘ └──────────────────┘ └──────────────────────┘

   Front Angular (sentinel-front)  ──▶  api-gateway
```

### Services

| Service                | Port | Rôle |
|------------------------|------|------|
| **api-gateway**        | 8080 | Point d'entrée unique. Route `/api/ingestion/**`, `/api/rules/**`, `/api/notifications/**` vers les services métier (filtre `StripPrefix=2`). |
| **ingestion-service**  | 8081 | Réception et persistance des métriques/événements entrants ; publication sur Redis. |
| **rules-engine**       | 8082 | Évaluation des règles d'alerting sur le flux d'événements ; publication des alertes sur Redis. |
| **notification-service** | 8083 | Consommation des alertes ; envoi vers les canaux de notification. |
| **sentinel-front**     | 4200 | Interface Angular (dashboard, alertes, règles, sources, canaux). |

Chaque service métier suit une **architecture hexagonale**
(`domain` / `application` / `infrastructure`) et possède son propre **schéma PostgreSQL**
isolé (`ingestion`, `rules_engine`, `notification`).

---

## Pipeline événementiel

```
Agent ──▶ ingestion-service ──▶ Redis (Pub/Sub) ──▶ rules-engine ──▶ Redis (Pub/Sub) ──▶ notification-service ──▶ canaux
```

Le bus événementiel est **Redis Pub/Sub** : `ingestion-service` publie les métriques,
`rules-engine` les consomme, évalue les règles et publie les alertes, que
`notification-service` consomme à son tour pour notifier.

---

## Stack technique

| Domaine | Technologies |
|---|---|
| Back-end | Java 17, Spring Boot 3.5, Spring Cloud Gateway 2025.0 (réactif), Spring Data JPA, Spring Data Redis, Spring Security, MapStruct, springdoc-openapi |
| Front-end | Angular 21 (standalone, sans NgModule), NgRx SignalStore, Tailwind CSS v4, Lucide |
| Données | PostgreSQL 16 (schémas isolés par service) |
| Messagerie | Redis 7 (Pub/Sub) |
| Infra locale | Docker Compose |
| Build | Maven (wrapper `mvnw`), npm |

---

## Lancer le projet

### 1. Cloner avec les submodules

```bash
git clone --recurse-submodules git@github.com:Matteo-Nossro/sentinel.git
cd sentinel
```

> Si tu as déjà cloné sans `--recurse-submodules` :
> `git submodule update --init --recursive`

### 2. Configurer l'environnement

```bash
cp .env.example .env
```

### 3. Démarrer l'infrastructure (PostgreSQL + Redis)

```bash
docker compose up -d
```

Les schémas `ingestion`, `rules_engine` et `notification` sont créés automatiquement
au premier démarrage via `init-db.sql`.

### 4. Lancer les services back-end

Chaque service se lance depuis IntelliJ (classe `*Application`) ou en ligne de commande :

```bash
cd ingestion-service     && ./mvnw spring-boot:run   # :8081
cd rules-engine          && ./mvnw spring-boot:run   # :8082
cd notification-service  && ./mvnw spring-boot:run   # :8083
cd api-gateway           && ./mvnw spring-boot:run   # :8080
```

> Java 17 requis. Documentation OpenAPI de chaque service métier :
> `http://localhost:<port>/swagger-ui.html`

### 5. Lancer le front

```bash
cd sentinel-front
npm install
ng serve            # http://localhost:4200
```

---

## Sous-dépôts

| Module | Dépôt |
|---|---|
| api-gateway | https://github.com/Matteo-Nossro/sentinel-api-gateway |
| ingestion-service | https://github.com/Matteo-Nossro/sentinel-ingestion-service |
| rules-engine | https://github.com/Matteo-Nossro/sentinel-rules-engine |
| notification-service | https://github.com/Matteo-Nossro/sentinel-notification-service |
| sentinel-front | https://github.com/Matteo-Nossro/sentinel-front |
