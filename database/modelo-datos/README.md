# Modelo de Datos CFL

## Scripts core

- `UP.sql`: crea esquema `cfl`, tablas, indices, FKs, vistas y funciones.
- `DOWN.sql`: elimina por completo el esquema `cfl` (destructivo).
- `SEED.sql`: orquestador de seed por modulos.
- `seed/01_catalogos_base.sql`: temporadas, centros, cuentas, detalles, especies, tipos de flete/camion.
- `seed/02_logistica_tarifas.sql`: nodos, rutas y tarifas.
- `seed/03_transporte.sql`: empresas, choferes, camiones, moviles.
- `seed/04_seguridad.sql`: roles, usuarios, permisos y relaciones.
- `seed/05_folios.sql`: folios base.

## Scripts operativos

- `ops/PURGE_DATA.sql`: purga de datos en tablas `cfl` (mantiene estructura).
- `ops/CAMIONES.sql`: carga camiones desde tablas SAP raw (uso puntual).
- `ops/CHOFERES.sql`: carga choferes desde tablas SAP raw (uso puntual).
- `ops/PATCH_*.sql`: parches legacy/manuales.

## Orden recomendado

1. `UP.sql`
2. `SEED.sql`
3. Scripts de `ops/` solo cuando aplique.

## Nota de seed de transporte

El seed modular incluye carga estable de:
- camiones/patentes
- choferes
- rutas
- tarifas

Esto evita depender de `CFL_sap_likp_raw` para recuperar estos datos luego de un `DOWN + UP + SEED`.
