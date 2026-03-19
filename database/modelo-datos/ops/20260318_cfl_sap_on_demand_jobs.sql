/* ============================================================================
   PATCH 20260318 - CFL SAP on-demand jobs
   Objetivo:
   - extender cfl.EtlEjecucion para tracking de jobs on-demand backend
   - agregar permisos de ejecutar/ver cargas SAP on-demand
   Idempotente: SI
============================================================================ */
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

IF COL_LENGTH('cfl.EtlEjecucion', 'TipoProceso') IS NULL
BEGIN
  ALTER TABLE [cfl].[EtlEjecucion] ADD [TipoProceso] NVARCHAR(50) NULL;
END;

IF COL_LENGTH('cfl.EtlEjecucion', 'ParametrosJson') IS NULL
BEGIN
  ALTER TABLE [cfl].[EtlEjecucion] ADD [ParametrosJson] NVARCHAR(MAX) NULL;
END;

IF COL_LENGTH('cfl.EtlEjecucion', 'ResumenJson') IS NULL
BEGIN
  ALTER TABLE [cfl].[EtlEjecucion] ADD [ResumenJson] NVARCHAR(MAX) NULL;
END;

IF COL_LENGTH('cfl.EtlEjecucion', 'FechaInicioProceso') IS NULL
BEGIN
  ALTER TABLE [cfl].[EtlEjecucion] ADD [FechaInicioProceso] DATETIME2(0) NULL;
END;

IF COL_LENGTH('cfl.EtlEjecucion', 'FechaFinProceso') IS NULL
BEGIN
  ALTER TABLE [cfl].[EtlEjecucion] ADD [FechaFinProceso] DATETIME2(0) NULL;
END;

IF NOT EXISTS (
  SELECT 1
  FROM sys.indexes
  WHERE name = 'IX_EtlEjecucion_TipoProcesoEstadoFecha'
    AND object_id = OBJECT_ID('cfl.EtlEjecucion')
)
BEGIN
  CREATE INDEX [IX_EtlEjecucion_TipoProcesoEstadoFecha]
  ON [cfl].[EtlEjecucion] ([TipoProceso], [Estado], [FechaCreacion] DESC);
END;

;WITH src(recurso, accion, clave, descripcion, activo) AS (
  SELECT *
  FROM (VALUES
    (N'fletes', N'execute_sap_load', N'fletes.sap.etl.ejecutar', N'Ejecutar cargas SAP on-demand de control de fletes', 1),
    (N'fletes', N'view_sap_load_jobs', N'fletes.sap.etl.ver', N'Consultar jobs de cargas SAP on-demand', 1)
  ) v(recurso, accion, clave, descripcion, activo)
)
MERGE cfl.Permiso AS t
USING src AS s
ON t.clave = s.clave
WHEN MATCHED THEN
  UPDATE SET
    t.recurso = s.recurso,
    t.accion = s.accion,
    t.descripcion = s.descripcion,
    t.activo = CAST(s.activo AS BIT)
WHEN NOT MATCHED THEN
  INSERT (recurso, accion, clave, descripcion, activo)
  VALUES (s.recurso, s.accion, s.clave, s.descripcion, CAST(s.activo AS BIT));

;WITH src(rol_nombre, permiso_clave) AS (
  SELECT *
  FROM (VALUES
    (N'Administrador', N'fletes.sap.etl.ejecutar'),
    (N'Administrador', N'fletes.sap.etl.ver'),
    (N'Autorizador', N'fletes.sap.etl.ejecutar'),
    (N'Autorizador', N'fletes.sap.etl.ver'),
    (N'Ingresador', N'fletes.sap.etl.ejecutar'),
    (N'Ingresador', N'fletes.sap.etl.ver')
  ) v(rol_nombre, permiso_clave)
), resolved AS (
  SELECT r.IdRol, p.IdPermiso
  FROM src s
  INNER JOIN cfl.Rol r ON r.nombre = s.rol_nombre
  INNER JOIN cfl.Permiso p ON p.clave = s.permiso_clave
)
MERGE cfl.RolPermiso AS t
USING resolved AS s
ON t.IdRol = s.IdRol
AND t.IdPermiso = s.IdPermiso
WHEN NOT MATCHED THEN
  INSERT (IdRol, IdPermiso)
  VALUES (s.IdRol, s.IdPermiso);

COMMIT TRANSACTION;
