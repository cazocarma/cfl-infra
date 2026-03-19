/* ============================================================================
   PATCH 20260310 - Agrega SapDestinatario a SapLikpRaw
   Objetivo:
   - Capturar el campo destinatario SAP (KUNWE / sold-to party) en la tabla
     raw para identificar al receptor de la entrega en el modulo de bandeja.
   Idempotente: SI
============================================================================ */
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

IF NOT EXISTS (
  SELECT 1 FROM sys.columns
  WHERE object_id = OBJECT_ID(N'[cfl].[SapLikpRaw]')
    AND name = N'SapDestinatario'
)
BEGIN
  ALTER TABLE [cfl].[SapLikpRaw]
    ADD [SapDestinatario] NVARCHAR(20) NULL;
END;

COMMIT TRANSACTION;
