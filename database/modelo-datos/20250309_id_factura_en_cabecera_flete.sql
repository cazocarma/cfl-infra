/* ============================================================================
   MIGRACIÓN: Agrega id_factura a CFL_cabecera_flete
   Fecha: 2025-03-09
   Motivo: El nuevo modelo de facturación agrupa movimientos individualmente
           por centro de costo o tipo de flete. Un folio puede quedar dividido
           entre varias facturas, por lo que cada movimiento debe conocer a qué
           factura pertenece para que anulación y recálculo de montos sean
           correctos.
   Ejecutar sobre BD existentes (no sobre BD nuevas creadas con UP.sql).
============================================================================ */

-- Agregar columna id_factura a CFL_cabecera_flete (nullable, un movimiento
-- puede no estar asociado a ninguna factura todavía)
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[cfl].[CFL_cabecera_flete]')
      AND name = 'id_factura'
)
BEGIN
    ALTER TABLE [cfl].[CFL_cabecera_flete]
    ADD [id_factura] BIGINT NULL;
    PRINT 'Columna id_factura agregada a CFL_cabecera_flete';
END
ELSE
    PRINT 'Columna id_factura ya existía en CFL_cabecera_flete — sin cambio';
GO

-- FK hacia CFL_cabecera_factura
IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = 'FK_CFL_cabecera_flete_id_factura'
)
BEGIN
    ALTER TABLE [cfl].[CFL_cabecera_flete]
    ADD CONSTRAINT [FK_CFL_cabecera_flete_id_factura]
    FOREIGN KEY ([id_factura]) REFERENCES [cfl].[CFL_cabecera_factura] ([id_factura])
    ON UPDATE NO ACTION ON DELETE NO ACTION;
    PRINT 'FK FK_CFL_cabecera_flete_id_factura creada';
END
ELSE
    PRINT 'FK FK_CFL_cabecera_flete_id_factura ya existía — sin cambio';
GO

-- Índice para acelerar búsquedas por id_factura (ej. recálculo de montos,
-- reversión al anular)
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_CFL_cabecera_flete_id_factura'
)
BEGIN
    CREATE INDEX [IX_CFL_cabecera_flete_id_factura]
    ON [cfl].[CFL_cabecera_flete] ([id_factura])
    WHERE [id_factura] IS NOT NULL;
    PRINT 'Índice IX_CFL_cabecera_flete_id_factura creado';
END
ELSE
    PRINT 'Índice IX_CFL_cabecera_flete_id_factura ya existía — sin cambio';
GO

PRINT 'Migración 20250309_id_factura_en_cabecera_flete completada.';
GO
