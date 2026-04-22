-- =============================================================
-- Prepara cfl.EmpresaTransporte para sincronizacion directa
-- desde SAP RFC YWT_CDTB24:
--   - Rut pasa a NULL (la tabla SAP no lo provee).
--   - SapCodigo se amplia a NVARCHAR(10) (origen es CHAR(6)).
--   - UNIQUE en Rut se reconvierte a filtrado (NOT NULL) para
--     permitir coexistencia con nuevas filas sin RUT.
--   - Nuevo UNIQUE filtrado en SapCodigo: es la clave natural
--     usada para dedup y MERGE desde SAP.
-- =============================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- 1) Eliminar UNIQUE sin filtrar sobre Rut (bloquea nullables).
IF EXISTS (
  SELECT 1 FROM sys.indexes
  WHERE name = 'UQ_EmpresaTransporte_Rut'
    AND object_id = OBJECT_ID('cfl.EmpresaTransporte')
    AND has_filter = 0
)
BEGIN
  DROP INDEX [UQ_EmpresaTransporte_Rut] ON [cfl].[EmpresaTransporte];
END
GO

-- 2) Rut pasa a nullable.
IF EXISTS (
  SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = 'cfl' AND TABLE_NAME = 'EmpresaTransporte'
    AND COLUMN_NAME = 'Rut' AND IS_NULLABLE = 'NO'
)
BEGIN
  ALTER TABLE [cfl].[EmpresaTransporte]
    ALTER COLUMN [Rut] NVARCHAR(20) NULL;
END
GO

-- 3) Ampliar SapCodigo CHAR(3) -> NVARCHAR(10).
IF EXISTS (
  SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = 'cfl' AND TABLE_NAME = 'EmpresaTransporte'
    AND COLUMN_NAME = 'SapCodigo'
    AND (DATA_TYPE <> 'nvarchar' OR ISNULL(CHARACTER_MAXIMUM_LENGTH, 0) < 10)
)
BEGIN
  ALTER TABLE [cfl].[EmpresaTransporte]
    ALTER COLUMN [SapCodigo] NVARCHAR(10) NULL;
END
GO

-- 4) UNIQUE filtrado sobre Rut (acepta múltiples NULL).
IF NOT EXISTS (
  SELECT 1 FROM sys.indexes
  WHERE name = 'UQ_EmpresaTransporte_Rut'
    AND object_id = OBJECT_ID('cfl.EmpresaTransporte')
)
BEGIN
  CREATE UNIQUE INDEX [UQ_EmpresaTransporte_Rut]
    ON [cfl].[EmpresaTransporte] ([Rut])
    WHERE [Rut] IS NOT NULL;
END
GO

-- 5) UNIQUE filtrado sobre SapCodigo (clave natural del sync SAP).
IF NOT EXISTS (
  SELECT 1 FROM sys.indexes
  WHERE name = 'UQ_EmpresaTransporte_SapCodigo'
    AND object_id = OBJECT_ID('cfl.EmpresaTransporte')
)
BEGIN
  CREATE UNIQUE INDEX [UQ_EmpresaTransporte_SapCodigo]
    ON [cfl].[EmpresaTransporte] ([SapCodigo])
    WHERE [SapCodigo] IS NOT NULL;
END
GO
