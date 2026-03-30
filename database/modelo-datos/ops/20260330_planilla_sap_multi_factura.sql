/*
   PATCH: Planilla SAP multi-factura
   Fecha: 2026-03-30
   Descripcion:
     - Crea tabla puente PlanillaSapFactura (N:N planilla <-> factura)
     - Migra datos existentes de PlanillaSap.IdFactura a la tabla puente
     - Elimina PlanillaSap.IdFactura (columna, FK e indice)
     - Agrega PlanillaSap.Referencia
*/

-- 1. Crear tabla PlanillaSapFactura si no existe
IF NOT EXISTS (
  SELECT 1 FROM INFORMATION_SCHEMA.TABLES
  WHERE TABLE_SCHEMA = 'cfl' AND TABLE_NAME = 'PlanillaSapFactura'
)
BEGIN
  CREATE TABLE [cfl].[PlanillaSapFactura] (
      [IdPlanillaSapFactura]  BIGINT NOT NULL IDENTITY UNIQUE,
      [IdPlanillaSap]         BIGINT NOT NULL,
      [IdFactura]             BIGINT NOT NULL,
      PRIMARY KEY ([IdPlanillaSapFactura])
  );

  CREATE UNIQUE INDEX [UQ_PlanillaSapFactura]
  ON [cfl].[PlanillaSapFactura] ([IdPlanillaSap], [IdFactura]);

  ALTER TABLE [cfl].[PlanillaSapFactura]
  ADD CONSTRAINT [FK_PlanillaSapFactura_PlanillaSap]
  FOREIGN KEY ([IdPlanillaSap]) REFERENCES [cfl].[PlanillaSap] ([IdPlanillaSap])
  ON UPDATE NO ACTION ON DELETE NO ACTION;

  ALTER TABLE [cfl].[PlanillaSapFactura]
  ADD CONSTRAINT [FK_PlanillaSapFactura_CabeceraFactura]
  FOREIGN KEY ([IdFactura]) REFERENCES [cfl].[CabeceraFactura] ([IdFactura])
  ON UPDATE NO ACTION ON DELETE NO ACTION;

  PRINT 'Tabla PlanillaSapFactura creada.';
END
ELSE
  PRINT 'Tabla PlanillaSapFactura ya existe, omitiendo.';
GO

-- 2. Migrar datos existentes de PlanillaSap.IdFactura a PlanillaSapFactura
IF EXISTS (
  SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = 'cfl' AND TABLE_NAME = 'PlanillaSap'
    AND COLUMN_NAME = 'IdFactura'
)
BEGIN
  INSERT INTO [cfl].[PlanillaSapFactura] ([IdPlanillaSap], [IdFactura])
  SELECT p.IdPlanillaSap, p.IdFactura
  FROM [cfl].[PlanillaSap] p
  WHERE p.IdFactura IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM [cfl].[PlanillaSapFactura] psf
      WHERE psf.IdPlanillaSap = p.IdPlanillaSap
        AND psf.IdFactura = p.IdFactura
    );

  PRINT CONCAT('Migrados ', @@ROWCOUNT, ' registros a PlanillaSapFactura.');
END
GO

-- 3. Eliminar FK, indice y columna IdFactura de PlanillaSap
IF EXISTS (
  SELECT 1 FROM sys.foreign_keys
  WHERE name = 'FK_PlanillaSap_CabeceraFactura'
)
BEGIN
  ALTER TABLE [cfl].[PlanillaSap] DROP CONSTRAINT [FK_PlanillaSap_CabeceraFactura];
  PRINT 'FK FK_PlanillaSap_CabeceraFactura eliminada.';
END
GO

IF EXISTS (
  SELECT 1 FROM sys.indexes
  WHERE name = 'IX_PlanillaSap_IdFactura'
    AND object_id = OBJECT_ID('[cfl].[PlanillaSap]')
)
BEGIN
  DROP INDEX [IX_PlanillaSap_IdFactura] ON [cfl].[PlanillaSap];
  PRINT 'Indice IX_PlanillaSap_IdFactura eliminado.';
END
GO

IF EXISTS (
  SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = 'cfl' AND TABLE_NAME = 'PlanillaSap'
    AND COLUMN_NAME = 'IdFactura'
)
BEGIN
  ALTER TABLE [cfl].[PlanillaSap] DROP COLUMN [IdFactura];
  PRINT 'Columna PlanillaSap.IdFactura eliminada.';
END
GO

-- 4. Eliminar columna Referencia de PlanillaSap si existe (campo movido a CabeceraFactura)
IF EXISTS (
  SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = 'cfl' AND TABLE_NAME = 'PlanillaSap'
    AND COLUMN_NAME = 'Referencia'
)
BEGIN
  ALTER TABLE [cfl].[PlanillaSap] DROP COLUMN [Referencia];
  PRINT 'Columna PlanillaSap.Referencia eliminada (derivada de CabeceraFactura.NumeroFacturaRecibida).';
END
GO

-- 5. Eliminar IdCentroCosto de PlanillaSapDocumento
IF EXISTS (
  SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = 'cfl' AND TABLE_NAME = 'PlanillaSapDocumento'
    AND COLUMN_NAME = 'IdCentroCosto'
)
BEGIN
  ALTER TABLE [cfl].[PlanillaSapDocumento] DROP COLUMN [IdCentroCosto];
  PRINT 'Columna PlanillaSapDocumento.IdCentroCosto eliminada.';
END
GO

-- 6. Eliminar IdCuentaMayor de PlanillaSapDocumento
IF EXISTS (
  SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = 'cfl' AND TABLE_NAME = 'PlanillaSapDocumento'
    AND COLUMN_NAME = 'IdCuentaMayor'
)
BEGIN
  ALTER TABLE [cfl].[PlanillaSapDocumento] DROP COLUMN [IdCuentaMayor];
  PRINT 'Columna PlanillaSapDocumento.IdCuentaMayor eliminada.';
END
GO

-- 7. Agregar Referencia a PlanillaSapDocumento
IF NOT EXISTS (
  SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = 'cfl' AND TABLE_NAME = 'PlanillaSapDocumento'
    AND COLUMN_NAME = 'Referencia'
)
BEGIN
  ALTER TABLE [cfl].[PlanillaSapDocumento]
    ADD [Referencia] NVARCHAR(60) NULL;
  PRINT 'Columna Referencia agregada a PlanillaSapDocumento.';
END
GO

-- 8. Agregar NumeroPreFactura a PlanillaSapDocumento
IF NOT EXISTS (
  SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = 'cfl' AND TABLE_NAME = 'PlanillaSapDocumento'
    AND COLUMN_NAME = 'NumeroPreFactura'
)
BEGIN
  ALTER TABLE [cfl].[PlanillaSapDocumento]
    ADD [NumeroPreFactura] NVARCHAR(40) NULL;
  PRINT 'Columna NumeroPreFactura agregada a PlanillaSapDocumento.';
END
GO
