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

## Nota de BD empresarial

Por ahora `back` queda conectado al `sqlserver` local del compose.
En el siguiente paso ajustamos variables y red para tu BD SQL Server empresarial.

## Carpeta database

`database/` queda reservada para scripts SQL, respaldos o inicializacion de datos.
