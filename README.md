# cfl-infra

Infraestructura local para desarrollo.

## SQL Server (dev)

1. Copiar `.env.example` a `.env`
2. Cambiar `MSSQL_SA_PASSWORD` por una password fuerte
3. Levantar:

```bash
docker compose up -d
```

Servidor en `localhost,1433`.

Conexion ejemplo:
- Server: `localhost,1433`
- User: `sa`
- Password: la definida en `.env`

`database/` queda reservado para scripts o respaldos de BD.
La conexion con tu BD empresarial se configurara en el siguiente paso.
