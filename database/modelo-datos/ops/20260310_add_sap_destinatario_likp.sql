/* ============================================================================
   MIGRACIÓN: Agrega SapDestinatario a SapLikpRaw
   Fecha: 2026-03-10
   Motivo: Campo destinatario SAP (KUNWE / sold-to party) requerido para
           identificar al receptor de la entrega en el módulo de bandeja.
   Ejecutar sobre BD existentes (no sobre BD nuevas creadas con UP.sql).
   Script idempotente.
============================================================================ */

BEGIN TRY
    BEGIN TRANSACTION;

    -- Agregar columna SapDestinatario después de SapPuestoExpedicion
    IF NOT EXISTS (
        SELECT 1 FROM sys.columns
        WHERE object_id = OBJECT_ID(N'[cfl].[SapLikpRaw]')
          AND name = N'SapDestinatario'
    )
    BEGIN
        ALTER TABLE [cfl].[SapLikpRaw]
        ADD [SapDestinatario] NVARCHAR(20) NULL;
        PRINT 'Columna SapDestinatario agregada a SapLikpRaw';
    END
    ELSE
        PRINT 'Columna SapDestinatario ya existia en SapLikpRaw — sin cambio';

    COMMIT TRANSACTION;
    PRINT 'Migracion 20260310_add_sap_destinatario_likp completada.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR('Migracion fallida: %s', 16, 1, @msg);
END CATCH;
GO
