# cfl-infra

Orquestacion Docker Compose para el sistema de Control de Fletes (CFL) de Greenvic.

## Arquitectura multi-ambiente

El proyecto soporta dos ambientes simultaneos en el mismo servidor:

| Aspecto | PRD (produccion) | DEV (desarrollo) |
|---|---|---|
| Branch | `main` | `dev` |
| Compose project | `greenvic-cfl-prd` | `greenvic-cfl-dev` |
| Red Docker | `greenvic-cfl-prd_default` | `greenvic-cfl-dev_default` |
| Backend alias | `cfl-backend` | `cfl-backend-dev` |
| Frontend alias | `cfl-frontend` | `cfl-frontend-dev` |
| Puerto platform | 80 | 83 |
| Acceso | `http://<IP>` | `http://<IP>:83` |

Cada ambiente corre desde su propio directorio:

```
/opt/cfl/
├── prd/repos/          ← branch main, .env con CFL_ENV=prd
│   ├── cfl-infra/      ← este repo (Makefile, docker-compose, .env)
│   ├── cfl-back/
│   └── cfl-front-ng/
└── dev/repos/          ← branch dev, .env con CFL_ENV=dev
    ├── cfl-infra/
    ├── cfl-back/
    └── cfl-front-ng/
```

## Requisitos previos

- Docker y Docker Compose
- Stack **greenvic-platform** levantado (provee las redes `greenvic-cfl-{prd|dev}_default` y `platform_identity`)
- Repos clonados en la estructura de directorios descrita arriba

## Setup inicial

### 1. Clonar repos

```bash
# PRD
mkdir -p /opt/cfl/prd/repos && cd /opt/cfl/prd/repos
git clone -b main <url>/cfl-infra.git
git clone -b main <url>/cfl-back.git
git clone -b main <url>/cfl-front-ng.git

# DEV
mkdir -p /opt/cfl/dev/repos && cd /opt/cfl/dev/repos
git clone -b dev <url>/cfl-infra.git
git clone -b dev <url>/cfl-back.git
git clone -b dev <url>/cfl-front-ng.git
```

### 2. Configurar variables de entorno

```bash
cd /opt/cfl/prd/repos/cfl-infra
make setup-env ENV=prd
# Edita .env con los valores reales (secretos, passwords, IPs)

cd /opt/cfl/dev/repos/cfl-infra
make setup-env ENV=dev
# Edita .env con los valores de desarrollo
```

### 3. Verificar prerequisitos

```bash
make doctor
```

Valida: Docker, .env, repos, redes Docker, y branches.

### 4. Levantar

```bash
make up          # Levanta el stack
make up-build    # Levanta reconstruyendo imagenes
```

## Fuente de entorno

- Archivo real: `cfl-infra/.env` (gitignoreado)
- Plantillas: `.env.prd.example`, `.env.dev.example`
- `cfl-back` consume este archivo; no usa `.env` propio

## Variable `CFL_ENV`

La variable `CFL_ENV` en `.env` controla todo el aislamiento:

- **Compose project name**: `greenvic-cfl-${CFL_ENV}`
- **Redes Docker**: `greenvic-cfl-${CFL_ENV}_default`
- **Imagen frontend**: `cfl-front-ng:${CFL_ENV}`
- **Volumenes**: auto-prefijados por compose project name

Valores permitidos: `prd`, `dev`.

## Arquitectura de red

El stack CFL se conecta a redes externas gestionadas por `greenvic-platform`:

| Red | Tipo | Proposito |
|---|---|---|
| `greenvic-cfl-{env}_default` | externa | Red principal del stack CFL |
| `platform_identity` | externa | Comunicacion con Keycloak (authn/authz) |
| `greenvic-cfl-{env}_egress` | interna | Salida controlada a servicios externos |

> El gateway (NGINX) fue delegado a `greenvic-platform`. CFL no levanta su propio reverse proxy.

## Operacion diaria

```bash
make ps          # Estado de contenedores
make logs        # Logs de todo el stack
make logs-cfl-front   # Logs solo del frontend
make logs-cfl-back    # Logs solo del backend
make restart     # Reinicia todo
make env-info    # Muestra ambiente, red y branches actuales
```

## Deploy

```bash
make deploy      # git pull + build + up (valida branch)
make redeploy    # down + build + up (valida branch)
```

El Makefile valida automaticamente que las ramas de los repos coincidan con `CFL_ENV` antes de hacer deploy.

## Release: merge dev a main

1. Verificar que DEV funciona correctamente en `http://<IP>:83`
2. En cada repo, mergear `dev` a `main`:
   ```bash
   cd /opt/cfl/dev/repos/cfl-back
   git checkout main && git merge dev && git push

   cd /opt/cfl/dev/repos/cfl-front-ng
   git checkout main && git merge dev && git push

   cd /opt/cfl/dev/repos/cfl-infra
   git checkout main && git merge dev && git push
   ```
3. Desplegar en PRD:
   ```bash
   cd /opt/cfl/prd/repos/cfl-infra
   make deploy
   ```

Los merges son limpios porque todos los archivos committeados son identicos entre ramas. Las diferencias viven solo en `.env` (gitignoreado).

## Servicios

| Servicio | Puerto | Descripcion |
|---|---|---|
| `front-ng` | 3000 | Frontend Angular CFL |
| `back` | 4000 | Backend Node (perfil `node`) |

## Targets del Makefile

| Target | Descripcion |
|---|---|
| `setup-env ENV=prd\|dev` | Copia .env.{ENV}.example a .env |
| `env-check` | Verifica que .env existe |
| `repo-check` | Verifica que los repos existen |
| `net-check` | Verifica que las redes Docker existen |
| `branch-check` | Verifica que las ramas coincidan con CFL_ENV |
| `doctor` | Verificacion completa del entorno |
| `env-info` | Muestra ambiente, red y branches |
| `build-cfl-front` | Build de cfl-front-ng |
| `build-cfl-back` | Build de cfl-back |
| `build-all` | Build de todas las imagenes |
| `rebuild` | Rebuild sin cache |
| `up` | Levanta el stack |
| `up-build` | Levanta reconstruyendo |
| `down` | Baja el stack |
| `down-v` | Baja el stack y elimina volumenes |
| `stop` / `start` | Detiene / inicia servicios |
| `restart` | Reinicia todo |
| `ps` / `status` | Estado de contenedores |
| `logs` | Logs de todo el stack |
| `logs-cfl-front` / `logs-cfl-back` | Logs por servicio |
| `config` | Render de docker compose |
| `pull` | Git pull en los 3 repos |
| `deploy` | Pull + build + up |
| `redeploy` | Down + build + up |

## Validacion rapida

```bash
make doctor
make env-info
curl http://127.0.0.1/healthz       # cfl-front-ng via platform gateway (PRD)
curl http://127.0.0.1:83/healthz    # cfl-front-ng via platform gateway (DEV)
curl http://127.0.0.1/api/health    # cfl-back via platform gateway (PRD)
```

## Troubleshooting

### "La red greenvic-cfl-prd_default no existe"

Platform debe estar corriendo antes que CFL. Las redes las crea el stack platform:

```bash
cd /opt/platform && docker compose up -d
```

### "WARNING: repo esta en branch 'dev' (esperado 'main')"

El branch del repo no coincide con `CFL_ENV`. Cambia al branch correcto:

```bash
cd <repo> && git checkout main   # para CFL_ENV=prd
cd <repo> && git checkout dev    # para CFL_ENV=dev
```

### Contenedores no aparecen

Verifica que el .env tenga `CFL_ENV` definido:

```bash
make env-info
```
