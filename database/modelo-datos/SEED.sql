/* ============================================================================
   SEED MASTER - CFL
   Rol: orquestar la carga de datos iniciales por capas.

   Orden de ejecucion:
   1) Catalogos base
   2) Logistica y tarifas
   3) Maestros de transporte
   4) Seguridad (roles, usuarios, permisos)
   5) Folios base

   Nota:
   - Este archivo se ejecuta con sqlcmd desde init-db.sh.
   - Los scripts incluidos son idempotentes (MERGE).
============================================================================ */

:r seed/01_catalogos_base.sql
GO
:r seed/02_logistica_tarifas.sql
GO
:r seed/03_transporte.sql
GO
:r seed/04_seguridad.sql
GO
