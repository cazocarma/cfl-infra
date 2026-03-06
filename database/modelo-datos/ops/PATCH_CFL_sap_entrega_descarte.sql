/* ============================================================================
   PATCH: Tabla de descarte para entregas SAP no ingresadas
   Objetivo:
   - Permitir descartar/restaurar ingresos SAP antes de crear cabecera de flete.
   - Script idempotente (se puede ejecutar mas de una vez).
============================================================================ */

IF OBJECT_ID(N'[cfl].[CFL_sap_entrega_descarte]', N'U') IS NULL
BEGIN
  CREATE TABLE [cfl].[CFL_sap_entrega_descarte] (
      [id_sap_entrega_descarte] BIGINT NOT NULL IDENTITY(1,1),
      [id_sap_entrega] BIGINT NOT NULL,
      [activo] BIT NOT NULL CONSTRAINT [DF_CFL_sap_entrega_descarte_activo] DEFAULT(1),
      [motivo] VARCHAR(200) NULL,
      [created_at] DATETIME2(0) NOT NULL,
      [updated_at] DATETIME2(0) NOT NULL,
      [created_by] BIGINT NULL,
      [restored_at] DATETIME2(0) NULL,
      [restored_by] BIGINT NULL,
      CONSTRAINT [PK_CFL_sap_entrega_descarte] PRIMARY KEY ([id_sap_entrega_descarte])
  );
END;
GO

IF NOT EXISTS (
  SELECT 1
  FROM sys.indexes
  WHERE name = N'UX_sap_entrega_descarte_entrega'
    AND object_id = OBJECT_ID(N'[cfl].[CFL_sap_entrega_descarte]')
)
BEGIN
  CREATE UNIQUE INDEX [UX_sap_entrega_descarte_entrega]
  ON [cfl].[CFL_sap_entrega_descarte] ([id_sap_entrega]);
END;
GO

IF NOT EXISTS (
  SELECT 1
  FROM sys.indexes
  WHERE name = N'IX_sap_entrega_descarte_activo'
    AND object_id = OBJECT_ID(N'[cfl].[CFL_sap_entrega_descarte]')
)
BEGIN
  CREATE INDEX [IX_sap_entrega_descarte_activo]
  ON [cfl].[CFL_sap_entrega_descarte] ([activo], [id_sap_entrega]);
END;
GO

IF OBJECT_ID(N'[cfl].[CFL_sap_entrega_descarte]', N'U') IS NOT NULL
   AND OBJECT_ID(N'[cfl].[CFL_sap_entrega]', N'U') IS NOT NULL
   AND NOT EXISTS (
     SELECT 1
     FROM sys.foreign_keys
     WHERE name = N'FK_CFL_sap_entrega_descarte_id_sap_entrega_CFL_sap_entrega'
   )
BEGIN
  ALTER TABLE [cfl].[CFL_sap_entrega_descarte]
  ADD CONSTRAINT [FK_CFL_sap_entrega_descarte_id_sap_entrega_CFL_sap_entrega]
  FOREIGN KEY ([id_sap_entrega]) REFERENCES [cfl].[CFL_sap_entrega] ([id_sap_entrega]);
END;
GO

IF OBJECT_ID(N'[cfl].[CFL_sap_entrega_descarte]', N'U') IS NOT NULL
   AND OBJECT_ID(N'[cfl].[CFL_usuario]', N'U') IS NOT NULL
   AND NOT EXISTS (
     SELECT 1
     FROM sys.foreign_keys
     WHERE name = N'FK_CFL_sap_entrega_descarte_created_by_CFL_usuario'
   )
BEGIN
  ALTER TABLE [cfl].[CFL_sap_entrega_descarte]
  ADD CONSTRAINT [FK_CFL_sap_entrega_descarte_created_by_CFL_usuario]
  FOREIGN KEY ([created_by]) REFERENCES [cfl].[CFL_usuario] ([id_usuario]);
END;
GO

IF OBJECT_ID(N'[cfl].[CFL_sap_entrega_descarte]', N'U') IS NOT NULL
   AND OBJECT_ID(N'[cfl].[CFL_usuario]', N'U') IS NOT NULL
   AND NOT EXISTS (
     SELECT 1
     FROM sys.foreign_keys
     WHERE name = N'FK_CFL_sap_entrega_descarte_restored_by_CFL_usuario'
   )
BEGIN
  ALTER TABLE [cfl].[CFL_sap_entrega_descarte]
  ADD CONSTRAINT [FK_CFL_sap_entrega_descarte_restored_by_CFL_usuario]
  FOREIGN KEY ([restored_by]) REFERENCES [cfl].[CFL_usuario] ([id_usuario]);
END;
GO
