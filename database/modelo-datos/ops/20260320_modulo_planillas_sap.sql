SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- PlanillaSap (header - one per generation)
IF NOT EXISTS (SELECT 1 FROM sys.tables t INNER JOIN sys.schemas s ON s.schema_id = t.schema_id WHERE s.name = 'cfl' AND t.name = 'PlanillaSap')
BEGIN
  CREATE TABLE [cfl].[PlanillaSap] (
    [IdPlanillaSap]         BIGINT NOT NULL IDENTITY UNIQUE,
    [IdFactura]             BIGINT        NOT NULL,
    [FechaDocumento]        DATE          NOT NULL,
    [FechaContabilizacion]  DATE          NOT NULL,
    [GlosaCabecera]         NVARCHAR(100) NOT NULL,
    [SociedadFI]            NVARCHAR(10)  NOT NULL DEFAULT '1000',
    [ClaseDocumento]        NVARCHAR(10)  NOT NULL DEFAULT 'KA',
    [Moneda]                CHAR(3)       NOT NULL DEFAULT 'CLP',
    [Temporada]             NVARCHAR(20)  NULL,
    [CodigoCargoAbono]      NVARCHAR(20)  NULL,
    [GlosaCargoAbono]       NVARCHAR(100) NULL,
    [IndicadorImpuesto]     NVARCHAR(10)  NOT NULL DEFAULT 'C0',
    [TotalLineas]           INT           NOT NULL DEFAULT 0,
    [TotalDocumentos]       INT           NOT NULL DEFAULT 0,
    [MontoTotal]            DECIMAL(18,2) NOT NULL DEFAULT 0,
    [Estado]                NVARCHAR(20)  NOT NULL DEFAULT 'generada',
    [IdUsuarioCreador]      BIGINT        NULL,
    [FechaCreacion]         DATETIME2(0)  NOT NULL,
    [FechaActualizacion]    DATETIME2(0)  NOT NULL,
    CONSTRAINT [PK_PlanillaSap] PRIMARY KEY ([IdPlanillaSap])
  );
  CREATE INDEX [IX_PlanillaSap_IdFactura] ON [cfl].[PlanillaSap] ([IdFactura]);
  CREATE INDEX [IX_PlanillaSap_Estado] ON [cfl].[PlanillaSap] ([Estado], [FechaCreacion] DESC);
END;

-- PlanillaSapDocumento (each SAP accounting document within a planilla)
IF NOT EXISTS (SELECT 1 FROM sys.tables t INNER JOIN sys.schemas s ON s.schema_id = t.schema_id WHERE s.name = 'cfl' AND t.name = 'PlanillaSapDocumento')
BEGIN
  CREATE TABLE [cfl].[PlanillaSapDocumento] (
    [IdPlanillaSapDocumento] BIGINT NOT NULL IDENTITY UNIQUE,
    [IdPlanillaSap]          BIGINT        NOT NULL,
    [NumeroDocumento]        INT           NOT NULL,
    [IdFolio]                BIGINT        NULL,
    [FolioNumero]            NVARCHAR(30)  NULL,
    [IdCentroCosto]          BIGINT        NULL,
    [CentroCostoCodigo]      NVARCHAR(20)  NULL,
    [IdCuentaMayor]          BIGINT        NULL,
    [CuentaMayorCodigo]      NVARCHAR(30)  NULL,
    [MontoDebito]            DECIMAL(18,2) NOT NULL DEFAULT 0,
    [TotalLineas]            INT           NOT NULL DEFAULT 0,
    CONSTRAINT [PK_PlanillaSapDocumento] PRIMARY KEY ([IdPlanillaSapDocumento])
  );
  CREATE INDEX [IX_PlanillaSapDocumento_IdPlanillaSap] ON [cfl].[PlanillaSapDocumento] ([IdPlanillaSap]);
END;

-- PlanillaSapLinea (each TSV line)
IF NOT EXISTS (SELECT 1 FROM sys.tables t INNER JOIN sys.schemas s ON s.schema_id = t.schema_id WHERE s.name = 'cfl' AND t.name = 'PlanillaSapLinea')
BEGIN
  CREATE TABLE [cfl].[PlanillaSapLinea] (
    [IdPlanillaSapLinea]      BIGINT NOT NULL IDENTITY UNIQUE,
    [IdPlanillaSapDocumento]  BIGINT        NOT NULL,
    [NumeroLinea]             INT           NOT NULL,
    [EsDocNuevo]              BIT           NOT NULL DEFAULT 0,
    [ClaveContabilizacion]    NVARCHAR(10)  NOT NULL,
    [CuentaMayor]             NVARCHAR(30)  NULL,
    [CodigoProveedor]         NVARCHAR(20)  NULL,
    [IndicadorCME]            NVARCHAR(5)   NULL,
    [Importe]                 DECIMAL(18,2) NOT NULL,
    [CentroCosto]             NVARCHAR(20)  NULL,
    [OrdenCompra]             NVARCHAR(30)  NULL,
    [PosicionOC]              NVARCHAR(10)  NULL,
    [NroAsignacion]           NVARCHAR(100) NULL,
    [TextoLinea]              NVARCHAR(100) NULL,
    [IndicadorImpuesto]       NVARCHAR(10)  NULL,
    [Temporada]               NVARCHAR(20)  NULL,
    [TipoCargoAbono]          NVARCHAR(20)  NULL,
    CONSTRAINT [PK_PlanillaSapLinea] PRIMARY KEY ([IdPlanillaSapLinea])
  );
  CREATE INDEX [IX_PlanillaSapLinea_IdDocumento] ON [cfl].[PlanillaSapLinea] ([IdPlanillaSapDocumento]);
END;

-- Foreign keys (idempotent)
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_PlanillaSap_CabeceraFactura')
  ALTER TABLE [cfl].[PlanillaSap] ADD CONSTRAINT [FK_PlanillaSap_CabeceraFactura] FOREIGN KEY ([IdFactura]) REFERENCES [cfl].[CabeceraFactura] ([IdFactura]);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_PlanillaSapDocumento_PlanillaSap')
  ALTER TABLE [cfl].[PlanillaSapDocumento] ADD CONSTRAINT [FK_PlanillaSapDocumento_PlanillaSap] FOREIGN KEY ([IdPlanillaSap]) REFERENCES [cfl].[PlanillaSap] ([IdPlanillaSap]);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_PlanillaSapLinea_PlanillaSapDocumento')
  ALTER TABLE [cfl].[PlanillaSapLinea] ADD CONSTRAINT [FK_PlanillaSapLinea_PlanillaSapDocumento] FOREIGN KEY ([IdPlanillaSapDocumento]) REFERENCES [cfl].[PlanillaSapDocumento] ([IdPlanillaSapDocumento]);

COMMIT TRANSACTION;
