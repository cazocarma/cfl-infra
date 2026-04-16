# CFL Infraestructura

Orquestacion Docker Compose, scripts de base de datos y herramientas de operacion para el sistema de Control de Fletes (CFL) de Greenvic. Este repositorio centraliza la configuracion de entorno, el esquema de base de datos y los procedimientos de deploy para los ambientes de desarrollo y produccion.

## Arquitectura general

El sistema CFL se compone de tres repositorios que trabajan en conjunto:

| Repositorio | Descripcion | Puerto |
| --- | --- | --- |
| `cfl-infra` | Orquestacion, base de datos y configuracion de entorno | -- |
| `cfl-back` | API REST Node.js/Express | 4000 |
| `cfl-front-ng` | Aplicacion web Angular | 3000 |

### Ambientes

| Aspecto | Produccion (PRD) | Desarrollo (DEV) |
| --- | --- | --- |
| Branch esperado | `main` | `dev` |
| Compose project | `greenvic-cfl-prd` | -- |
| Backend alias | `cfl-backend` | -- |
| Frontend alias | `cfl-frontend` | -- |
| Ubicacion | `/opt/cfl/prd/` (servidor) | Maquina local del desarrollador |

### Estructura en servidor de produccion

```text
/opt/cfl/
  prd/
    cfl-infra/       Docker Compose, .env, scripts de base de datos
    cfl-back/        Codigo fuente del backend
    cfl-front-ng/    Codigo fuente del frontend
```

El desarrollo se realiza en maquina local. El deploy a produccion es automatico mediante merge a `main` (ver seccion Deploy).

## Compatibilidad del Makefile

El Makefile requiere `bash` disponible en el PATH del sistema:

- Linux con Bash (nativo)
- Windows con Git Bash o cualquier terminal que exponga `bash`/`bash.exe`

## Setup inicial

### 1. Clonar repositorios

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
```

Editar `.env` con los valores reales de la instalacion (secrets, passwords, IPs, tokens). El archivo `.env` esta gitignoreado y nunca debe subirse al repositorio.

### 3. Levantar el stack

```bash
make up          # Levanta todos los servicios
make up-build    # Levanta reconstruyendo imagenes Docker
```

En Windows, ejecutar estos comandos desde Git Bash.

## Variables de entorno

Archivo: `.env` (gitignoreado). Plantilla de referencia: `.env.example`.

### Ambiente y Docker

| Variable | Descripcion | Ejemplo |
| --- | --- | --- |
| `CFL_ENV` | Ambiente de ejecucion | `prd` o `dev` |
| `CFL_BACKEND_ALIAS` | Alias Docker del contenedor backend | `cfl-backend` |
| `CFL_FRONTEND_ALIAS` | Alias Docker del contenedor frontend | `cfl-frontend` |
| `NODE_ENV` | Ambiente de Node.js | `production` o `development` |

### Backend

| Variable | Descripcion | Ejemplo |
| --- | --- | --- |
| `PORT` | Puerto del servidor backend | `4000` |
| `CORS_ORIGIN` | Origen permitido para CORS | `http://localhost:3000` |
| `AUTHN_JWT_SECRET` | Secreto JWT HS256 (minimo 32 bytes, obligatorio) | -- |

### Base de datos

| Variable | Descripcion | Ejemplo |
| --- | --- | --- |
| `DB_HOST` | Host de SQL Server | `sqlserver` |
| `DB_PORT` | Puerto de SQL Server | `1433` |
| `DB_USER` | Usuario de SQL Server | `sa` |
| `DB_PASSWORD` | Password de SQL Server | -- |
| `DB_NAME` | Nombre de la base de datos | `CFL` |

### Integracion SAP ETL

| Variable | Descripcion | Ejemplo |
| --- | --- | --- |
| `SAP_ETL_BASE_URL` | URL base del servicio SAP ETL | `http://sap-etl:5000` |
| `SAP_ETL_API_TOKEN` | Bearer token para autenticacion | -- |
| `SAP_ETL_DEFAULT_DESTINATION` | Destino RFC por defecto | `PRD` |
| `SAP_ETL_REQUEST_TIMEOUT_MS` | Timeout de requests hacia SAP ETL (ms) | `125000` |
| `CFL_ETL_MAX_DATE_RANGE_DAYS` | Maximo de dias en consultas por rango | `30` |

## Servicios Docker

| Servicio | Imagen base | Puerto | Memoria | CPU | Descripcion |
| --- | --- | --- | --- | --- | --- |
| `front-ng` | node:20 / nginx:1.27 | 3000 | 128 MB | 0.5 | Frontend Angular (read-only en runtime) |
| `back` | node:20-slim | 4000 | 512 MB | 1.0 | Backend Node.js/Express |

El servicio `back` utiliza el profile `node` y debe iniciarse explicitamente con `--profile node` o mediante el Makefile.

### Redes

| Red | Proposito |
| --- | --- |
| `greenvic-cfl-{env}_default` | Comunicacion interna entre servicios del stack |
| `platform_identity` | Comunicacion con el servicio de identidad (Keycloak) |
| `greenvic-cfl-{env}_egress` | Salida a servicios externos (SAP ETL) |

## Base de datos

El esquema completo reside en `[cfl]` dentro de SQL Server. Los scripts se organizan de la siguiente manera:

```text
database/modelo-datos/
  UP.sql                        Definicion completa del esquema (tablas, vistas, indices, FKs)
  DOWN.sql                      Eliminacion completa del esquema
  seed/
    01_catalogos_base.sql       Catalogos iniciales (temporadas, centros de costo, tipos)
    02_logistica_tarifas.sql    Nodos logisticos, rutas y tarifas
    03_transporte.sql           Empresas de transporte, camiones, choferes
    04_seguridad.sql            Roles, permisos y usuarios seed (idempotente via MERGE)
    05_empresas_transportes_sap.sql   Empresas de transporte sincronizadas desde SAP
    06_productores_sap_bp.sql   Productores sincronizados desde SAP Business Partners
  ops/
    (migraciones incrementales ordenadas por fecha)
```

### Roles y permisos predefinidos

| Rol | Cantidad de permisos | Alcance |
| --- | --- | --- |
| Administrador | 33 (todos) | Acceso total al sistema |
| Autorizador | 27 | Operaciones de fletes, facturacion y mantenedores parciales |
| Ingresador | 11 | Ingreso de fletes, lectura de facturas, planillas y mantenedores |

Los usuarios seed y sus asignaciones de roles se definen en `seed/04_seguridad.sql` utilizando sentencias MERGE para garantizar idempotencia.

## Deploy

### Deploy automatico (produccion)

El deploy a produccion se ejecuta automaticamente al hacer merge a `main` en GitHub:

1. GitHub envia un webhook a `http://<IP>/webhook/github`
2. El servicio `greenvic-deployer` (en la plataforma) valida la firma HMAC del payload
3. Ejecuta `git pull` en el repositorio afectado dentro de `/opt/cfl/prd/`
4. Reconstruye y reinicia el servicio Docker correspondiente
5. Ejecuta smoke tests (health checks) para verificar disponibilidad

La configuracion del webhook se encuentra en `platform/deployer/deploy-config.json`.

### Deploy manual

```bash
cd /opt/cfl/prd/cfl-infra
make deploy      # git pull + build + up (valida que el branch sea el esperado)
make redeploy    # down + build + up (reconstruccion completa)
```

## Makefile

### Operaciones principales

| Target | Descripcion |
| --- | --- |
| `up` | Levanta el stack Docker |
| `up-build` | Levanta el stack reconstruyendo imagenes |
| `down` | Detiene y elimina contenedores |
| `down-v` | Detiene y elimina contenedores junto con volumenes |
| `stop` / `start` / `restart` | Control de contenedores sin eliminarlos |

### Build

| Target | Descripcion |
| --- | --- |
| `build-cfl-front` | Construye imagen del frontend |
| `build-cfl-back` | Construye imagen del backend |
| `build-all` | Construye todas las imagenes |
| `rebuild` | Reconstruye sin cache |

### Deploy

| Target | Descripcion |
| --- | --- |
| `deploy` | Pull de codigo + build + up (valida branch) |
| `redeploy` | Down + build + up (reconstruccion completa) |
| `pull` | Git pull en todos los repositorios |

### Monitoreo y diagnostico

| Target | Descripcion |
| --- | --- |
| `ps` / `status` | Estado de los contenedores |
| `logs` | Logs de todos los servicios |
| `logs-cfl-front` | Logs del frontend |
| `logs-cfl-back` | Logs del backend |
| `doctor` | Verificacion completa del entorno (Docker, redes, archivos, branches) |
| `env-info` | Muestra el ambiente actual y configuracion |

### Infraestructura

| Target | Descripcion |
| --- | --- |
| `images` | Lista imagenes Docker del proyecto |
| `volumes` | Lista volumenes Docker del proyecto |
| `networks` | Lista redes Docker del proyecto |
| `prune-soft` | Limpieza de recursos Docker no utilizados |
| `prune` | Limpieza agresiva de recursos Docker |
| `config` | Muestra la configuracion Docker Compose resultante |
| `exec-cfl-front` / `exec-cfl-back` | Shell interactivo en contenedores |

## Verificacion del entorno

```bash
make doctor
```

El target `doctor` ejecuta una verificacion completa que incluye: disponibilidad de Docker, existencia de redes externas, presencia del archivo `.env`, estado de los repositorios y branch actual.

### Health checks manuales

```bash
curl http://127.0.0.1/healthz       # Frontend (produccion, via proxy)
curl http://127.0.0.1/api/health    # Backend (produccion, via proxy)
curl http://localhost:3000/healthz   # Frontend (local)
curl http://localhost:4000/health    # Backend (local)
```
