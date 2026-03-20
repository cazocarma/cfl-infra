-- =============================================================
-- Agrega columna MontoExtra a CabeceraFlete
-- Permite registrar un monto adicional sobre la tarifa base.
-- MontoAplicado = tarifa_base + MontoExtra
-- =============================================================

IF NOT EXISTS (
  SELECT 1
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = 'cfl'
    AND TABLE_NAME   = 'CabeceraFlete'
    AND COLUMN_NAME  = 'MontoExtra'
)
BEGIN
  ALTER TABLE [cfl].[CabeceraFlete]
    ADD [MontoExtra] DECIMAL(18,2) NOT NULL DEFAULT 0;
END
GO
