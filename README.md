# cfl-infra

Infraestructura local para desarrollo.

## Levantar todo desde infra

1. Copiar `.env.example` a `.env`
2. Cambiar `MSSQL_SA_PASSWORD` por una password fuerte
3. Desde esta carpeta, levantar todo:

```bash
docker compose up -d
```

Esto levanta:
- `front` en `http://localhost:3000`
- `back` en `http://localhost:4000`
- `sqlserver` en `localhost,1433`

## Comandos rapidos

Ejecutar todo desde `cfl-infra` (PowerShell):

```powershell
Copy-Item .env.example .env
docker compose build sqlserver
docker compose up -d
docker compose logs -f sqlserver
```

Reinicializar modelo de datos desde cero (borra datos del volumen):

```powershell
docker compose down -v
docker compose up -d --build
```

## Inicializacion automatica del modelo de datos

Al iniciar `sqlserver`, el contenedor ejecuta automaticamente:
- `database/modelo-datos/UP.sql`
- `database/modelo-datos/SEED.sql`

Esto ocurre solo la primera vez por volumen, usando el marcador:
- `/var/opt/mssql/.cfl_model_initialized`

Si necesitas volver a ejecutar inicializacion desde cero, elimina el volumen local:

```bash
docker compose down -v
```

## Nota de BD empresarial

Por ahora `back` queda conectado al `sqlserver` local del compose.
En el siguiente paso ajustamos variables y red para tu BD SQL Server empresarial.

## Carpeta database

`database/` queda reservada para scripts SQL, respaldos o inicializacion de datos.
