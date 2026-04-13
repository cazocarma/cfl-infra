-- ============================================================
-- Tablas para pipeline Romana (recepciones SAP via OData)
-- Patrón: Raw → Stage → Dedup → Canonical
-- Análogo a LIKP/LIPS para despachos
--
-- Clave natural de cabecera: NumeroPartida + GuiaDespacho
-- Un flete de recepción = una combinación partida + guía
-- ============================================================

-- ============================================================
-- LIMPIEZA: DROP de tablas existentes (purgar datos dev)
-- ============================================================
IF EXISTS (SELECT 1 FROM sys.views WHERE name='VW_RomanaDetalleActual' AND schema_id=SCHEMA_ID('cfl'))
  DROP VIEW [cfl].[VW_RomanaDetalleActual];
GO
IF EXISTS (SELECT 1 FROM sys.views WHERE name='VW_RomanaCabeceraActual' AND schema_id=SCHEMA_ID('cfl'))
  DROP VIEW [cfl].[VW_RomanaCabeceraActual];
GO

-- Drop FKs first
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_FleteRomanaEntrega_Flete') ALTER TABLE [cfl].[FleteRomanaEntrega] DROP CONSTRAINT [FK_FleteRomanaEntrega_Flete];
GO
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_FleteRomanaEntrega_Romana') ALTER TABLE [cfl].[FleteRomanaEntrega] DROP CONSTRAINT [FK_FleteRomanaEntrega_Romana];
GO
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_RomanaEntregaDescarte_Entrega') ALTER TABLE [cfl].[RomanaEntregaDescarte] DROP CONSTRAINT [FK_RomanaEntregaDescarte_Entrega];
GO
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_RomanaEntregaPosHist_Pos') ALTER TABLE [cfl].[RomanaEntregaPosicionHistorial] DROP CONSTRAINT [FK_RomanaEntregaPosHist_Pos];
GO
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_RomanaEntregaPosHist_Raw') ALTER TABLE [cfl].[RomanaEntregaPosicionHistorial] DROP CONSTRAINT [FK_RomanaEntregaPosHist_Raw];
GO
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_RomanaEntregaPos_Entrega') ALTER TABLE [cfl].[RomanaEntregaPosicion] DROP CONSTRAINT [FK_RomanaEntregaPos_Entrega];
GO
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_RomanaEntregaHist_Entrega') ALTER TABLE [cfl].[RomanaEntregaHistorial] DROP CONSTRAINT [FK_RomanaEntregaHist_Entrega];
GO
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_RomanaEntregaHist_Raw') ALTER TABLE [cfl].[RomanaEntregaHistorial] DROP CONSTRAINT [FK_RomanaEntregaHist_Raw];
GO

DROP TABLE IF EXISTS [cfl].[FleteRomanaEntrega];
DROP TABLE IF EXISTS [cfl].[RomanaEntregaDescarte];
DROP TABLE IF EXISTS [cfl].[RomanaEntregaPosicionHistorial];
DROP TABLE IF EXISTS [cfl].[RomanaEntregaPosicion];
DROP TABLE IF EXISTS [cfl].[RomanaEntregaHistorial];
DROP TABLE IF EXISTS [cfl].[RomanaEntrega];
DROP TABLE IF EXISTS [cfl].[StgRomanaCabecera];
DROP TABLE IF EXISTS [cfl].[StgRomanaDetalle];
DROP TABLE IF EXISTS [cfl].[RomanaDetalleRaw];
DROP TABLE IF EXISTS [cfl].[RomanaCabeceraRaw];
GO

-- ============================================================
-- RAW: RomanaCabeceraRaw — cabecera por movimiento
-- Clave natural: (SistemaFuente, NumeroPartida, GuiaDespacho)
-- ============================================================
CREATE TABLE [cfl].[RomanaCabeceraRaw] (
  [IdRomanaCabeceraRaw]    BIGINT IDENTITY UNIQUE,
  [IdEjecucion]            UNIQUEIDENTIFIER NOT NULL,
  [FechaExtraccion]        DATETIME2(0)     NOT NULL,
  [SistemaFuente]          NVARCHAR(50)     NOT NULL,
  [HashFila]               BINARY(32)       NOT NULL,
  [EstadoFila]             NVARCHAR(20)     NOT NULL,
  [FechaCreacion]          DATETIME2(0)     NOT NULL,

  [IdRomana]               NVARCHAR(20)     NOT NULL,
  [NumeroPartida]          NVARCHAR(20)     NULL,
  [GuiaDespacho]           NVARCHAR(30)     NULL,
  [TipoDocumento]          NVARCHAR(10)     NULL,
  [TipoDocumentoTexto]     NVARCHAR(40)     NULL,
  [EstadoRomana]           NVARCHAR(10)     NULL,
  [EstadoRomanaTexto]      NVARCHAR(40)     NULL,
  [Patente]                NVARCHAR(20)     NULL,
  [Carro]                  NVARCHAR(20)     NULL,
  [Conductor]              NVARCHAR(80)     NULL,
  [CreadoPor]              NVARCHAR(12)     NULL,
  [CreadoPorNombre]        NVARCHAR(80)     NULL,
  [FechaCreacionSap]       DATE             NULL,
  [FechaModificacionSap]   DATE             NULL,
  [OrdenCompra]            NVARCHAR(20)     NULL,
  [CodigoProductor]        NVARCHAR(20)     NULL,
  [Centro]                 NVARCHAR(10)     NULL,
  [CentroNombre]           NVARCHAR(40)     NULL,
  [PlantaDestino]          NVARCHAR(10)     NULL,
  [PlantaDestinoNombre]    NVARCHAR(40)     NULL,
  [AlmacenDestino]         NVARCHAR(10)     NULL,
  [AlmacenDestinoNombre]   NVARCHAR(40)     NULL,
  [Temporada]              NVARCHAR(10)     NULL,
  [CSG]                    NVARCHAR(20)     NULL,
  [GuiaAlterna]            NVARCHAR(30)     NULL,
  [ProductorDescripcion]   NVARCHAR(80)     NULL,
  [ProductorDireccion]     NVARCHAR(150)    NULL,
  [ProductorComuna]        NVARCHAR(60)     NULL,
  [ProductorProvincia]     NVARCHAR(60)     NULL,
  [PeticionBorrado]        BIT              NOT NULL DEFAULT 0,
  [ActualizadoPor]         NVARCHAR(12)     NULL,
  [ActualizadoPorNombre]   NVARCHAR(80)     NULL,

  PRIMARY KEY ([IdRomanaCabeceraRaw])
);
GO

CREATE INDEX [IX_RomanaCabeceraRaw_IdEjecucion]
  ON [cfl].[RomanaCabeceraRaw] ([IdEjecucion]);
CREATE INDEX [IX_RomanaCabeceraRaw_BkFecha]
  ON [cfl].[RomanaCabeceraRaw] ([SistemaFuente], [NumeroPartida], [GuiaDespacho], [FechaExtraccion]);
CREATE UNIQUE INDEX [UQ_RomanaCabeceraRaw_BkHash]
  ON [cfl].[RomanaCabeceraRaw] ([SistemaFuente], [NumeroPartida], [GuiaDespacho], [HashFila]);
GO

-- ============================================================
-- RAW: RomanaDetalleRaw — posiciones por movimiento
-- ============================================================
CREATE TABLE [cfl].[RomanaDetalleRaw] (
  [IdRomanaDetalleRaw]     BIGINT IDENTITY UNIQUE,
  [IdEjecucion]            UNIQUEIDENTIFIER NOT NULL,
  [FechaExtraccion]        DATETIME2(0)     NOT NULL,
  [SistemaFuente]          NVARCHAR(50)     NOT NULL,
  [HashFila]               BINARY(32)       NOT NULL,
  [EstadoFila]             NVARCHAR(20)     NOT NULL,
  [FechaCreacion]          DATETIME2(0)     NOT NULL,

  [NumeroPartida]          NVARCHAR(20)     NOT NULL,
  [GuiaDespacho]           NVARCHAR(30)     NOT NULL,
  [Posicion]               NVARCHAR(10)     NOT NULL,
  [Material]               NVARCHAR(40)     NULL,
  [MaterialDescripcion]    NVARCHAR(40)     NULL,
  [Lote]                   NVARCHAR(20)     NULL,
  [PesoReal]               DECIMAL(15,3)    NOT NULL DEFAULT 0,
  [UnidadMedida]           NVARCHAR(5)      NULL,
  [Envase]                 NVARCHAR(20)     NULL,
  [EnvaseDescripcion]      NVARCHAR(40)     NULL,
  [SubEnvase]              NVARCHAR(20)     NULL,
  [SubEnvaseDescripcion]   NVARCHAR(40)     NULL,
  [PosicionOrdenCompra]    NVARCHAR(10)     NULL,
  [CodigoEspecie]          NVARCHAR(10)     NULL,
  [EspecieDescripcion]     NVARCHAR(40)     NULL,
  [CodigoGrupoVariedad]    NVARCHAR(10)     NULL,
  [GrupoVariedadDescripcion] NVARCHAR(40)   NULL,
  [CodigoManejo]           NVARCHAR(10)     NULL,
  [ManejoDescripcion]      NVARCHAR(40)     NULL,
  [Centro]                 NVARCHAR(10)     NULL,
  [Almacen]                NVARCHAR(10)     NULL,
  [AlmacenDescripcion]     NVARCHAR(40)     NULL,
  [VariedadAgronomica]     NVARCHAR(10)     NULL,
  [VariedadAgronomicaDescripcion] NVARCHAR(40) NULL,
  [TipoVariedad]           NVARCHAR(10)     NULL,
  [TipoVariedadDescripcion] NVARCHAR(40)    NULL,
  [TipoFrio]               NVARCHAR(10)     NULL,
  [TipoFrioDescripcion]    NVARCHAR(40)     NULL,
  [Destino]                NVARCHAR(10)     NULL,
  [DestinoDescripcion]     NVARCHAR(40)     NULL,
  [LineaProduccion]        NVARCHAR(20)     NULL,
  [FechaCosecha]           DATE             NULL,
  [PSA]                    NVARCHAR(20)     NULL,
  [GGN]                    NVARCHAR(20)     NULL,
  [SDP]                    NVARCHAR(10)     NULL,
  [UnidadMadurez]          NVARCHAR(20)     NULL,
  [Cuartel]                NVARCHAR(20)     NULL,
  [ExportadorMP]           NVARCHAR(20)     NULL,
  [ExportadorMPDescripcion] NVARCHAR(80)    NULL,
  [PesoPromedioEnvase]     NVARCHAR(20)     NULL,
  [PesoRealEnvase]         NVARCHAR(20)     NULL,
  [CantidadSubEnvaseL]     DECIMAL(15,3)    NULL,
  [PesoEnvase]             DECIMAL(15,3)    NULL,
  [PesoSubEnvase]          DECIMAL(15,3)    NULL,
  [CantidadSubEnvaseV]     DECIMAL(15,3)    NULL,

  PRIMARY KEY ([IdRomanaDetalleRaw])
);
GO

CREATE INDEX [IX_RomanaDetalleRaw_IdEjecucion]
  ON [cfl].[RomanaDetalleRaw] ([IdEjecucion]);
CREATE INDEX [IX_RomanaDetalleRaw_BkFecha]
  ON [cfl].[RomanaDetalleRaw] ([SistemaFuente], [NumeroPartida], [GuiaDespacho], [Posicion], [FechaExtraccion]);
CREATE UNIQUE INDEX [UQ_RomanaDetalleRaw_BkHash]
  ON [cfl].[RomanaDetalleRaw] ([SistemaFuente], [NumeroPartida], [GuiaDespacho], [Posicion], [HashFila]);
GO

-- ============================================================
-- STAGING: StgRomanaCabecera + StgRomanaDetalle
-- ============================================================
CREATE TABLE [cfl].[StgRomanaCabecera] (
  [IdEjecucion]            UNIQUEIDENTIFIER NOT NULL,
  [FechaExtraccion]        DATETIME2(0)     NOT NULL,
  [SistemaFuente]          NVARCHAR(50)     NOT NULL,
  [HashFila]               BINARY(32)       NOT NULL,
  [EstadoFila]             NVARCHAR(20)     NOT NULL,
  [FechaCreacion]          DATETIME2(0)     NOT NULL,
  [IdRomana]               NVARCHAR(20)     NOT NULL,
  [NumeroPartida]          NVARCHAR(20)     NULL,
  [GuiaDespacho]           NVARCHAR(30)     NULL,
  [TipoDocumento]          NVARCHAR(10)     NULL,
  [TipoDocumentoTexto]     NVARCHAR(40)     NULL,
  [EstadoRomana]           NVARCHAR(10)     NULL,
  [EstadoRomanaTexto]      NVARCHAR(40)     NULL,
  [Patente]                NVARCHAR(20)     NULL,
  [Carro]                  NVARCHAR(20)     NULL,
  [Conductor]              NVARCHAR(80)     NULL,
  [CreadoPor]              NVARCHAR(12)     NULL,
  [CreadoPorNombre]        NVARCHAR(80)     NULL,
  [FechaCreacionSap]       DATE             NULL,
  [FechaModificacionSap]   DATE             NULL,
  [OrdenCompra]            NVARCHAR(20)     NULL,
  [CodigoProductor]        NVARCHAR(20)     NULL,
  [Centro]                 NVARCHAR(10)     NULL,
  [CentroNombre]           NVARCHAR(40)     NULL,
  [PlantaDestino]          NVARCHAR(10)     NULL,
  [PlantaDestinoNombre]    NVARCHAR(40)     NULL,
  [AlmacenDestino]         NVARCHAR(10)     NULL,
  [AlmacenDestinoNombre]   NVARCHAR(40)     NULL,
  [Temporada]              NVARCHAR(10)     NULL,
  [CSG]                    NVARCHAR(20)     NULL,
  [GuiaAlterna]            NVARCHAR(30)     NULL,
  [ProductorDescripcion]   NVARCHAR(80)     NULL,
  [ProductorDireccion]     NVARCHAR(150)    NULL,
  [ProductorComuna]        NVARCHAR(60)     NULL,
  [ProductorProvincia]     NVARCHAR(60)     NULL,
  [PeticionBorrado]        BIT              NOT NULL DEFAULT 0,
  [ActualizadoPor]         NVARCHAR(12)     NULL,
  [ActualizadoPorNombre]   NVARCHAR(80)     NULL
);
GO
CREATE INDEX [IX_StgRomanaCabecera_Ejecucion] ON [cfl].[StgRomanaCabecera] ([IdEjecucion]);
GO

CREATE TABLE [cfl].[StgRomanaDetalle] (
  [IdEjecucion]            UNIQUEIDENTIFIER NOT NULL,
  [FechaExtraccion]        DATETIME2(0)     NOT NULL,
  [SistemaFuente]          NVARCHAR(50)     NOT NULL,
  [HashFila]               BINARY(32)       NOT NULL,
  [EstadoFila]             NVARCHAR(20)     NOT NULL,
  [FechaCreacion]          DATETIME2(0)     NOT NULL,
  [NumeroPartida]          NVARCHAR(20)     NOT NULL,
  [GuiaDespacho]           NVARCHAR(30)     NOT NULL,
  [Posicion]               NVARCHAR(10)     NOT NULL,
  [Material]               NVARCHAR(40)     NULL,
  [MaterialDescripcion]    NVARCHAR(40)     NULL,
  [Lote]                   NVARCHAR(20)     NULL,
  [PesoReal]               DECIMAL(15,3)    NOT NULL DEFAULT 0,
  [UnidadMedida]           NVARCHAR(5)      NULL,
  [Envase]                 NVARCHAR(20)     NULL,
  [EnvaseDescripcion]      NVARCHAR(40)     NULL,
  [SubEnvase]              NVARCHAR(20)     NULL,
  [SubEnvaseDescripcion]   NVARCHAR(40)     NULL,
  [PosicionOrdenCompra]    NVARCHAR(10)     NULL,
  [CodigoEspecie]          NVARCHAR(10)     NULL,
  [EspecieDescripcion]     NVARCHAR(40)     NULL,
  [CodigoGrupoVariedad]    NVARCHAR(10)     NULL,
  [GrupoVariedadDescripcion] NVARCHAR(40)   NULL,
  [CodigoManejo]           NVARCHAR(10)     NULL,
  [ManejoDescripcion]      NVARCHAR(40)     NULL,
  [Centro]                 NVARCHAR(10)     NULL,
  [Almacen]                NVARCHAR(10)     NULL,
  [AlmacenDescripcion]     NVARCHAR(40)     NULL,
  [VariedadAgronomica]     NVARCHAR(10)     NULL,
  [VariedadAgronomicaDescripcion] NVARCHAR(40) NULL,
  [TipoVariedad]           NVARCHAR(10)     NULL,
  [TipoVariedadDescripcion] NVARCHAR(40)    NULL,
  [TipoFrio]               NVARCHAR(10)     NULL,
  [TipoFrioDescripcion]    NVARCHAR(40)     NULL,
  [Destino]                NVARCHAR(10)     NULL,
  [DestinoDescripcion]     NVARCHAR(40)     NULL,
  [LineaProduccion]        NVARCHAR(20)     NULL,
  [FechaCosecha]           DATE             NULL,
  [PSA]                    NVARCHAR(20)     NULL,
  [GGN]                    NVARCHAR(20)     NULL,
  [SDP]                    NVARCHAR(10)     NULL,
  [UnidadMadurez]          NVARCHAR(20)     NULL,
  [Cuartel]                NVARCHAR(20)     NULL,
  [ExportadorMP]           NVARCHAR(20)     NULL,
  [ExportadorMPDescripcion] NVARCHAR(80)    NULL,
  [PesoPromedioEnvase]     NVARCHAR(20)     NULL,
  [PesoRealEnvase]         NVARCHAR(20)     NULL,
  [CantidadSubEnvaseL]     DECIMAL(15,3)    NULL,
  [PesoEnvase]             DECIMAL(15,3)    NULL,
  [PesoSubEnvase]          DECIMAL(15,3)    NULL,
  [CantidadSubEnvaseV]     DECIMAL(15,3)    NULL
);
GO
CREATE INDEX [IX_StgRomanaDetalle_Ejecucion] ON [cfl].[StgRomanaDetalle] ([IdEjecucion]);
GO

-- ============================================================
-- CANONICAL: RomanaEntrega
-- Clave natural: (NumeroPartida, GuiaDespacho, SistemaFuente)
-- ============================================================
CREATE TABLE [cfl].[RomanaEntrega] (
  [IdRomanaEntrega]                BIGINT NOT NULL IDENTITY UNIQUE,
  [NumeroPartida]                  NVARCHAR(20)     NOT NULL,
  [GuiaDespacho]                   NVARCHAR(30)     NOT NULL,
  [SistemaFuente]                  NVARCHAR(50)     NOT NULL,
  [FechaCreacion]                  DATETIME2(0)     NOT NULL,
  [FechaActualizacion]             DATETIME2(0)     NOT NULL,
  [Bloqueado]                      BIT NOT NULL DEFAULT 0,
  [FechaBloqueado]                 DATETIME2(0) NULL,
  [CambiadoEnUltimaEjecucion]     BIT NOT NULL DEFAULT 0,
  [FechaUltimoCambio]              DATETIME2(0) NULL,
  [TipoUltimoCambio]               NVARCHAR(20) NULL,
  [IdEjecucionUltimaVista]         UNIQUEIDENTIFIER NULL,
  [FechaUltimaVista]               DATETIME2(0) NULL,
  [IdEjecucionUltimoCambio]        UNIQUEIDENTIFIER NULL,
  [FechaExtraccionUltimoCambio]    DATETIME2(0) NULL,
  [IdUltimoCabeceraRaw]            BIGINT NULL,
  [HashUltimoCabeceraRaw]          BINARY(32) NULL,
  PRIMARY KEY ([IdRomanaEntrega])
);
GO
CREATE UNIQUE INDEX [UQ_RomanaEntrega_Bk]
  ON [cfl].[RomanaEntrega] ([NumeroPartida], [GuiaDespacho], [SistemaFuente]);
CREATE INDEX [IX_RomanaEntrega_NumeroPartida]
  ON [cfl].[RomanaEntrega] ([NumeroPartida]);
CREATE INDEX [IX_RomanaEntrega_GuiaDespacho]
  ON [cfl].[RomanaEntrega] ([GuiaDespacho]);
GO

-- ============================================================
-- CANONICAL: RomanaEntregaHistorial
-- ============================================================
CREATE TABLE [cfl].[RomanaEntregaHistorial] (
  [IdRomanaEntregaHistorial] BIGINT NOT NULL IDENTITY UNIQUE,
  [IdRomanaEntrega]          BIGINT NOT NULL,
  [IdRomanaCabeceraRaw]      BIGINT NOT NULL,
  [IdEjecucion]              UNIQUEIDENTIFIER NOT NULL,
  [FechaExtraccion]          DATETIME2(0) NOT NULL,
  [FechaCreacion]            DATETIME2(0) NOT NULL,
  PRIMARY KEY ([IdRomanaEntregaHistorial])
);
GO
CREATE INDEX [IX_RomanaEntregaHistorial_IdEntrega]
  ON [cfl].[RomanaEntregaHistorial] ([IdRomanaEntrega]);
CREATE UNIQUE INDEX [UQ_RomanaEntregaHistorial_IdRaw]
  ON [cfl].[RomanaEntregaHistorial] ([IdRomanaCabeceraRaw]);
GO

-- ============================================================
-- CANONICAL: RomanaEntregaPosicion
-- ============================================================
CREATE TABLE [cfl].[RomanaEntregaPosicion] (
  [IdRomanaEntregaPosicion] BIGINT NOT NULL IDENTITY UNIQUE,
  [IdRomanaEntrega]         BIGINT NOT NULL,
  [Posicion]                NVARCHAR(10) NOT NULL,
  [FechaCreacion]           DATETIME2(0) NOT NULL,
  [FechaActualizacion]      DATETIME2(0) NOT NULL,
  [Estado]                  NVARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  [AusenteDesde]            DATETIME2(0) NULL,
  [CambiadoEnUltimaEjecucion] BIT NOT NULL DEFAULT 0,
  [FechaUltimoCambio]       DATETIME2(0) NULL,
  [TipoUltimoCambio]        NVARCHAR(20) NULL,
  [IdEjecucionUltimoCambio] UNIQUEIDENTIFIER NULL,
  [IdEjecucionUltimaVista]  UNIQUEIDENTIFIER NULL,
  [FechaUltimaVista]        DATETIME2(0) NULL,
  PRIMARY KEY ([IdRomanaEntregaPosicion])
);
GO
CREATE UNIQUE INDEX [UQ_RomanaEntregaPosicion_Bk]
  ON [cfl].[RomanaEntregaPosicion] ([IdRomanaEntrega], [Posicion]);
GO

-- ============================================================
-- CANONICAL: RomanaEntregaPosicionHistorial
-- ============================================================
CREATE TABLE [cfl].[RomanaEntregaPosicionHistorial] (
  [IdRomanaEntregaPosicionHistorial] BIGINT NOT NULL IDENTITY UNIQUE,
  [IdRomanaEntregaPosicion] BIGINT NOT NULL,
  [IdRomanaDetalleRaw]      BIGINT NOT NULL,
  [IdEjecucion]             UNIQUEIDENTIFIER NOT NULL,
  [FechaExtraccion]         DATETIME2(0) NOT NULL,
  [FechaCreacion]           DATETIME2(0) NOT NULL,
  PRIMARY KEY ([IdRomanaEntregaPosicionHistorial])
);
GO
CREATE UNIQUE INDEX [UQ_RomanaEntregaPosHist_IdRaw]
  ON [cfl].[RomanaEntregaPosicionHistorial] ([IdRomanaDetalleRaw]);
CREATE INDEX [IX_RomanaEntregaPosHist_IdPos]
  ON [cfl].[RomanaEntregaPosicionHistorial] ([IdRomanaEntregaPosicion]);
GO

-- ============================================================
-- RomanaEntregaDescarte
-- ============================================================
CREATE TABLE [cfl].[RomanaEntregaDescarte] (
  [IdRomanaEntregaDescarte] BIGINT NOT NULL IDENTITY UNIQUE,
  [IdRomanaEntrega]         BIGINT NOT NULL,
  [Activo]                  BIT NOT NULL DEFAULT 1,
  [Motivo]                  NVARCHAR(200) NULL,
  [FechaCreacion]           DATETIME2(0) NOT NULL,
  [FechaActualizacion]      DATETIME2(0) NOT NULL,
  [CreadoPor]               BIGINT NULL,
  [FechaRestauracion]       DATETIME2(0) NULL,
  [RestauradoPor]           BIGINT NULL,
  PRIMARY KEY ([IdRomanaEntregaDescarte])
);
GO
CREATE UNIQUE INDEX [UQ_RomanaEntregaDescarte_IdEntrega]
  ON [cfl].[RomanaEntregaDescarte] ([IdRomanaEntrega]);
CREATE INDEX [IX_RomanaEntregaDescarte_Activo]
  ON [cfl].[RomanaEntregaDescarte] ([Activo], [IdRomanaEntrega]);
GO

-- ============================================================
-- FleteRomanaEntrega (bridge)
-- ============================================================
CREATE TABLE [cfl].[FleteRomanaEntrega] (
  [IdFleteRomanaEntrega]  BIGINT NOT NULL IDENTITY UNIQUE,
  [IdCabeceraFlete]       BIGINT NOT NULL,
  [IdRomanaEntrega]       BIGINT NOT NULL,
  [OrigenDatos]           NVARCHAR(10) NOT NULL DEFAULT 'ROMANA',
  [TipoRelacion]          NVARCHAR(20) NOT NULL DEFAULT 'PRINCIPAL',
  [FechaCreacion]         DATETIME2(0) NOT NULL,
  [CreadoPor]             BIGINT NULL,
  PRIMARY KEY ([IdFleteRomanaEntrega])
);
GO
CREATE UNIQUE INDEX [UQ_FleteRomanaEntrega_Bridge]
  ON [cfl].[FleteRomanaEntrega] ([IdCabeceraFlete], [IdRomanaEntrega]);
GO

-- ============================================================
-- FOREIGN KEYS
-- ============================================================
ALTER TABLE [cfl].[FleteRomanaEntrega] ADD CONSTRAINT [FK_FleteRomanaEntrega_Flete]
  FOREIGN KEY ([IdCabeceraFlete]) REFERENCES [cfl].[CabeceraFlete] ([IdCabeceraFlete]);
ALTER TABLE [cfl].[FleteRomanaEntrega] ADD CONSTRAINT [FK_FleteRomanaEntrega_Romana]
  FOREIGN KEY ([IdRomanaEntrega]) REFERENCES [cfl].[RomanaEntrega] ([IdRomanaEntrega]);
GO
ALTER TABLE [cfl].[RomanaEntregaHistorial] ADD CONSTRAINT [FK_RomanaEntregaHist_Entrega]
  FOREIGN KEY ([IdRomanaEntrega]) REFERENCES [cfl].[RomanaEntrega] ([IdRomanaEntrega]);
ALTER TABLE [cfl].[RomanaEntregaHistorial] ADD CONSTRAINT [FK_RomanaEntregaHist_Raw]
  FOREIGN KEY ([IdRomanaCabeceraRaw]) REFERENCES [cfl].[RomanaCabeceraRaw] ([IdRomanaCabeceraRaw]);
GO
ALTER TABLE [cfl].[RomanaEntregaPosicion] ADD CONSTRAINT [FK_RomanaEntregaPos_Entrega]
  FOREIGN KEY ([IdRomanaEntrega]) REFERENCES [cfl].[RomanaEntrega] ([IdRomanaEntrega]);
GO
ALTER TABLE [cfl].[RomanaEntregaPosicionHistorial] ADD CONSTRAINT [FK_RomanaEntregaPosHist_Pos]
  FOREIGN KEY ([IdRomanaEntregaPosicion]) REFERENCES [cfl].[RomanaEntregaPosicion] ([IdRomanaEntregaPosicion]);
ALTER TABLE [cfl].[RomanaEntregaPosicionHistorial] ADD CONSTRAINT [FK_RomanaEntregaPosHist_Raw]
  FOREIGN KEY ([IdRomanaDetalleRaw]) REFERENCES [cfl].[RomanaDetalleRaw] ([IdRomanaDetalleRaw]);
GO
ALTER TABLE [cfl].[RomanaEntregaDescarte] ADD CONSTRAINT [FK_RomanaEntregaDescarte_Entrega]
  FOREIGN KEY ([IdRomanaEntrega]) REFERENCES [cfl].[RomanaEntrega] ([IdRomanaEntrega]);
GO

-- ============================================================
-- VISTAS
-- ============================================================
CREATE VIEW [cfl].[VW_RomanaCabeceraActual] AS
WITH ranked AS (
  SELECT r.*,
    rn = ROW_NUMBER() OVER (
      PARTITION BY r.SistemaFuente, r.NumeroPartida, r.GuiaDespacho
      ORDER BY r.FechaExtraccion DESC, r.IdRomanaCabeceraRaw DESC
    )
  FROM [cfl].[RomanaCabeceraRaw] r
  WHERE r.EstadoFila = 'ACTIVE'
)
SELECT * FROM ranked WHERE rn = 1;
GO

CREATE VIEW [cfl].[VW_RomanaDetalleActual] AS
WITH ranked AS (
  SELECT r.*,
    rn = ROW_NUMBER() OVER (
      PARTITION BY r.SistemaFuente, r.NumeroPartida, r.GuiaDespacho, r.Posicion, r.Lote
      ORDER BY r.FechaExtraccion DESC, r.IdRomanaDetalleRaw DESC
    )
  FROM [cfl].[RomanaDetalleRaw] r
  WHERE r.EstadoFila = 'ACTIVE'
)
SELECT * FROM ranked WHERE rn = 1;
GO
