/* ============================================================================
   PATCH 20260422 - Agrega IdTemporada a CabeceraFlete y unicidad de Temporada activa
   Objetivo:
   - Cada flete queda ligado a la temporada vigente al momento de crearse.
   - La asignacion es explicita (estampada en el INSERT), no derivada por fecha.
   - A nivel de BD solo puede haber una Temporada con Activa = 1.
   Idempotente: SI
============================================================================ */
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

-- 1. Unicidad de Temporada activa: indice unico filtrado.
IF NOT EXISTS (
  SELECT 1 FROM sys.indexes
  WHERE name = N'UQ_Temporada_Activa'
    AND object_id = OBJECT_ID(N'[cfl].[Temporada]')
)
BEGIN
  CREATE UNIQUE INDEX [UQ_Temporada_Activa]
    ON [cfl].[Temporada] ([Activa])
    WHERE [Activa] = 1;
END;

-- 2. Columna IdTemporada (NULLable primero, luego backfill, luego NOT NULL).
IF NOT EXISTS (
  SELECT 1 FROM sys.columns
  WHERE object_id = OBJECT_ID(N'[cfl].[CabeceraFlete]')
    AND name = N'IdTemporada'
)
BEGIN
  ALTER TABLE [cfl].[CabeceraFlete]
    ADD [IdTemporada] BIGINT NULL;
END;

COMMIT TRANSACTION;
GO

-- 3. Backfill: asigna la temporada activa a los fletes existentes sin IdTemporada.
--    Fuera de la transaccion anterior para que el ALTER ADD sea visible.
DECLARE @idTemporadaActiva BIGINT = (
  SELECT TOP 1 IdTemporada FROM [cfl].[Temporada] WHERE Activa = 1
);

IF @idTemporadaActiva IS NULL AND EXISTS (
  SELECT 1 FROM [cfl].[CabeceraFlete] WHERE IdTemporada IS NULL
)
BEGIN
  RAISERROR(
    'No hay temporada activa y existen fletes sin IdTemporada. Active una temporada antes de aplicar este patch.',
    16, 1
  );
  RETURN;
END;

IF @idTemporadaActiva IS NOT NULL
BEGIN
  UPDATE [cfl].[CabeceraFlete]
    SET IdTemporada = @idTemporadaActiva
    WHERE IdTemporada IS NULL;
END;
GO

-- 4. NOT NULL + FK + indice. Todo idempotente.
BEGIN TRANSACTION;

IF EXISTS (
  SELECT 1 FROM sys.columns
  WHERE object_id = OBJECT_ID(N'[cfl].[CabeceraFlete]')
    AND name = N'IdTemporada'
    AND is_nullable = 1
)
BEGIN
  ALTER TABLE [cfl].[CabeceraFlete]
    ALTER COLUMN [IdTemporada] BIGINT NOT NULL;
END;

IF NOT EXISTS (
  SELECT 1 FROM sys.foreign_keys
  WHERE name = N'FK_CabeceraFlete_Temporada'
)
BEGIN
  ALTER TABLE [cfl].[CabeceraFlete]
    ADD CONSTRAINT [FK_CabeceraFlete_Temporada]
    FOREIGN KEY ([IdTemporada]) REFERENCES [cfl].[Temporada] ([IdTemporada])
    ON UPDATE NO ACTION ON DELETE NO ACTION;
END;

IF NOT EXISTS (
  SELECT 1 FROM sys.indexes
  WHERE name = N'IX_CabeceraFlete_IdTemporada'
    AND object_id = OBJECT_ID(N'[cfl].[CabeceraFlete]')
)
BEGIN
  CREATE INDEX [IX_CabeceraFlete_IdTemporada]
    ON [cfl].[CabeceraFlete] ([IdTemporada]);
END;

COMMIT TRANSACTION;
