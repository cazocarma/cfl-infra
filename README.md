# cfl-infra

Orquestacion Docker Compose para el sistema de Control de Fletes (CFL) de Greenvic.

Soporte oficial del Makefile:

- Linux con Bash
- Windows con Git Bash o `bash`/`bash.exe` disponible en `PATH`

## Arquitectura

| Aspecto | PRD (server) | DEV (local) |
|---|---|---|
| Branch | `main` | `dev` |
| Compose project | `greenvic-cfl-prd` | — |
| Backend alias | `cfl-backend` | — |
| Frontend alias | `cfl-frontend` | — |
| Puerto | 80 | localhost |

```
/opt/cfl/
  prd/               branch main, CFL_ENV=prd
    cfl-infra/       docker-compose, .env, database scripts
    cfl-back/
    cfl-front-ng/
  dev/               (vacio — desarrollo es local)
```

Desarrollo se hace en maquina local. Deploy a PRD es automatico via merge a `main` (deployer por polling).

## Setup

### 1. Clonar repos

```bash
mkdir -p /opt/cfl/prd && cd /opt/cfl/prd
git clone -b main git@github.com:cazocarma/cfl-infra.git
git clone -b main git@github.com:cazocarma/cfl-back.git
git clone -b main git@github.com:cazocarma/cfl-front-ng.git
```

### 2. Configurar entorno

```bash
cd /opt/cfl/prd/cfl-infra
cp .env.example .env
# Editar .env con valores reales (secrets, passwords, IPs)
```

### 3. Levantar

```bash
make up          # Levanta el stack
make up-build    # Levanta reconstruyendo imagenes
```

En Windows, correr estos comandos desde Git Bash o desde una terminal que tenga `bash` disponible en `PATH`.

## Variables de entorno

Archivo: `cfl-infra/.env` (gitignoreado). Plantilla: `.env.example`.

| Variable | Descripcion |
|---|---|
| `CFL_ENV` | Ambiente: `prd` o `dev` |
| `CFL_BACKEND_ALIAS` | Alias Docker del backend |
| `CFL_FRONTEND_ALIAS` | Alias Docker del frontend |
| `NODE_ENV` | `production` o `development` |
| `PORT` | Puerto del backend (4000) |
| `CORS_ORIGIN` | Origen CORS |
| `AUTHN_JWT_SECRET` | Secret JWT (min 32 bytes) |
| `DB_HOST` / `DB_PORT` / `DB_USER` / `DB_PASSWORD` / `DB_NAME` | Conexion SQL Server |
| `SAP_ETL_BASE_URL` / `SAP_ETL_API_TOKEN` | Integracion SAP ETL |

## Deploy automatico

El deploy a PRD se ejecuta automaticamente al hacer merge a `main` en GitHub:

1. GitHub envia webhook a `http://<IP>/webhook/github`
2. El servicio `greenvic-deployer` (en platform) valida la firma HMAC
3. Ejecuta `git pull` en el repo afectado dentro de `/opt/cfl/prd/`
4. Rebuild + restart del servicio Docker
5. Smoke tests (health checks)

Configuracion del webhook: ver `platform/deployer/deploy-config.json`.

### Deploy manual

```bash
cd /opt/cfl/prd/cfl-infra
make deploy      # git pull + build + up (valida branch)
make redeploy    # down + build + up
```

## Base de datos

Esquema: `[cfl]` en SQL Server. Scripts en `database/modelo-datos/`:

| Archivo | Descripcion |
|---|---|
| `UP.sql` | Definicion completa del schema (52 tablas, vistas, indices, FKs) |
| `seed/04_seguridad.sql` | Roles, permisos, usuarios seed (idempotente via MERGE) |

### Roles y permisos

| Rol | Permisos | Descripcion |
|---|---|---|
| Administrador | 33 (todos) | Acceso total |
| Autorizador | 27 | Operaciones + mantenedores parcial |
| Ingresador | 11 | Fletes + lectura facturas/planillas/mantenedores |

## Servicios

| Servicio | Puerto interno | Descripcion |
|---|---|---|
| `front-ng` | 3000 | Frontend Angular |
| `back` | 4000 | Backend Node.js/Express |

## Red

| Red | Proposito |
|---|---|
| `greenvic-cfl-{env}_default` | Red principal del stack |
| `platform_identity` | Comunicacion con Keycloak |
| `greenvic-cfl-{env}_egress` | Salida a servicios externos (SAP ETL) |

## Makefile

| Target | Descripcion |
|---|---|
| `up` / `up-build` | Levantar stack |
| `down` / `down-v` | Bajar stack (con/sin volumenes) |
| `deploy` / `redeploy` | Deploy (pull+build+up) |
| `ps` / `status` | Estado de contenedores |
| `logs` / `logs-cfl-front` / `logs-cfl-back` | Logs |
| `doctor` | Verificacion completa del entorno |
| `env-info` | Muestra ambiente actual |

## Validacion

```bash
make doctor
curl http://127.0.0.1/healthz       # frontend PRD
curl http://127.0.0.1/api/health    # backend PRD
```
