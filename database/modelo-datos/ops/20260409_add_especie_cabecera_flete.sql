-- ============================================================
-- Agrega IdEspecie a CabeceraFlete
-- La especie se selecciona manualmente por el usuario.
-- Se usa en la agrupacion de la planilla SAP (NroAsignacion).
-- ============================================================

IF NOT EXISTS (
  SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = 'cfl' AND TABLE_NAME = 'CabeceraFlete' AND COLUMN_NAME = 'IdEspecie'
)
BEGIN
  ALTER TABLE [cfl].[CabeceraFlete]
    ADD [IdEspecie] BIGINT NULL;

  ALTER TABLE [cfl].[CabeceraFlete]
    ADD CONSTRAINT [FK_CabeceraFlete_Especie]
    FOREIGN KEY ([IdEspecie]) REFERENCES [cfl].[Especie] ([IdEspecie]);

  CREATE INDEX [IX_CabeceraFlete_IdEspecie]
    ON [cfl].[CabeceraFlete] ([IdEspecie]);
END
GO
