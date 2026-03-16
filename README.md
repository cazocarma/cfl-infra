# cfl-infra

Infraestructura local de desarrollo para `greenvic-control-fletes`.

## Fuente de entorno

- Archivo real: `cfl-infra/.env`
- Plantilla: `cfl-infra/.env.example`
- `cfl-back` y `cfl-back-go` consumen este archivo; no usan `.env` propios

## Flujo recomendado

Desde la raiz del monorepo:

```bash
make env-check
make up-node
make up-node-db
make up-go
make up-go-db
make down
make down-v
```

## Perfiles disponibles

- `node`: backend Node
- `go`: backend Go
- `db`: SQL Server local

## Equivalentes docker compose

Desde `cfl-infra/`:

```bash
docker compose --profile node up -d --build
docker compose --profile node --profile db up -d --build
docker compose --profile go up -d --build
docker compose --profile go --profile db up -d --build
docker compose --profile db up -d sqlserver
```

## Servicios

- `gateway`: expone `http://localhost`
- `front-ng`: frontend Angular
- `back`: backend Node
- `back-go`: backend Go
- `sqlserver`: base de datos local

## Validacion rapida

```bash
docker compose ps
curl http://127.0.0.1/healthz
curl http://127.0.0.1/api/health
```

## Reset de base de datos

```bash
docker compose down -v
```

o desde la raiz:

```bash
make down-v
```
