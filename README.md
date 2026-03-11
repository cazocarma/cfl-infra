# cfl-infra

Infraestructura local de desarrollo con Docker Compose.

## Variables de entorno centralizadas

Se usa un unico archivo de variables: `cfl-infra/.env`.
No se usan `.env` separados en `cfl-back` ni `cfl-front-ng`.

## Levantar stack

1. Copiar `.env.example` a `.env`.
2. Ajustar variables de backend/DB segun tu entorno.
3. Desde `cfl-infra`, levantar servicios:

```bash
# App + gateway (usa DB externa)
docker compose up -d

# Stack completo incluyendo SQL Server local
docker compose --profile db up -d --build
```

Servicios principales:
- `gateway` en `http://localhost` (puerto 80)
- `front-ng` interno (`front-ng:80`)
- `back` interno (`back:4000`)
- `sqlserver` interno (solo con perfil `db`)

El navegador solo necesita `gateway`:
- `/` -> `front-ng`
- `/api/*` -> `back`

## Configuracion de DB recomendada

Para SQL Server en el mismo compose (`--profile db`):
- `DB_HOST=sqlserver`
- `MSSQL_MEMORY_LIMIT_MB=1024` (recomendado en laptops para evitar presion de memoria)

Para SQL Server fuera de compose, ejecutando en la maquina host:
- `DB_HOST=host.docker.internal`

## Health checks

- Gateway: `GET /healthz`
- Backend: `GET /api/health` (viene de `/health` en el back)

Validacion rapida:

```powershell
docker compose ps
curl http://127.0.0.1/healthz
curl http://127.0.0.1/api/health
```

## Comandos rapidos

```powershell
Copy-Item .env.example .env
docker compose --profile db up -d --build
docker compose logs -f gateway
```

Detener y limpiar:

```powershell
docker compose down
```

## Notas de seguridad aplicadas

- `depends_on` por salud (`service_healthy`) para evitar arrancar dependencias no listas.
- Endurecimiento base de contenedores (`no-new-privileges` en todos los servicios).
- Health checks activos en `gateway`, `front-ng`, `back` y `sqlserver`.
- Imagen Node actualizada a `node:20-bookworm-slim` para mejor base de seguridad y mantenimiento.
- Instalacion de dependencias con cache en backend (`npm install --prefer-offline`) para reducir tiempo y trafico en reinicios.
- `front-ng` se ejecuta como imagen buildada (Angular compilado + Nginx), reduciendo consumo de memoria y superficie de ataque frente a `ng serve`.

## Carpeta database

`database/modelo-datos` queda organizado por rol:
- `UP.sql`: modelo (schema/DDL).
- `SEED.sql`: carga de datos iniciales por modulos (`seed/*.sql`).
- `DOWN.sql`: eliminacion completa del esquema.
- `ops/*.sql`: utilitarios/parches manuales (no forman parte del flujo base `UP + SEED`).
