# Déploiement

Notes pour déployer Sentinel sur mon LXC Portainer (homelab), derrière un tunnel Cloudflare — pas de reverse proxy classique, pas de port ouvert sur la box.

Le conteneur `sentinel-front` (nginx) sert le build Angular et proxifie `/api` et `/auth` vers `api-gateway` en interne (réseau Docker). Ça évite d'avoir à exposer 4 ports différents : le tunnel Cloudflare pointe juste sur le front.

## Récupérer le code

```bash
git clone --recurse-submodules https://github.com/Matteo-Nossro/sentinel.git
cd sentinel
```

(si déjà cloné sans l'option : `git submodule update --init --recursive`, sinon les dossiers de service restent vides)

## Config

```bash
cp .env.example .env
```

À changer absolument avant de passer en prod :
- `POSTGRES_PASSWORD`, `JWT_SECRET` (généré avec `openssl rand -base64 48`), `ADMIN_PASSWORD`
- `CORS_ALLOWED_ORIGIN` → `https://sentinel.nossereau.fr`
- `FRONT_PORT` : `8084` chez moi (libre sur le LXC, ni baserow/n8n/portainer/vscode ne l'utilisent)

## Build et démarrage

```bash
docker compose up -d --build
docker ps
```

Test rapide :

```bash
curl -X POST http://localhost:8084/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"<ADMIN_PASSWORD>"}'
```

## Tunnel Cloudflare

Zero Trust → Tunnels → Public Hostname :
- Subdomain `sentinel`, domain `nossereau.fr`, type HTTP
- URL : `192.168.1.37:8084`

Le flux SSE (`/api/notifications/stream`) passe par la même route, pas de config particulière côté tunnel.

## Mise à jour

```bash
git pull
git submodule update --init --recursive
docker compose up -d --build
```

## Dépannage

```bash
docker compose logs -f <service>
docker exec -it sentinel-postgres psql -U sentinel -d sentinel
```

Les données Postgres sont dans le volume `sentinel_pg_data`, pas de backup automatisé pour l'instant.
