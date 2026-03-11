/* ============================================================================
   PATCH: Tabla de descarte para entregas SAP no ingresadas
   Objetivo:
   - Permitir descartar/restaurar ingresos SAP antes de crear cabecera de flete.
   - Script idempotente (se puede ejecutar mas de una vez).
============================================================================ */

IF OBJECT_ID(N'[cfl].[SapEntregaDescarte]', N'U') IS NULL
BEGIN
  CREATE TABLE [cfl].[SapEntregaDescarte] (
      [IdSapEntregaDescarte] BIGINT NOT NULL IDENTITY(1,1),
      [IdSapEntrega] BIGINT NOT NULL,
      [Activo] BIT NOT NULL CONSTRAINT [DF_SapEntregaDescarte_Activo] DEFAULT(1),
      [Motivo] VARCHAR(200) NULL,
      [FechaCreacion] DATETIME2(0) NOT NULL,
      [FechaActualizacion] DATETIME2(0) NOT NULL,
      [CreadoPor] BIGINT NULL,
      [FechaRestauracion] DATETIME2(0) NULL,
      [RestauradoPor] BIGINT NULL,
      CONSTRAINT [PK_SapEntregaDescarte] PRIMARY KEY ([IdSapEntregaDescarte])
  );
END;
GO

IF NOT EXISTS (
  SELECT 1
  FROM sys.indexes
  WHERE name = N'UQ_SapEntregaDescarte_IdSapEntrega'
    AND object_id = OBJECT_ID(N'[cfl].[SapEntregaDescarte]')
)
BEGIN
  CREATE UNIQUE INDEX [UQ_SapEntregaDescarte_IdSapEntrega]
  ON [cfl].[SapEntregaDescarte] ([IdSapEntrega]);
END;
GO

IF NOT EXISTS (
  SELECT 1
  FROM sys.indexes
  WHERE name = N'IX_SapEntregaDescarte_Activo'
    AND object_id = OBJECT_ID(N'[cfl].[SapEntregaDescarte]')
)
BEGIN
  CREATE INDEX [IX_SapEntregaDescarte_Activo]
  ON [cfl].[SapEntregaDescarte] ([Activo], [IdSapEntrega]);
END;
GO

IF OBJECT_ID(N'[cfl].[SapEntregaDescarte]', N'U') IS NOT NULL
   AND OBJECT_ID(N'[cfl].[SapEntrega]', N'U') IS NOT NULL
   AND NOT EXISTS (
     SELECT 1
     FROM sys.foreign_keys
     WHERE name = N'FK_SapEntregaDescarte_SapEntrega'
   )
BEGIN
  ALTER TABLE [cfl].[SapEntregaDescarte]
  ADD CONSTRAINT [FK_SapEntregaDescarte_SapEntrega]
  FOREIGN KEY ([IdSapEntrega]) REFERENCES [cfl].[SapEntrega] ([IdSapEntrega]);
END;
GO

IF OBJECT_ID(N'[cfl].[SapEntregaDescarte]', N'U') IS NOT NULL
   AND OBJECT_ID(N'[cfl].[Usuario]', N'U') IS NOT NULL
   AND NOT EXISTS (
     SELECT 1
     FROM sys.foreign_keys
     WHERE name = N'FK_SapEntregaDescarte_UsuarioCreadoPor'
   )
BEGIN
  ALTER TABLE [cfl].[SapEntregaDescarte]
  ADD CONSTRAINT [FK_SapEntregaDescarte_UsuarioCreadoPor]
  FOREIGN KEY ([CreadoPor]) REFERENCES [cfl].[Usuario] ([IdUsuario]);
END;
GO

IF OBJECT_ID(N'[cfl].[SapEntregaDescarte]', N'U') IS NOT NULL
   AND OBJECT_ID(N'[cfl].[Usuario]', N'U') IS NOT NULL
   AND NOT EXISTS (
     SELECT 1
     FROM sys.foreign_keys
     WHERE name = N'FK_SapEntregaDescarte_UsuarioRestauradoPor'
   )
BEGIN
  ALTER TABLE [cfl].[SapEntregaDescarte]
  ADD CONSTRAINT [FK_SapEntregaDescarte_UsuarioRestauradoPor]
  FOREIGN KEY ([RestauradoPor]) REFERENCES [cfl].[Usuario] ([IdUsuario]);
END;
GO
