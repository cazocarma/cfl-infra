-- =============================================================
-- Prepara cfl.Chofer para sincronizacion directa desde SAP RFC
-- YWTRM_TB_CONDUCT (CONDUCTOR CHAR(24) / FONO_CONDUCTOR CHAR(30)).
--
--   - SapIdFiscal pasa a NVARCHAR(24): acepta el ancho original
--     de SAP sin truncar RUTs extendidos / choferes extranjeros.
--   - Telefono pasa a NVARCHAR(30): acepta el ancho original
--     del fono SAP.
--   - Nueva columna PERSISTED SapIdFiscalNorm: misma informacion
--     sin puntos/guiones/espacios en mayuscula. Sirve exclusiva-
--     mente para busquedas tolerantes; el literal SapIdFiscal se
--     mantiene tal cual SAP lo entrega (principio "SAP es fuente
--     de verdad" para match con fletes/romana).
--   - Indice sobre SapIdFiscalNorm para busquedas eficientes.
-- =============================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- 1) Eliminar UNIQUE existente para poder ampliar el ancho.
IF EXISTS (
  SELECT 1 FROM sys.indexes
  WHERE name = 'UQ_Chofer_SapIdFiscal'
    AND object_id = OBJECT_ID('cfl.Chofer')
)
BEGIN
  DROP INDEX [UQ_Chofer_SapIdFiscal] ON [cfl].[Chofer];
END
GO

-- 2) Ampliar SapIdFiscal NVARCHAR(20) -> NVARCHAR(24).
IF EXISTS (
  SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = 'cfl' AND TABLE_NAME = 'Chofer'
    AND COLUMN_NAME = 'SapIdFiscal'
    AND (DATA_TYPE <> 'nvarchar' OR ISNULL(CHARACTER_MAXIMUM_LENGTH, 0) < 24)
)
BEGIN
  ALTER TABLE [cfl].[Chofer]
    ALTER COLUMN [SapIdFiscal] NVARCHAR(24) NOT NULL;
END
GO

-- 3) Ampliar Telefono NVARCHAR(20) -> NVARCHAR(30).
IF EXISTS (
  SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = 'cfl' AND TABLE_NAME = 'Chofer'
    AND COLUMN_NAME = 'Telefono'
    AND (DATA_TYPE <> 'nvarchar' OR ISNULL(CHARACTER_MAXIMUM_LENGTH, 0) < 30)
)
BEGIN
  ALTER TABLE [cfl].[Chofer]
    ALTER COLUMN [Telefono] NVARCHAR(30) NULL;
END
GO

-- 4) Recrear UNIQUE sobre SapIdFiscal.
IF NOT EXISTS (
  SELECT 1 FROM sys.indexes
  WHERE name = 'UQ_Chofer_SapIdFiscal'
    AND object_id = OBJECT_ID('cfl.Chofer')
)
BEGIN
  CREATE UNIQUE INDEX [UQ_Chofer_SapIdFiscal]
    ON [cfl].[Chofer] ([SapIdFiscal]);
END
GO

-- 5) Columna computed PERSISTED para busqueda tolerante.
-- Se envuelve en CAST(... AS NVARCHAR(24)) para que el indice
-- tenga key de tamaño acotado (sin CAST, SQL Server infiere
-- NVARCHAR(4000) y lanza Warning por exceder 1700 bytes).
-- Si la columna existe sin CAST (max_length distinto de 48), la
-- re-crea acotada para corregir instalaciones previas.
IF EXISTS (
  SELECT 1 FROM sys.columns
  WHERE object_id = OBJECT_ID('cfl.Chofer')
    AND name = 'SapIdFiscalNorm'
    AND max_length <> 48
)
BEGIN
  IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Chofer_SapIdFiscalNorm'
      AND object_id = OBJECT_ID('cfl.Chofer')
  )
  BEGIN
    DROP INDEX [IX_Chofer_SapIdFiscalNorm] ON [cfl].[Chofer];
  END
  ALTER TABLE [cfl].[Chofer] DROP COLUMN [SapIdFiscalNorm];
END
GO

IF NOT EXISTS (
  SELECT 1 FROM sys.columns
  WHERE object_id = OBJECT_ID('cfl.Chofer')
    AND name = 'SapIdFiscalNorm'
)
BEGIN
  ALTER TABLE [cfl].[Chofer]
    ADD [SapIdFiscalNorm] AS (
      CAST(
        UPPER(
          REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
            ISNULL([SapIdFiscal], ''),
            '.', ''), '-', ''), ' ', ''),
            CHAR(9), ''), CHAR(10), '')
        ) AS NVARCHAR(24)
      )
    ) PERSISTED;
END
GO

-- 6) Indice sobre SapIdFiscalNorm.
IF NOT EXISTS (
  SELECT 1 FROM sys.indexes
  WHERE name = 'IX_Chofer_SapIdFiscalNorm'
    AND object_id = OBJECT_ID('cfl.Chofer')
)
BEGIN
  CREATE INDEX [IX_Chofer_SapIdFiscalNorm]
    ON [cfl].[Chofer] ([SapIdFiscalNorm]);
END
GO
