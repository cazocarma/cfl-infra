/* ============================================================================
   PATCH 20260320 - Elimina tabla DetalleFactura (obsoleta)

   Motivo: La tabla nunca fue poblada por el módulo de pre facturación.
   Los movimientos se obtienen via FacturaFolio → Folio → CabeceraFlete.
   Idempotente: SI
============================================================================ */
SET NOCOUNT ON;

-- 1. Eliminar FK si existe
IF EXISTS (
  SELECT 1 FROM sys.foreign_keys
  WHERE name = N'FK_DetalleFactura_CabeceraFactura'
)
BEGIN
  ALTER TABLE [cfl].[DetalleFactura]
    DROP CONSTRAINT [FK_DetalleFactura_CabeceraFactura];
END;

-- 2. Eliminar tabla si existe
IF OBJECT_ID(N'[cfl].[DetalleFactura]', N'U') IS NOT NULL
BEGIN
  DROP TABLE [cfl].[DetalleFactura];
  PRINT 'Tabla [cfl].[DetalleFactura] eliminada.';
END;
