/* ============================================================================
   MIGRACIÓN: Agrega IdFactura a CabeceraFlete
   Fecha: 2025-03-09
   Motivo: El nuevo modelo de facturación agrupa movimientos individualmente
           por centro de costo o tipo de flete. Un folio puede quedar dividido
           entre varias facturas, por lo que cada movimiento debe conocer a qué
           factura pertenece para que anulación y recálculo de montos sean
           correctos.
   Ejecutar sobre BD existentes (no sobre BD nuevas creadas con UP.sql).
============================================================================ */

-- Agregar columna IdFactura a CabeceraFlete (nullable, un movimiento
-- puede no estar asociado a ninguna factura todavía)
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[cfl].[CabeceraFlete]')
      AND name = 'IdFactura'
)
BEGIN
    ALTER TABLE [cfl].[CabeceraFlete]
    ADD [IdFactura] BIGINT NULL;
    PRINT 'Columna IdFactura agregada a CabeceraFlete';
END
ELSE
    PRINT 'Columna IdFactura ya existia en CabeceraFlete — sin cambio';
GO

-- FK hacia CabeceraFactura
IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = 'FK_CabeceraFlete_CabeceraFactura'
)
BEGIN
    ALTER TABLE [cfl].[CabeceraFlete]
    ADD CONSTRAINT [FK_CabeceraFlete_CabeceraFactura]
    FOREIGN KEY ([IdFactura]) REFERENCES [cfl].[CabeceraFactura] ([IdFactura])
    ON UPDATE NO ACTION ON DELETE NO ACTION;
    PRINT 'FK FK_CabeceraFlete_CabeceraFactura creada';
END
ELSE
    PRINT 'FK FK_CabeceraFlete_CabeceraFactura ya existia — sin cambio';
GO

-- Índice para acelerar búsquedas por IdFactura (ej. recálculo de montos,
-- reversión al anular)
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_CabeceraFlete_IdFactura'
)
BEGIN
    CREATE INDEX [IX_CabeceraFlete_IdFactura]
    ON [cfl].[CabeceraFlete] ([IdFactura])
    WHERE [IdFactura] IS NOT NULL;
    PRINT 'Indice IX_CabeceraFlete_IdFactura creado';
END
ELSE
    PRINT 'Indice IX_CabeceraFlete_IdFactura ya existia — sin cambio';
GO

PRINT 'Migracion 20250309_id_factura_en_cabecera_flete completada.';
GO
