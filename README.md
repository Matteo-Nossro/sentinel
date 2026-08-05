# Sentinel

Petite plateforme de monitoring/alerting que j'ai montée pour pratiquer les microservices et l'event-driven avec Spring Boot + Angular. Des sources poussent des métriques, un moteur de règles les évalue en continu, et les alertes déclenchées partent vers un dashboard en temps réel (SSE) et des webhooks (Discord/Telegram/custom).

Ce dépôt est le repo chapeau : il agrège les 4 microservices back et le front via des submodules Git, plus le Docker Compose pour tout faire tourner en local.

## Architecture

```
Agents/sources ──▶ api-gateway (8080)
                       │
        ┌──────────────┼──────────────┐
        ▼               ▼              ▼
  ingestion-service  rules-engine  notification-service
      (8081)            (8082)           (8083)

  front Angular (4200) ──▶ api-gateway
```

- **api-gateway** : point d'entrée, valide le JWT, route vers les 3 services métier (Spring Cloud Gateway, réactif)
- **ingestion-service** : reçoit les métriques, les persiste, publie sur Redis
- **rules-engine** : évalue les règles sur le flux d'événements, publie les alertes
- **notification-service** : dispatch les alertes (SSE + webhooks)
- **sentinel-front** : dashboard Angular

Chaque service back suit une architecture hexagonale (domain / application / infrastructure) avec son propre schéma Postgres. Le bus d'événements c'est du Redis Pub/Sub, pas de Kafka — volontairement, pour rester simple sur ce genre de projet.

## Stack

Java 17, Spring Boot 3.5, Spring Cloud Gateway, Spring Data JPA/Redis, Spring Security, MapStruct côté back. Angular 21 (standalone), NgRx SignalStore, Tailwind v4 côté front. Postgres 16, Redis 7, Docker Compose.

## Lancer le projet

Cloner avec les submodules :

```bash
git clone --recurse-submodules https://github.com/Matteo-Nossro/sentinel.git
cd sentinel
```

(si déjà cloné sans l'option : `git submodule update --init --recursive`)

Copier `.env.example` en `.env` et ajuster les valeurs, puis :

```bash
docker compose up -d --build
```

Ça lance Postgres, Redis et les 4 services back. Les schémas Postgres sont créés au premier démarrage via `init-db.sql`.

Pour le front en dev (hot reload) :

```bash
cd sentinel-front
npm install
ng serve
```

Swagger dispo sur chaque service back : `http://localhost:<port>/swagger-ui.html`.

### Tests back

Nécessite Java 17 (le build échoue sous Java 11/21 avec un mismatch de version de classe) :

```bash
cd rules-engine && ./mvnw test
```
(idem pour les 3 autres services)

## Sous-dépôts

- [api-gateway](https://github.com/Matteo-Nossro/sentinel-api-gateway)
- [ingestion-service](https://github.com/Matteo-Nossro/sentinel-ingestion-service)
- [rules-engine](https://github.com/Matteo-Nossro/sentinel-rules-engine)
- [notification-service](https://github.com/Matteo-Nossro/sentinel-notification-service)
- [sentinel-front](https://github.com/Matteo-Nossro/sentinel-front)

## Déploiement

Voir [DEPLOYMENT.md](DEPLOYMENT.md) pour le déploiement sur un serveur perso derrière un tunnel Cloudflare.
