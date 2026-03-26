/* =================================================================
   PATCH: Agrega NumeroFacturaRecibida a CabeceraFactura
   Fecha: 2026-03-25
   Motivo: Al marcar una pre factura como "recibida" se debe registrar
           el numero de factura real entregado por la empresa de transporte.
   ================================================================= */

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'cfl'
      AND TABLE_NAME   = 'CabeceraFactura'
      AND COLUMN_NAME  = 'NumeroFacturaRecibida'
)
BEGIN
    ALTER TABLE [cfl].[CabeceraFactura]
        ADD [NumeroFacturaRecibida] NVARCHAR(60) NULL;
END
GO
