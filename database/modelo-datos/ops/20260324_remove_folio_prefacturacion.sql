/*
 * Migración: Eliminación del concepto de Folio + nuevo flujo de prefacturación
 * Fecha: 2026-03-24
 *
 * Cambios:
 *   1. Migrar fletes ASIGNADO_FOLIO → COMPLETADO
 *   2. Eliminar columna IdFolio de CabeceraFlete (FK + index + columna)
 *   3. Eliminar tabla FacturaFolio (bridge factura↔folio)
 *   4. Eliminar tabla Folio
 *   5. Eliminar columnas IdFolio y FolioNumero de PlanillaSapDocumento
 *   6. Crear nuevo index para queries de movimientos elegibles
 */

-- ============================================================
-- 1. Migrar datos existentes
-- ============================================================

-- Fletes en ASIGNADO_FOLIO → COMPLETADO (ya no existe ese estado)
UPDATE [cfl].[CabeceraFlete]
SET [Estado] = 'COMPLETADO',
    [FechaActualizacion] = GETDATE()
WHERE UPPER([Estado]) = 'ASIGNADO_FOLIO';
GO

-- Nullificar IdFolio en todos los fletes antes de eliminar la columna
UPDATE [cfl].[CabeceraFlete]
SET [IdFolio] = NULL
WHERE [IdFolio] IS NOT NULL;
GO

-- ============================================================
-- 2. Eliminar columna IdFolio de CabeceraFlete
-- ============================================================

-- Drop FK CabeceraFlete → Folio
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_CabeceraFlete_Folio')
BEGIN
    ALTER TABLE [cfl].[CabeceraFlete] DROP CONSTRAINT [FK_CabeceraFlete_Folio];
END
GO

-- Drop index IX_CabeceraFlete_FolioEstado
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CabeceraFlete_FolioEstado' AND object_id = OBJECT_ID('[cfl].[CabeceraFlete]'))
BEGIN
    DROP INDEX [IX_CabeceraFlete_FolioEstado] ON [cfl].[CabeceraFlete];
END
GO

-- Drop columna IdFolio
IF EXISTS (SELECT 1 FROM sys.columns WHERE name = 'IdFolio' AND object_id = OBJECT_ID('[cfl].[CabeceraFlete]'))
BEGIN
    ALTER TABLE [cfl].[CabeceraFlete] DROP COLUMN [IdFolio];
END
GO

-- ============================================================
-- 3. Eliminar tabla FacturaFolio (bridge factura↔folio)
-- ============================================================

-- Drop FKs de FacturaFolio
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_FacturaFolio_CabeceraFactura')
BEGIN
    ALTER TABLE [cfl].[FacturaFolio] DROP CONSTRAINT [FK_FacturaFolio_CabeceraFactura];
END
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_FacturaFolio_Folio')
BEGIN
    ALTER TABLE [cfl].[FacturaFolio] DROP CONSTRAINT [FK_FacturaFolio_Folio];
END
GO

-- Drop unique index
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_FacturaFolio_FacturaFolio' AND object_id = OBJECT_ID('[cfl].[FacturaFolio]'))
BEGIN
    DROP INDEX [UQ_FacturaFolio_FacturaFolio] ON [cfl].[FacturaFolio];
END
GO

-- Drop tabla
IF OBJECT_ID('[cfl].[FacturaFolio]', 'U') IS NOT NULL
BEGIN
    DROP TABLE [cfl].[FacturaFolio];
END
GO

-- ============================================================
-- 4. Eliminar tabla Folio
-- ============================================================

-- Drop FKs de Folio
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Folio_CentroCosto')
BEGIN
    ALTER TABLE [cfl].[Folio] DROP CONSTRAINT [FK_Folio_CentroCosto];
END
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Folio_CuentaMayor')
BEGIN
    ALTER TABLE [cfl].[Folio] DROP CONSTRAINT [FK_Folio_CuentaMayor];
END
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Folio_Temporada')
BEGIN
    ALTER TABLE [cfl].[Folio] DROP CONSTRAINT [FK_Folio_Temporada];
END
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Folio_UsuarioCierre')
BEGIN
    ALTER TABLE [cfl].[Folio] DROP CONSTRAINT [FK_Folio_UsuarioCierre];
END
GO

-- Drop unique index
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_Folio_TemporadaCcCuenta' AND object_id = OBJECT_ID('[cfl].[Folio]'))
BEGIN
    DROP INDEX [UQ_Folio_TemporadaCcCuenta] ON [cfl].[Folio];
END
GO

-- Drop tabla
IF OBJECT_ID('[cfl].[Folio]', 'U') IS NOT NULL
BEGIN
    DROP TABLE [cfl].[Folio];
END
GO

-- ============================================================
-- 5. Eliminar columnas IdFolio y FolioNumero de PlanillaSapDocumento
-- ============================================================

IF EXISTS (SELECT 1 FROM sys.columns WHERE name = 'IdFolio' AND object_id = OBJECT_ID('[cfl].[PlanillaSapDocumento]'))
BEGIN
    ALTER TABLE [cfl].[PlanillaSapDocumento] DROP COLUMN [IdFolio];
END
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE name = 'FolioNumero' AND object_id = OBJECT_ID('[cfl].[PlanillaSapDocumento]'))
BEGIN
    ALTER TABLE [cfl].[PlanillaSapDocumento] DROP COLUMN [FolioNumero];
END
GO

-- ============================================================
-- 6. Crear nuevo index para queries de movimientos elegibles
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CabeceraFlete_EstadoIdFactura' AND object_id = OBJECT_ID('[cfl].[CabeceraFlete]'))
BEGIN
    CREATE INDEX [IX_CabeceraFlete_EstadoIdFactura]
    ON [cfl].[CabeceraFlete] ([Estado], [IdFactura])
    WHERE [IdFactura] IS NULL;
END
GO
