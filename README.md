# cfl-infra

Infraestructura local para desarrollo.

## Variables de entorno centralizadas

Se usa un unico archivo de variables: `cfl-infra/.env`.
No se usan `.env` separados en `cfl-back` ni `cfl-front-ng`.

## Levantar todo desde infra

1. Copiar `.env.example` a `.env`
2. Ajustar variables de entorno de backend/BD segun tu entorno
3. Desde esta carpeta, levantar todo:

```bash
docker compose up -d
```

Esto levanta:
- `gateway` en `http://localhost` (puerto 80)
- `front-ng` interno en red Docker (`front-ng:3000`)
- `back` interno en red Docker (`back:4000`)

El navegador solo necesita acceder al `gateway`. El gateway enruta:
- `/` -> `front-ng`
- `/api/*` -> `back`

## Acceso desde LAN

La app queda disponible en:

```text
http://IP_DEL_SERVIDOR
```

## Comandos rapidos

Ejecutar todo desde `cfl-infra` (PowerShell):

```powershell
Copy-Item .env.example .env
docker compose up -d
docker compose logs -f gateway
```

Detener servicios:

```powershell
docker compose down
```

## Carpeta database

`database/modelo-datos` queda organizado por rol:
- `UP.sql`: modelo (schema/DDL).
- `SEED.sql`: carga de datos iniciales por modulos (`seed/*.sql`).
- `DOWN.sql`: eliminacion completa del esquema.
- `ops/*.sql`: utilitarios/paches manuales (no forman parte del flujo base `UP + SEED`).
