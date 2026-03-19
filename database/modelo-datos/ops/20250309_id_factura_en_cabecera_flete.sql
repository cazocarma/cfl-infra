/* ============================================================================
   PATCH 20250309 - Agrega IdFactura a CabeceraFlete
   Objetivo:
   - Soportar el modelo de facturacion donde un folio puede quedar dividido
     entre varias facturas; cada movimiento debe conocer a que factura
     pertenece para que anulacion y recalculo de montos sean correctos.
   Idempotente: SI
============================================================================ */
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

IF NOT EXISTS (
  SELECT 1 FROM sys.columns
  WHERE object_id = OBJECT_ID(N'[cfl].[CabeceraFlete]')
    AND name = N'IdFactura'
)
BEGIN
  ALTER TABLE [cfl].[CabeceraFlete]
    ADD [IdFactura] BIGINT NULL;
END;

IF NOT EXISTS (
  SELECT 1 FROM sys.foreign_keys
  WHERE name = N'FK_CabeceraFlete_CabeceraFactura'
)
BEGIN
  ALTER TABLE [cfl].[CabeceraFlete]
    ADD CONSTRAINT [FK_CabeceraFlete_CabeceraFactura]
    FOREIGN KEY ([IdFactura]) REFERENCES [cfl].[CabeceraFactura] ([IdFactura])
    ON UPDATE NO ACTION ON DELETE NO ACTION;
END;

IF NOT EXISTS (
  SELECT 1 FROM sys.indexes
  WHERE name = N'IX_CabeceraFlete_IdFactura'
    AND object_id = OBJECT_ID(N'[cfl].[CabeceraFlete]')
)
BEGIN
  CREATE INDEX [IX_CabeceraFlete_IdFactura]
    ON [cfl].[CabeceraFlete] ([IdFactura])
    WHERE [IdFactura] IS NOT NULL;
END;

COMMIT TRANSACTION;
