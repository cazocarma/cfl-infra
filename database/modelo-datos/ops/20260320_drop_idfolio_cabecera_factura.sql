/* ============================================================================
   PATCH 20260320 - Elimina columna IdFolio de CabeceraFactura (obsoleta)

   Motivo: La relación factura↔folio se maneja via bridge FacturaFolio (n:m).
   El campo IdFolio directo nunca se escribía en el flujo de generación.
   Idempotente: SI
============================================================================ */
SET NOCOUNT ON;

-- 1. Eliminar FK si existe
IF EXISTS (
  SELECT 1 FROM sys.foreign_keys
  WHERE name = N'FK_CabeceraFactura_Folio'
)
BEGIN
  ALTER TABLE [cfl].[CabeceraFactura]
    DROP CONSTRAINT [FK_CabeceraFactura_Folio];
  PRINT 'FK [FK_CabeceraFactura_Folio] eliminada.';
END;

-- 2. Eliminar columna si existe
IF EXISTS (
  SELECT 1 FROM sys.columns
  WHERE object_id = OBJECT_ID(N'[cfl].[CabeceraFactura]')
    AND name = N'IdFolio'
)
BEGIN
  ALTER TABLE [cfl].[CabeceraFactura]
    DROP COLUMN [IdFolio];
  PRINT 'Columna [IdFolio] eliminada de [cfl].[CabeceraFactura].';
END;
