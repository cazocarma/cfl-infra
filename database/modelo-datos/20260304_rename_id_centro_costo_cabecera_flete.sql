/* ============================================================================
   MIGRACION: 20260304_rename_id_centro_costo_cabecera_flete
   Tabla:     [cfl].[CFL_cabecera_flete]

   Objetivo:
     - Renombrar la columna [id_centro_costo_final] a [id_centro_costo]
     - Recrear la FK con el nombre canonico nuevo

   Notas:
     - Idempotente: si la columna ya fue renombrada, no hace cambios
     - No recrea tabla
============================================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

BEGIN TRY

  IF EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'FK_CFL_cabecera_flete_id_centro_costo_final_CFL_centro_costo'
  )
  BEGIN
    ALTER TABLE [cfl].[CFL_cabecera_flete]
      DROP CONSTRAINT [FK_CFL_cabecera_flete_id_centro_costo_final_CFL_centro_costo];
  END

  IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'cfl'
      AND TABLE_NAME = 'CFL_cabecera_flete'
      AND COLUMN_NAME = 'id_centro_costo_final'
  )
  AND NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'cfl'
      AND TABLE_NAME = 'CFL_cabecera_flete'
      AND COLUMN_NAME = 'id_centro_costo'
  )
  BEGIN
    EXEC sp_rename
      'cfl.CFL_cabecera_flete.id_centro_costo_final',
      'id_centro_costo',
      'COLUMN';
  END

  IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'cfl'
      AND TABLE_NAME = 'CFL_cabecera_flete'
      AND COLUMN_NAME = 'id_centro_costo'
  )
  AND NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'FK_CFL_cabecera_flete_id_centro_costo_CFL_centro_costo'
  )
  BEGIN
    ALTER TABLE [cfl].[CFL_cabecera_flete]
      ADD CONSTRAINT [FK_CFL_cabecera_flete_id_centro_costo_CFL_centro_costo]
      FOREIGN KEY ([id_centro_costo]) REFERENCES [cfl].[CFL_centro_costo] ([id_centro_costo])
      ON UPDATE NO ACTION ON DELETE NO ACTION;
  END

  COMMIT TRANSACTION;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;

  DECLARE @err_msg NVARCHAR(4000) = ERROR_MESSAGE();
  DECLARE @err_sev INT = ERROR_SEVERITY();

  RAISERROR(@err_msg, @err_sev, 1);
END CATCH;
GO
