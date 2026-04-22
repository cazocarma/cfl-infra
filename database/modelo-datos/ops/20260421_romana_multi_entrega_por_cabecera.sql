-- ============================================================
-- Migración: candidatos Romana agrupados por camión/guía.
-- Fecha: 2026-04-21
--
-- Cambios:
--   1) Endurecer invariante "una entrega Romana -> un único flete"
--      agregando UNIQUE INDEX sobre cfl.FleteRomanaEntrega(IdRomanaEntrega).
--      El índice bridge existente es compuesto (IdCabeceraFlete, IdRomanaEntrega)
--      y SÍ permite múltiples entregas por cabecera — lo que habilita el nuevo
--      modelo. Pero no impedía que una misma entrega acabara en dos fletes: este
--      índice lo garantiza a nivel de BD.
--
--   2) Trazabilidad Romana persistida en cfl.DetalleFlete. Hoy el desglose
--      (partida, posición, lote) se reconstruye on-the-fly desde vistas; al
--      persistirlo en el detalle guardado queda independiente de la vista y
--      sobrevive a resincronías Romana.
-- ============================================================

-- 1) Unicidad global de IdRomanaEntrega en el bridge
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'UQ_FleteRomanaEntrega_IdRomanaEntrega'
      AND object_id = OBJECT_ID('cfl.FleteRomanaEntrega')
)
BEGIN
    CREATE UNIQUE INDEX [UQ_FleteRomanaEntrega_IdRomanaEntrega]
        ON [cfl].[FleteRomanaEntrega] ([IdRomanaEntrega]);
END
GO

-- 2) Trazabilidad Romana en DetalleFlete
IF COL_LENGTH('cfl.DetalleFlete', 'IdRomanaEntrega') IS NULL
    ALTER TABLE [cfl].[DetalleFlete] ADD [IdRomanaEntrega] BIGINT NULL;
GO
IF COL_LENGTH('cfl.DetalleFlete', 'RomanaNumeroPartida') IS NULL
    ALTER TABLE [cfl].[DetalleFlete] ADD [RomanaNumeroPartida] NVARCHAR(20) NULL;
GO
IF COL_LENGTH('cfl.DetalleFlete', 'RomanaPosicion') IS NULL
    ALTER TABLE [cfl].[DetalleFlete] ADD [RomanaPosicion] NVARCHAR(10) NULL;
GO
IF COL_LENGTH('cfl.DetalleFlete', 'RomanaLote') IS NULL
    ALTER TABLE [cfl].[DetalleFlete] ADD [RomanaLote] NVARCHAR(20) NULL;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = 'FK_DetalleFlete_RomanaEntrega'
)
BEGIN
    ALTER TABLE [cfl].[DetalleFlete] WITH CHECK
        ADD CONSTRAINT [FK_DetalleFlete_RomanaEntrega]
        FOREIGN KEY ([IdRomanaEntrega]) REFERENCES [cfl].[RomanaEntrega] ([IdRomanaEntrega]);
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_DetalleFlete_IdRomanaEntrega'
      AND object_id = OBJECT_ID('cfl.DetalleFlete')
)
BEGIN
    CREATE INDEX [IX_DetalleFlete_IdRomanaEntrega]
        ON [cfl].[DetalleFlete] ([IdRomanaEntrega])
        INCLUDE ([RomanaNumeroPartida], [RomanaPosicion], [RomanaLote]);
END
GO
