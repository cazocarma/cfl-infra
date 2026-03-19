/* ============================================================================
   ESQUEMA: cfl
   Convencion de nombres (PascalCase + español):
   - Tablas:      cfl.<NombreSingular>          (sin prefijo CFL_)
   - Columnas:    PascalCase español             (ej. FechaCreacion)
   - PK:          PK_<Tabla>
   - FK:          FK_<Tabla>_<TablaRef>          (+ rol si hay ambiguedad)
   - UNIQUE idx:  UQ_<Tabla>_<Columna>
   - Indices:     IX_<Tabla>_<Columna>
   - Vistas:      VW_<Nombre>
   - Funciones:   Fn_<Nombre>
============================================================================ */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'cfl')
    EXEC('CREATE SCHEMA [cfl] AUTHORIZATION [dbo];');
GO

/* ============================================================
   TABLA: cfl.EtlEjecucion  (ex CFL_etl_run)
============================================================ */
CREATE TABLE [cfl].[EtlEjecucion] (
    [IdEtlEjecucion]    BIGINT IDENTITY UNIQUE,
    [IdEjecucion]       UNIQUEIDENTIFIER NOT NULL UNIQUE,
    [SistemaFuente]     NVARCHAR(50)  NOT NULL,
    [NombreFuente]      NVARCHAR(100) NOT NULL,
    [FechaExtraccion]   DATETIME2(0) NOT NULL,
    [MarcaAguaDesde]    DATETIME2(0) NULL,
    [MarcaAguaHasta]    DATETIME2(0) NULL,
    [Estado]            NVARCHAR(20)  NOT NULL,
    [FilasExtraidas]    INT NULL,
    [FilasInsertadas]   INT NULL,
    [FilasActualizadas] INT NULL,
    [FilasSinCambio]    INT NULL,
    [MensajeError]      NVARCHAR(4000) NULL,
    [FechaCreacion]     DATETIME2(0) NOT NULL,
    [TipoProceso]       NVARCHAR(50) NULL,
    [ParametrosJson]    NVARCHAR(MAX) NULL,
    [ResumenJson]       NVARCHAR(MAX) NULL,
    [FechaInicioProceso] DATETIME2(0) NULL,
    [FechaFinProceso]   DATETIME2(0) NULL,
    PRIMARY KEY ([IdEtlEjecucion])
);
GO

CREATE INDEX [IX_EtlEjecucion_TipoProcesoEstadoFecha]
ON [cfl].[EtlEjecucion] ([TipoProceso], [Estado], [FechaCreacion] DESC);
GO

/* ============================================================
   TABLA: cfl.SapLikpRaw  (ex CFL_sap_likp_raw)
   + columna nueva: SapDestinatario (después de SapPuestoExpedicion)
============================================================ */
CREATE TABLE [cfl].[SapLikpRaw] (
    [IdSapLikpRaw]          BIGINT IDENTITY UNIQUE,
    [IdEjecucion]           UNIQUEIDENTIFIER NOT NULL,
    [FechaExtraccion]       DATETIME2(0) NOT NULL,
    [SistemaFuente]         NVARCHAR(50)  NOT NULL,
    [HashFila]              BINARY(32)   NOT NULL,
    [EstadoFila]            NVARCHAR(20)  NOT NULL,
    [FechaCreacion]         DATETIME2(0) NOT NULL,

    [SapNumeroEntrega]      NVARCHAR(20)  NOT NULL,
    [SapReferencia]         CHAR(25)     NOT NULL,
    [SapPuestoExpedicion]   CHAR(4)      NOT NULL,
    [SapDestinatario]       NVARCHAR(20) NULL,
    [SapOrganizacionVentas] CHAR(4)      NOT NULL,
    [SapCreadoPor]          CHAR(12)     NOT NULL,
    [SapFechaCreacion]      DATE         NOT NULL,
    [SapClaseEntrega]       CHAR(4)      NOT NULL,
    [SapTipoEntrega]        NVARCHAR(20)  NOT NULL,
    [SapFechaCarga]         DATE         NOT NULL,
    [SapHoraCarga]          TIME         NOT NULL,
    [SapGuiaRemision]       CHAR(25)     NOT NULL,
    [SapNombreChofer]       NVARCHAR(40)  NOT NULL,
    [SapIdFiscalChofer]     NVARCHAR(20)  NOT NULL,
    [SapEmpresaTransporte]  CHAR(3)      NOT NULL,
    [SapPatente]            NVARCHAR(20)  NOT NULL,
    [SapCarro]              NVARCHAR(20)  NOT NULL,
    [SapFechaSalida]        DATE         NOT NULL,
    [SapHoraSalida]         TIME         NOT NULL,
    [SapCodigoTipoFlete]    CHAR(4)      NOT NULL,
    [SapCentroCosto]        CHAR(10)     NULL,
    [SapCuentaMayor]        CHAR(10)     NULL,
    [SapPesoTotal]          DECIMAL(15,3) NOT NULL,
    [SapPesoNeto]           DECIMAL(15,3) NOT NULL,
    [SapFechaEntregaReal]   DATE         NOT NULL,

    PRIMARY KEY ([IdSapLikpRaw])
);
GO

CREATE INDEX [IX_SapLikpRaw_IdEjecucion]
ON [cfl].[SapLikpRaw] ([IdEjecucion]);
GO

CREATE INDEX [IX_SapLikpRaw_BkFecha]
ON [cfl].[SapLikpRaw] ([SistemaFuente], [SapNumeroEntrega], [FechaExtraccion]);
GO

CREATE UNIQUE INDEX [UQ_SapLikpRaw_BkHash]
ON [cfl].[SapLikpRaw] ([SistemaFuente], [SapNumeroEntrega], [HashFila]);
GO

/* ============================================================
   TABLA: cfl.SapLipsRaw  (ex CFL_sap_lips_raw)
============================================================ */
CREATE TABLE [cfl].[SapLipsRaw] (
    [IdSapLipsRaw]              BIGINT IDENTITY UNIQUE,
    [IdEjecucion]               UNIQUEIDENTIFIER NOT NULL,
    [FechaExtraccion]           DATETIME2(0) NOT NULL,
    [SistemaFuente]             NVARCHAR(50)  NOT NULL,
    [HashFila]                  BINARY(32)   NOT NULL,
    [EstadoFila]                NVARCHAR(20)  NOT NULL,
    [FechaCreacion]             DATETIME2(0) NOT NULL,

    [SapNumeroEntrega]          NVARCHAR(20)  NOT NULL,
    [SapPosicion]               CHAR(6)      NOT NULL,
    [SapMaterial]               NVARCHAR(40)  NOT NULL,
    [SapCantidadEntregada]      DECIMAL(13,3) NOT NULL,
    [SapUnidadPeso]             CHAR(3)      NOT NULL,
    [SapDenominacionMaterial]   NVARCHAR(40)  NOT NULL,
    [SapCentro]                 CHAR(4)      NOT NULL,
    [SapAlmacen]                CHAR(4)      NOT NULL,
    [SapPosicionSuperior]       CHAR(6)      NULL,  -- UEPOS: soporte detalles extendidos
    [SapLote]                   NVARCHAR(20)  NULL,  -- CHARG

    PRIMARY KEY ([IdSapLipsRaw])
);
GO

CREATE INDEX [IX_SapLipsRaw_IdEjecucion]
ON [cfl].[SapLipsRaw] ([IdEjecucion]);
GO

CREATE INDEX [IX_SapLipsRaw_BkFecha]
ON [cfl].[SapLipsRaw] ([SistemaFuente], [SapNumeroEntrega], [SapPosicion], [FechaExtraccion]);
GO

CREATE INDEX [IX_SapLipsRaw_VbelnUepos]
ON [cfl].[SapLipsRaw] ([SistemaFuente], [SapNumeroEntrega], [SapPosicionSuperior]);
GO

CREATE UNIQUE INDEX [UQ_SapLipsRaw_BkHash]
ON [cfl].[SapLipsRaw] ([SistemaFuente], [SapNumeroEntrega], [SapPosicion], [HashFila]);
GO

/* ============================================================
   TABLA: cfl.SapEntrega  (ex CFL_sap_entrega)
============================================================ */
CREATE TABLE [cfl].[SapEntrega] (
    [IdSapEntrega]                  BIGINT NOT NULL IDENTITY UNIQUE,
    [SapNumeroEntrega]              NVARCHAR(20)      NOT NULL,
    [SistemaFuente]                 NVARCHAR(50)      NOT NULL,
    [FechaCreacion]                 DATETIME2(0)     NOT NULL,
    [FechaActualizacion]            DATETIME2(0)     NOT NULL,

    [Bloqueado]                     BIT NOT NULL CONSTRAINT [DF_SapEntrega_Bloqueado] DEFAULT(0),
    [FechaBloqueado]                DATETIME2(0)     NULL,

    [CambiadoEnUltimaEjecucion]     BIT NOT NULL CONSTRAINT [DF_SapEntrega_CambiadoEnUltimaEjecucion] DEFAULT(0),
    [FechaUltimoCambio]             DATETIME2(0)     NULL,
    [TipoUltimoCambio]              NVARCHAR(20)      NULL,

    [IdEjecucionUltimaVista]        UNIQUEIDENTIFIER NULL,
    [FechaUltimaVista]              DATETIME2(0)     NULL,

    [IdEjecucionUltimoCambio]       UNIQUEIDENTIFIER NULL,
    [FechaExtraccionUltimoCambio]   DATETIME2(0)     NULL,

    [IdUltimoLikpRaw]               BIGINT           NULL,
    [HashUltimoLikpRaw]             BINARY(32)       NULL,
    PRIMARY KEY ([IdSapEntrega])
);
GO

CREATE UNIQUE INDEX [UQ_SapEntrega_Bk]
ON [cfl].[SapEntrega] ([SapNumeroEntrega], [SistemaFuente]);
GO

CREATE INDEX [IX_SapEntrega_NumeroEntrega]
ON [cfl].[SapEntrega] ([SapNumeroEntrega]);
GO

/* ============================================================
   TABLA: cfl.SapEntregaHistorial  (ex CFL_sap_entrega_hist)
============================================================ */
CREATE TABLE [cfl].[SapEntregaHistorial] (
    [IdSapEntregaHistorial] BIGINT NOT NULL IDENTITY UNIQUE,
    [IdSapEntrega]          BIGINT           NOT NULL,
    [IdLikpRaw]             BIGINT           NOT NULL,
    [IdEjecucion]           UNIQUEIDENTIFIER NOT NULL,
    [FechaExtraccion]       DATETIME2(0)     NOT NULL,
    [FechaCreacion]         DATETIME2(0)     NOT NULL,
    PRIMARY KEY ([IdSapEntregaHistorial])
);
GO

CREATE INDEX [IX_SapEntregaHistorial_IdSapEntrega]
ON [cfl].[SapEntregaHistorial] ([IdSapEntrega]);
GO

CREATE UNIQUE INDEX [UQ_SapEntregaHistorial_IdLikpRaw]
ON [cfl].[SapEntregaHistorial] ([IdLikpRaw]);
GO

/* ============================================================
   TABLA: cfl.SapEntregaPosicion  (ex CFL_sap_entrega_posicion)
============================================================ */
CREATE TABLE [cfl].[SapEntregaPosicion] (
    [IdSapEntregaPosicion]          BIGINT NOT NULL IDENTITY UNIQUE,
    [IdSapEntrega]                  BIGINT       NOT NULL,
    [SapPosicion]                   CHAR(6)      NOT NULL,
    [FechaCreacion]                 DATETIME2(0) NOT NULL,
    [FechaActualizacion]            DATETIME2(0) NOT NULL,
    [Estado]                        NVARCHAR(20)  NOT NULL CONSTRAINT [DF_SapEntregaPosicion_Estado] DEFAULT('ACTIVE'),
    [AusenteDesde]                  DATETIME2(0) NULL,

    [CambiadoEnUltimaEjecucion]     BIT NOT NULL CONSTRAINT [DF_SapEntregaPosicion_CambiadoEnUltimaEjecucion] DEFAULT(0),
    [FechaUltimoCambio]             DATETIME2(0) NULL,
    [TipoUltimoCambio]              NVARCHAR(20)  NULL,

    [IdEjecucionUltimaVista]        UNIQUEIDENTIFIER NULL,
    [FechaUltimaVista]              DATETIME2(0)     NULL,

    [IdEjecucionUltimoCambio]       UNIQUEIDENTIFIER NULL,
    [FechaExtraccionUltimoCambio]   DATETIME2(0)     NULL,

    [IdUltimoLipsRaw]               BIGINT           NULL,
    [HashUltimoLipsRaw]             BINARY(32)       NULL,
    PRIMARY KEY ([IdSapEntregaPosicion])
);
GO

CREATE UNIQUE INDEX [UQ_SapEntregaPosicion_Bk]
ON [cfl].[SapEntregaPosicion] ([IdSapEntrega], [SapPosicion]);
GO

/* ============================================================
   TABLA: cfl.SapEntregaPosicionHistorial  (ex CFL_sap_entrega_posicion_hist)
============================================================ */
CREATE TABLE [cfl].[SapEntregaPosicionHistorial] (
    [IdSapEntregaPosicionHistorial] BIGINT NOT NULL IDENTITY UNIQUE,
    [IdSapEntregaPosicion]          BIGINT           NOT NULL,
    [IdLipsRaw]                     BIGINT           NOT NULL,
    [IdEjecucion]                   UNIQUEIDENTIFIER NOT NULL,
    [FechaExtraccion]               DATETIME2(0)     NOT NULL,
    [FechaCreacion]                 DATETIME2(0)     NOT NULL,
    PRIMARY KEY ([IdSapEntregaPosicionHistorial])
);
GO

CREATE UNIQUE INDEX [UQ_SapEntregaPosicionHistorial_IdLipsRaw]
ON [cfl].[SapEntregaPosicionHistorial] ([IdLipsRaw]);
GO

CREATE INDEX [IX_SapEntregaPosicionHistorial_IdPosicion]
ON [cfl].[SapEntregaPosicionHistorial] ([IdSapEntregaPosicion]);
GO

/* ============================================================
   TABLA: cfl.SapEntregaDescarte  (ex CFL_sap_entrega_descarte)
============================================================ */
CREATE TABLE [cfl].[SapEntregaDescarte] (
    [IdSapEntregaDescarte]  BIGINT NOT NULL IDENTITY UNIQUE,
    [IdSapEntrega]          BIGINT       NOT NULL,
    [Activo]                BIT NOT NULL CONSTRAINT [DF_SapEntregaDescarte_Activo] DEFAULT(1),
    [Motivo]                NVARCHAR(200) NULL,
    [FechaCreacion]         DATETIME2(0) NOT NULL,
    [FechaActualizacion]    DATETIME2(0) NOT NULL,
    [CreadoPor]             BIGINT       NULL,
    [FechaRestauracion]     DATETIME2(0) NULL,
    [RestauradoPor]         BIGINT       NULL,
    PRIMARY KEY ([IdSapEntregaDescarte])
);
GO

CREATE UNIQUE INDEX [UQ_SapEntregaDescarte_IdSapEntrega]
ON [cfl].[SapEntregaDescarte] ([IdSapEntrega]);
GO

CREATE INDEX [IX_SapEntregaDescarte_Activo]
ON [cfl].[SapEntregaDescarte] ([Activo], [IdSapEntrega]);
GO

/* ============================================================
   TABLAS: staging permanentes para pipeline SAP on-demand
============================================================ */

CREATE TABLE [cfl].[StgLikp] (
    [IdEjecucion]           UNIQUEIDENTIFIER NOT NULL,
    [FechaExtraccion]       DATETIME2(0)     NOT NULL,
    [SistemaFuente]         NVARCHAR(50)     NOT NULL,
    [HashFila]              BINARY(32)       NOT NULL,
    [EstadoFila]            NVARCHAR(20)     NOT NULL,
    [FechaCreacion]         DATETIME2(0)     NOT NULL,
    [SapNumeroEntrega]      NVARCHAR(20)     NOT NULL,
    [SapReferencia]         CHAR(25)         NOT NULL,
    [SapPuestoExpedicion]   CHAR(4)          NOT NULL,
    [SapDestinatario]       NVARCHAR(20)     NULL,
    [SapOrganizacionVentas] CHAR(4)          NOT NULL,
    [SapCreadoPor]          CHAR(12)         NOT NULL,
    [SapFechaCreacion]      DATE             NOT NULL,
    [SapClaseEntrega]       CHAR(4)          NOT NULL,
    [SapTipoEntrega]        NVARCHAR(20)     NOT NULL,
    [SapFechaCarga]         DATE             NOT NULL,
    [SapHoraCarga]          VARCHAR(8)       NOT NULL,
    [SapGuiaRemision]       CHAR(25)         NOT NULL,
    [SapNombreChofer]       NVARCHAR(40)     NOT NULL,
    [SapIdFiscalChofer]     NVARCHAR(20)     NOT NULL,
    [SapEmpresaTransporte]  CHAR(3)          NOT NULL,
    [SapPatente]            NVARCHAR(20)     NOT NULL,
    [SapCarro]              NVARCHAR(20)     NOT NULL,
    [SapFechaSalida]        DATE             NOT NULL,
    [SapHoraSalida]         VARCHAR(8)       NOT NULL,
    [SapCodigoTipoFlete]    CHAR(4)          NOT NULL,
    [SapCentroCosto]        CHAR(10)         NULL,
    [SapCuentaMayor]        CHAR(10)         NULL,
    [SapPesoTotal]          DECIMAL(15,3)    NOT NULL,
    [SapPesoNeto]           DECIMAL(15,3)    NOT NULL,
    [SapFechaEntregaReal]   DATE             NOT NULL
);
GO

CREATE INDEX [IX_StgLikp_Ejecucion]
ON [cfl].[StgLikp] ([IdEjecucion]);
GO

CREATE TABLE [cfl].[StgLips] (
    [IdEjecucion]             UNIQUEIDENTIFIER NOT NULL,
    [FechaExtraccion]         DATETIME2(0)     NOT NULL,
    [SistemaFuente]           NVARCHAR(50)     NOT NULL,
    [HashFila]                BINARY(32)       NOT NULL,
    [EstadoFila]              NVARCHAR(20)     NOT NULL,
    [FechaCreacion]           DATETIME2(0)     NOT NULL,
    [SapNumeroEntrega]        NVARCHAR(20)     NOT NULL,
    [SapPosicion]             CHAR(6)          NOT NULL,
    [SapPosicionSuperior]     CHAR(6)          NULL,
    [SapLote]                 NVARCHAR(20)     NULL,
    [SapMaterial]             NVARCHAR(40)     NOT NULL,
    [SapCantidadEntregada]    DECIMAL(13,3)    NOT NULL,
    [SapUnidadPeso]           CHAR(3)          NOT NULL,
    [SapDenominacionMaterial] NVARCHAR(40)     NOT NULL,
    [SapCentro]               CHAR(4)          NOT NULL,
    [SapAlmacen]              CHAR(4)          NOT NULL
);
GO

CREATE INDEX [IX_StgLips_Ejecucion]
ON [cfl].[StgLips] ([IdEjecucion]);
GO

/* ============================================================
   TABLAS: catálogo y operación
============================================================ */

CREATE TABLE [cfl].[Temporada] (
    [IdTemporada]       BIGINT NOT NULL IDENTITY UNIQUE,
    [Codigo]            NVARCHAR(20)  NOT NULL,
    [Nombre]            NVARCHAR(100) NOT NULL,
    [FechaInicio]       DATETIME2(0) NOT NULL,
    [FechaFin]          DATETIME2(0) NOT NULL,
    [Activa]            BIT          NOT NULL,
    [Cerrada]           BIT          NOT NULL,
    [FechaCierre]       DATETIME2(0) NULL,
    [IdUsuarioCierre]   BIGINT       NULL,
    [ObservacionCierre] NVARCHAR(200) NULL,
    [FechaCreacion]     DATETIME2(0) NOT NULL,
    [FechaActualizacion] DATETIME2(0) NOT NULL,
    PRIMARY KEY ([IdTemporada])
);
GO

CREATE UNIQUE INDEX [UQ_Temporada_Codigo]
ON [cfl].[Temporada] ([Codigo]);
GO

CREATE TABLE [cfl].[CentroCosto] (
    [IdCentroCosto] BIGINT NOT NULL IDENTITY UNIQUE,
    [SapCodigo]     NVARCHAR(20)  NOT NULL,
    [Nombre]        NVARCHAR(100) NOT NULL,
    [Activo]        BIT          NOT NULL,
    PRIMARY KEY ([IdCentroCosto])
);
GO

CREATE UNIQUE INDEX [UQ_CentroCosto_SapCodigo]
ON [cfl].[CentroCosto] ([SapCodigo]);
GO

CREATE TABLE [cfl].[CuentaMayor] (
    [IdCuentaMayor] BIGINT NOT NULL IDENTITY UNIQUE,
    [Codigo]        NVARCHAR(30)  NOT NULL,
    [Glosa]         NVARCHAR(100) NOT NULL,
    PRIMARY KEY ([IdCuentaMayor])
);
GO

CREATE UNIQUE INDEX [UQ_CuentaMayor_Codigo]
ON [cfl].[CuentaMayor] ([Codigo]);
GO

CREATE TABLE [cfl].[Folio] (
    [IdFolio]               BIGINT NOT NULL IDENTITY UNIQUE,
    [IdUsuarioCierre]       BIGINT       NULL,
    [IdCentroCosto]         BIGINT       NOT NULL,
    [IdCuentaMayor]         BIGINT       NULL,
    [IdTemporada]           BIGINT       NOT NULL,
    [FolioNumero]           NVARCHAR(30)  NOT NULL,
    [PeriodoDesde]          DATETIME2(0) NULL,
    [PeriodoHasta]          DATETIME2(0) NULL,
    [Estado]                NVARCHAR(20)  NOT NULL,
    [Bloqueado]             BIT          NOT NULL,
    [FechaCierre]           DATETIME2(0) NULL,
    [ResultadoCuadratura]   NVARCHAR(20)  NULL,
    [ResumenCuadratura]     NVARCHAR(500) NULL,
    [FechaCreacion]         DATETIME2(0) NOT NULL,
    [FechaActualizacion]    DATETIME2(0) NOT NULL,
    PRIMARY KEY ([IdFolio])
);
GO

CREATE UNIQUE INDEX [UQ_Folio_TemporadaCcCuenta]
ON [cfl].[Folio] ([IdTemporada], [IdCentroCosto], [IdCuentaMayor], [FolioNumero]);
GO

CREATE TABLE [cfl].[NodoLogistico] (
    [IdNodo]    BIGINT NOT NULL IDENTITY UNIQUE,
    [Nombre]    NVARCHAR(100) NOT NULL,
    [Region]    NVARCHAR(50)  NOT NULL,
    [Comuna]    NVARCHAR(100) NOT NULL,
    [Ciudad]    NVARCHAR(100) NOT NULL,
    [Calle]     NVARCHAR(100) NOT NULL,
    [Activo]    BIT          NOT NULL,
    PRIMARY KEY ([IdNodo])
);
GO

CREATE TABLE [cfl].[Ruta] (
    [IdRuta]             BIGINT NOT NULL IDENTITY UNIQUE,
    [IdOrigenNodo]       BIGINT        NOT NULL,
    [IdDestinoNodo]      BIGINT        NOT NULL,
    [NombreRuta]         NVARCHAR(100)  NOT NULL,
    [DistanciaKm]        DECIMAL(10,2) NULL,
    [Activo]             BIT           NOT NULL,
    [FechaCreacion]      DATETIME2(0)  NOT NULL,
    [FechaActualizacion] DATETIME2(0)  NOT NULL,
    PRIMARY KEY ([IdRuta])
);
GO

CREATE UNIQUE INDEX [UQ_Ruta_OrigenDestino]
ON [cfl].[Ruta] ([IdOrigenNodo], [IdDestinoNodo]);
GO

CREATE TABLE [cfl].[TipoCamion] (
    [IdTipoCamion]          BIGINT NOT NULL IDENTITY UNIQUE,
    [Nombre]                NVARCHAR(100)  NOT NULL,
    [Categoria]             NVARCHAR(20)   NOT NULL,
    [CapacidadKg]           DECIMAL(15,3) NOT NULL,
    [RequiereTemperatura]   BIT           NOT NULL,
    [Descripcion]           NVARCHAR(100)  NULL,
    [Activo]                BIT           NOT NULL,
    PRIMARY KEY ([IdTipoCamion])
);
GO

CREATE TABLE [cfl].[Camion] (
    [IdCamion]           BIGINT NOT NULL IDENTITY UNIQUE,
    [IdTipoCamion]       BIGINT       NOT NULL,
    [SapPatente]         NVARCHAR(20)  NOT NULL,
    [SapCarro]           NVARCHAR(20)  NOT NULL,
    [Activo]             BIT          NOT NULL,
    [FechaCreacion]      DATETIME2(0) NOT NULL,
    [FechaActualizacion] DATETIME2(0) NOT NULL,
    PRIMARY KEY ([IdCamion])
);
GO

CREATE UNIQUE INDEX [UQ_Camion_PatenteCarro]
ON [cfl].[Camion] ([SapPatente], [SapCarro]);
GO

CREATE TABLE [cfl].[EmpresaTransporte] (
    [IdEmpresa]              BIGINT NOT NULL IDENTITY UNIQUE,
    [SapCodigo]              CHAR(3)      NULL,
    [Rut]                    NVARCHAR(20)  NOT NULL,
    [RazonSocial]            NVARCHAR(100) NULL,
    [NombreRepresentante]    NVARCHAR(100) NULL,
    [Correo]                 NVARCHAR(100) NULL,
    [Telefono]               NVARCHAR(20)  NULL,
    [Activo]                 BIT          NOT NULL,
    [FechaCreacion]          DATETIME2(0) NOT NULL,
    [FechaActualizacion]     DATETIME2(0) NOT NULL,
    PRIMARY KEY ([IdEmpresa])
);
GO

CREATE UNIQUE INDEX [UQ_EmpresaTransporte_Rut]
ON [cfl].[EmpresaTransporte] ([Rut]);
GO

CREATE TABLE [cfl].[Chofer] (
    [IdChofer]      BIGINT NOT NULL IDENTITY UNIQUE,
    [SapIdFiscal]   NVARCHAR(20) NOT NULL,
    [SapNombre]     NVARCHAR(80) NOT NULL,
    [Telefono]      NVARCHAR(20) NULL,
    [Activo]        BIT         NOT NULL,
    PRIMARY KEY ([IdChofer])
);
GO

CREATE UNIQUE INDEX [UQ_Chofer_SapIdFiscal]
ON [cfl].[Chofer] ([SapIdFiscal]);
GO

CREATE TABLE [cfl].[Movil] (
    [IdMovil]               BIGINT NOT NULL IDENTITY UNIQUE,
    [IdChofer]              BIGINT       NOT NULL,
    [IdEmpresaTransporte]   BIGINT       NOT NULL,
    [IdCamion]              BIGINT       NOT NULL,
    [Activo]                BIT          NOT NULL,
    [FechaCreacion]         DATETIME2(0) NOT NULL,
    [FechaActualizacion]    DATETIME2(0) NOT NULL,
    PRIMARY KEY ([IdMovil])
);
GO

CREATE UNIQUE INDEX [UQ_Movil_Combo]
ON [cfl].[Movil] ([IdEmpresaTransporte], [IdChofer], [IdCamion]);
GO

CREATE TABLE [cfl].[DetalleViaje] (
    [IdDetalleViaje]    BIGINT NOT NULL IDENTITY UNIQUE,
    [Descripcion]       NVARCHAR(200) NOT NULL,
    [Observacion]       NVARCHAR(100) NULL,
    [Activo]            BIT          NOT NULL,
    PRIMARY KEY ([IdDetalleViaje])
);
GO

CREATE TABLE [cfl].[TipoFlete] (
    [IdTipoFlete]   BIGINT NOT NULL IDENTITY UNIQUE,
    [SapCodigo]     NVARCHAR(20)  NOT NULL,
    [Nombre]        NVARCHAR(100) NOT NULL,
    [Activo]        BIT          NOT NULL,
    PRIMARY KEY ([IdTipoFlete])
);
GO

CREATE UNIQUE INDEX [UQ_TipoFlete_SapCodigo]
ON [cfl].[TipoFlete] ([SapCodigo]);
GO

CREATE TABLE [cfl].[ImputacionFlete] (
    [IdImputacionFlete]  BIGINT NOT NULL IDENTITY UNIQUE,
    [IdTipoFlete]        BIGINT       NOT NULL,
    [IdCentroCosto]      BIGINT       NOT NULL,
    [IdCuentaMayor]      BIGINT       NOT NULL,
    [Activo]             BIT          NOT NULL,
    [FechaCreacion]      DATETIME2(0) NOT NULL,
    [FechaActualizacion] DATETIME2(0) NOT NULL,
    PRIMARY KEY ([IdImputacionFlete])
);
GO

CREATE UNIQUE INDEX [UQ_ImputacionFlete_Combo]
ON [cfl].[ImputacionFlete] ([IdTipoFlete], [IdCentroCosto], [IdCuentaMayor]);
GO

CREATE INDEX [IX_ImputacionFlete_TipoActivo]
ON [cfl].[ImputacionFlete] ([IdTipoFlete], [Activo], [IdCentroCosto], [IdCuentaMayor]);
GO

CREATE TABLE [cfl].[Tarifa] (
    [IdTarifa]           BIGINT NOT NULL IDENTITY UNIQUE,
    [IdTipoCamion]       BIGINT        NOT NULL,
    [IdTemporada]        BIGINT        NOT NULL,
    [IdRuta]             BIGINT        NOT NULL,
    [VigenciaDesde]      DATE          NOT NULL,
    [VigenciaHasta]      DATE          NULL,
    [Prioridad]          INT           NOT NULL,
    [Regla]              NVARCHAR(50)   NOT NULL,
    [Moneda]             CHAR(3)       NOT NULL,
    [MontoFijo]          DECIMAL(18,2) NOT NULL,
    [Activo]             BIT           NOT NULL,
    [FechaCreacion]      DATETIME2(0)  NOT NULL,
    [FechaActualizacion] DATETIME2(0)  NOT NULL,
    PRIMARY KEY ([IdTarifa])
);
GO

CREATE UNIQUE INDEX [UQ_Tarifa_Combo]
ON [cfl].[Tarifa] ([IdTemporada], [IdTipoCamion], [IdRuta], [VigenciaDesde], [Regla], [Prioridad]);
GO

CREATE TABLE [cfl].[Especie] (
    [IdEspecie] BIGINT NOT NULL IDENTITY UNIQUE,
    [Glosa]     NVARCHAR(50) NOT NULL,
    PRIMARY KEY ([IdEspecie])
);
GO

CREATE UNIQUE INDEX [UQ_Especie_Glosa]
ON [cfl].[Especie] ([Glosa]);
GO

/* ============================================================
   TABLA: cfl.Productor
   Fuente de carga principal: dbo.Sap_BP
============================================================ */
CREATE TABLE [cfl].[Productor] (
    [IdProductor]            BIGINT NOT NULL IDENTITY UNIQUE,
    [CodigoProveedor]        NVARCHAR(20)  NOT NULL,
    [Rut]                    NVARCHAR(20)  NULL,
    [Nombre]                 NVARCHAR(150) NOT NULL,
    [Pais]                   CHAR(2)       NULL,
    [Region]                 NVARCHAR(10)  NULL,
    [Comuna]                 NVARCHAR(100) NULL,
    [Distrito]               NVARCHAR(100) NULL,
    [Calle]                  NVARCHAR(150) NULL,
    [Email]                  NVARCHAR(150) NULL,
    [OrganizacionCompra]     NVARCHAR(10)  NULL,
    [MonedaPedido]           CHAR(3)       NULL,
    [CondicionPago]          NVARCHAR(20)  NULL,
    [Incoterm]               NVARCHAR(10)  NULL,
    [Sociedad]               NVARCHAR(10)  NULL,
    [CuentaAsociada]         NVARCHAR(30)  NULL,
    [Activo]                 BIT           NOT NULL,
    [FechaActualizacionSap]  DATETIME2(3)  NULL,
    [FechaCreacion]          DATETIME2(0)  NOT NULL,
    [FechaActualizacion]     DATETIME2(0)  NOT NULL,
    PRIMARY KEY ([IdProductor])
);
GO

CREATE UNIQUE INDEX [UQ_Productor_CodigoProveedor]
ON [cfl].[Productor] ([CodigoProveedor]);
GO

CREATE INDEX [IX_Productor_Rut]
ON [cfl].[Productor] ([Rut]);
GO

/* ============================================================
   TABLA: cfl.CabeceraFlete  (ex CFL_cabecera_flete)
   Incluye IdFactura (migración 20250309)
============================================================ */
CREATE TABLE [cfl].[CabeceraFlete] (
    [IdCabeceraFlete]    BIGINT NOT NULL IDENTITY UNIQUE,
    [SapNumeroEntrega]   NVARCHAR(20)   NULL,
    [SapCodigoTipoFlete] CHAR(4)       NULL,
    [SapCentroCosto]     CHAR(10)      NULL,
    [SapCuentaMayor]     CHAR(10)      NULL,
    [SapGuiaRemision]    CHAR(25)      NULL,
    [NumeroEntrega]      NVARCHAR(20)   NULL,
    [GuiaRemision]       CHAR(25)      NULL,
    [TipoMovimiento]     NVARCHAR(4)    NOT NULL,
    [Estado]             NVARCHAR(20)   NOT NULL,
    [FechaSalida]        DATE          NOT NULL,
    [HoraSalida]         TIME          NOT NULL,
    [MontoAplicado]      DECIMAL(18,2) NOT NULL,
    [Observaciones]      NVARCHAR(200)  NULL,
    [IdCuentaMayor]      BIGINT        NULL,
    [IdImputacionFlete]  BIGINT        NULL,
    [IdCentroCosto]      BIGINT        NOT NULL,
    [IdProductor]        BIGINT        NULL,
    [IdFolio]            BIGINT        NULL,
    [SentidoFlete]       NVARCHAR(20)   NULL,
    [IdTipoFlete]        BIGINT        NOT NULL,
    [IdDetalleViaje]     BIGINT        NULL,
    [IdMovil]            BIGINT        NULL,
    [IdTarifa]           BIGINT        NULL,
    [IdUsuarioCreador]   BIGINT        NULL,
    [IdFactura]          BIGINT        NULL,
    [FechaCreacion]      DATETIME2(0)  NOT NULL,
    [FechaActualizacion] DATETIME2(0)  NOT NULL,
    PRIMARY KEY ([IdCabeceraFlete]),
    CONSTRAINT [CK_CabeceraFlete_TipoMovimiento] CHECK ([TipoMovimiento] IN ('PUSH','PULL'))
);
GO

CREATE INDEX [IX_CabeceraFlete_FolioEstado]
ON [cfl].[CabeceraFlete] ([IdFolio], [Estado]);
GO

CREATE INDEX [IX_CabeceraFlete_IdCuentaMayor]
ON [cfl].[CabeceraFlete] ([IdCuentaMayor]);
GO

CREATE INDEX [IX_CabeceraFlete_IdImputacionFlete]
ON [cfl].[CabeceraFlete] ([IdImputacionFlete]);
GO

CREATE INDEX [IX_CabeceraFlete_IdProductor]
ON [cfl].[CabeceraFlete] ([IdProductor]);
GO

CREATE INDEX [IX_CabeceraFlete_IdFactura]
ON [cfl].[CabeceraFlete] ([IdFactura])
WHERE [IdFactura] IS NOT NULL;
GO

/* ============================================================
   TABLA: cfl.DetalleFlete  (ex CFL_detalle_flete)
============================================================ */
CREATE TABLE [cfl].[DetalleFlete] (
    [IdDetalleFlete]    BIGINT NOT NULL IDENTITY UNIQUE,
    [IdCabeceraFlete]   BIGINT        NOT NULL,
    [IdEspecie]         BIGINT        NULL,
    [Material]          NVARCHAR(50)   NULL,
    [Descripcion]       NVARCHAR(100)  NULL,
    [Cantidad]          DECIMAL(12,2) NULL,
    [Unidad]            CHAR(3)       NULL,
    [Peso]              DECIMAL(15,3) NULL,
    [FechaCreacion]     DATETIME2(0)  NOT NULL,
    PRIMARY KEY ([IdDetalleFlete])
);
GO

/* ============================================================
   TABLA: cfl.FleteEstadoHistorial  (ex CFL_flete_estado_historial)
============================================================ */
CREATE TABLE [cfl].[FleteEstadoHistorial] (
    [IdFleteEstadoHistorial] BIGINT NOT NULL IDENTITY UNIQUE,
    [IdCabeceraFlete]        BIGINT       NOT NULL,
    [Estado]                 NVARCHAR(20)  NOT NULL,
    [FechaHora]              DATETIME2(0) NOT NULL,
    [IdUsuario]              BIGINT       NOT NULL,
    [Motivo]                 NVARCHAR(200) NULL,
    [EvidenciaRef]           NVARCHAR(100) NULL,
    PRIMARY KEY ([IdFleteEstadoHistorial])
);
GO

/* ============================================================
   TABLA: cfl.CabeceraFactura  (ex CFL_cabecera_factura)
   Incluye CriterioAgrupacion, Observaciones (módulo facturación)
   IdFolio es nullable (bridge FacturaFolio cubre n:m)
============================================================ */
CREATE TABLE [cfl].[CabeceraFactura] (
    [IdFactura]           BIGINT NOT NULL IDENTITY UNIQUE,
    [IdFolio]             BIGINT        NULL,
    [IdEmpresa]           BIGINT        NOT NULL,
    [NumeroFactura]       NVARCHAR(40)   NOT NULL,
    [FechaEmision]        DATETIME2(0)  NOT NULL,
    [Moneda]              CHAR(3)       NOT NULL,
    [MontoNeto]           DECIMAL(18,2) NOT NULL,
    [MontoIva]            DECIMAL(18,2) NOT NULL,
    [MontoTotal]          DECIMAL(18,2) NOT NULL,
    [Estado]              NVARCHAR(20)   NOT NULL,
    [CriterioAgrupacion]  NVARCHAR(20)   NULL,
    [Observaciones]       NVARCHAR(200)  NULL,
    [RutaXml]             NVARCHAR(255)  NULL,
    [RutaPdf]             NVARCHAR(255)  NULL,
    [FechaCreacion]       DATETIME2(0)  NOT NULL,
    [FechaActualizacion]  DATETIME2(0)  NOT NULL,
    PRIMARY KEY ([IdFactura])
);
GO

CREATE UNIQUE INDEX [UQ_CabeceraFactura_EmpresaNumero]
ON [cfl].[CabeceraFactura] ([IdEmpresa], [NumeroFactura]);
GO

/* ============================================================
   TABLA: cfl.FacturaFolio  (nueva — bridge factura ↔ folio)
============================================================ */
CREATE TABLE [cfl].[FacturaFolio] (
    [IdFacturaFolio]  BIGINT NOT NULL IDENTITY UNIQUE,
    [IdFactura]       BIGINT       NOT NULL,
    [IdFolio]         BIGINT       NOT NULL,
    [FechaCreacion]   DATETIME2(0) NOT NULL,
    PRIMARY KEY ([IdFacturaFolio])
);
GO

CREATE UNIQUE INDEX [UQ_FacturaFolio_FacturaFolio]
ON [cfl].[FacturaFolio] ([IdFactura], [IdFolio]);
GO

/* ============================================================
   TABLA: cfl.DetalleFactura  (ex CFL_detalle_factura)
============================================================ */
CREATE TABLE [cfl].[DetalleFactura] (
    [IdFacturaDetalle]  BIGINT NOT NULL IDENTITY UNIQUE,
    [IdFactura]         BIGINT        NOT NULL,
    [MontoLinea]        DECIMAL(18,2) NULL,
    [Detalle]           NVARCHAR(200)  NULL,
    PRIMARY KEY ([IdFacturaDetalle])
);
GO

/* ============================================================
   TABLA: cfl.ConciliacionFacturaFlete  (ex CFL_conciliacion_factura_flete)
============================================================ */
CREATE TABLE [cfl].[ConciliacionFacturaFlete] (
    [IdConciliacion]        BIGINT NOT NULL IDENTITY UNIQUE,
    [IdFactura]             BIGINT        NOT NULL,
    [IdCabeceraFlete]       BIGINT        NOT NULL,
    [MontoAsignado]         DECIMAL(18,2) NOT NULL,
    [Diferencia]            DECIMAL(18,2) NOT NULL,
    [ToleranciaAplicada]    DECIMAL(18,2) NOT NULL,
    [Estado]                NVARCHAR(20)   NOT NULL,
    [Observacion]           NVARCHAR(300)  NULL,
    [FechaCreacion]         DATETIME2(0)  NOT NULL,
    [FechaActualizacion]    DATETIME2(0)  NOT NULL,
    PRIMARY KEY ([IdConciliacion])
);
GO

CREATE UNIQUE INDEX [UQ_ConciliacionFacturaFlete_FacturaFlete]
ON [cfl].[ConciliacionFacturaFlete] ([IdFactura], [IdCabeceraFlete]);
GO

/* ============================================================
   TABLA: cfl.FleteSapEntrega  (ex CFL_flete_sap_entrega)
============================================================ */
CREATE TABLE [cfl].[FleteSapEntrega] (
    [IdFleteSapEntrega] BIGINT NOT NULL IDENTITY UNIQUE,
    [IdCabeceraFlete]   BIGINT       NOT NULL,
    [IdSapEntrega]      BIGINT       NOT NULL,
    [OrigenDatos]       NVARCHAR(10)  NOT NULL,
    [TipoRelacion]      NVARCHAR(20)  NOT NULL,
    [FechaCreacion]     DATETIME2(0) NOT NULL,
    [CreadoPor]         BIGINT       NULL,
    PRIMARY KEY ([IdFleteSapEntrega])
);
GO

CREATE UNIQUE INDEX [UQ_FleteSapEntrega_Bridge]
ON [cfl].[FleteSapEntrega] ([IdCabeceraFlete], [IdSapEntrega]);
GO

/* ============================================================
   TABLAS: seguridad
============================================================ */
CREATE TABLE [cfl].[Usuario] (
    [IdUsuario]          BIGINT IDENTITY UNIQUE,
    [Username]           NVARCHAR(60)  NOT NULL,
    [Email]              NVARCHAR(200) NOT NULL,
    [PasswordHash]       NVARCHAR(255) NOT NULL,
    [Nombre]             NVARCHAR(100) NULL,
    [Apellido]           NVARCHAR(100) NULL,
    [Activo]             BIT          NOT NULL,
    [UltimoLogin]        DATETIME2(0) NULL,
    [FechaCreacion]      DATETIME2(0) NOT NULL,
    [FechaActualizacion] DATETIME2(0) NOT NULL,
    PRIMARY KEY ([IdUsuario])
);
GO

CREATE UNIQUE INDEX [UQ_Usuario_Username]
ON [cfl].[Usuario] ([Username]);
GO

CREATE UNIQUE INDEX [UQ_Usuario_Email]
ON [cfl].[Usuario] ([Email]);
GO

CREATE TABLE [cfl].[Rol] (
    [IdRol]       BIGINT NOT NULL IDENTITY UNIQUE,
    [Nombre]      NVARCHAR(50)  NOT NULL,
    [Descripcion] NVARCHAR(100) NULL,
    [Activo]      BIT          NOT NULL,
    PRIMARY KEY ([IdRol])
);
GO

CREATE UNIQUE INDEX [UQ_Rol_Nombre]
ON [cfl].[Rol] ([Nombre]);
GO

CREATE TABLE [cfl].[Permiso] (
    [IdPermiso]   BIGINT NOT NULL IDENTITY UNIQUE,
    [Recurso]     NVARCHAR(100) NOT NULL,
    [Accion]      NVARCHAR(20)  NOT NULL,
    [Clave]       NVARCHAR(50)  NOT NULL,
    [Descripcion] NVARCHAR(100) NULL,
    [Activo]      BIT          NOT NULL,
    PRIMARY KEY ([IdPermiso])
);
GO

CREATE UNIQUE INDEX [UQ_Permiso_Clave]
ON [cfl].[Permiso] ([Clave]);
GO

CREATE TABLE [cfl].[UsuarioRol] (
    [IdUsuarioRol]  BIGINT NOT NULL IDENTITY UNIQUE,
    [IdUsuario]     BIGINT NOT NULL,
    [IdRol]         BIGINT NOT NULL,
    PRIMARY KEY ([IdUsuarioRol])
);
GO

CREATE UNIQUE INDEX [UQ_UsuarioRol_UsuarioRol]
ON [cfl].[UsuarioRol] ([IdUsuario], [IdRol]);
GO

CREATE TABLE [cfl].[RolPermiso] (
    [IdRolPermiso]  BIGINT NOT NULL IDENTITY UNIQUE,
    [IdRol]         BIGINT NOT NULL,
    [IdPermiso]     BIGINT NOT NULL,
    PRIMARY KEY ([IdRolPermiso])
);
GO

CREATE UNIQUE INDEX [UQ_RolPermiso_RolPermiso]
ON [cfl].[RolPermiso] ([IdRol], [IdPermiso]);
GO

CREATE TABLE [cfl].[Auditoria] (
    [IdAuditoria]   BIGINT NOT NULL IDENTITY UNIQUE,
    [IdUsuario]     BIGINT       NOT NULL,
    [FechaHora]     DATETIME2(0) NOT NULL,
    [Accion]        NVARCHAR(50)  NOT NULL,
    [Entidad]       NVARCHAR(100) NOT NULL,
    [IdEntidad]     NVARCHAR(50)  NULL,
    [Resumen]       NVARCHAR(300) NULL,
    [IpEquipo]      NVARCHAR(50)  NULL,
    PRIMARY KEY ([IdAuditoria])
);
GO

/* ============================================================
   FOREIGN KEYS
============================================================ */

-- EtlEjecucion no tiene FKs entrantes relevantes en UP

-- SapLikpRaw → EtlEjecucion
ALTER TABLE [cfl].[SapLikpRaw]
ADD CONSTRAINT [FK_SapLikpRaw_EtlEjecucion]
FOREIGN KEY ([IdEjecucion]) REFERENCES [cfl].[EtlEjecucion] ([IdEjecucion])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- SapLipsRaw → EtlEjecucion
ALTER TABLE [cfl].[SapLipsRaw]
ADD CONSTRAINT [FK_SapLipsRaw_EtlEjecucion]
FOREIGN KEY ([IdEjecucion]) REFERENCES [cfl].[EtlEjecucion] ([IdEjecucion])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- SapEntregaHistorial → SapEntrega
ALTER TABLE [cfl].[SapEntregaHistorial]
ADD CONSTRAINT [FK_SapEntregaHistorial_SapEntrega]
FOREIGN KEY ([IdSapEntrega]) REFERENCES [cfl].[SapEntrega] ([IdSapEntrega])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- SapEntregaHistorial → SapLikpRaw
ALTER TABLE [cfl].[SapEntregaHistorial]
ADD CONSTRAINT [FK_SapEntregaHistorial_SapLikpRaw]
FOREIGN KEY ([IdLikpRaw]) REFERENCES [cfl].[SapLikpRaw] ([IdSapLikpRaw])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- SapEntregaPosicion → SapEntrega
ALTER TABLE [cfl].[SapEntregaPosicion]
ADD CONSTRAINT [FK_SapEntregaPosicion_SapEntrega]
FOREIGN KEY ([IdSapEntrega]) REFERENCES [cfl].[SapEntrega] ([IdSapEntrega])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- SapEntregaPosicionHistorial → SapEntregaPosicion
ALTER TABLE [cfl].[SapEntregaPosicionHistorial]
ADD CONSTRAINT [FK_SapEntregaPosicionHistorial_SapEntregaPosicion]
FOREIGN KEY ([IdSapEntregaPosicion]) REFERENCES [cfl].[SapEntregaPosicion] ([IdSapEntregaPosicion])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- SapEntregaPosicionHistorial → SapLipsRaw
ALTER TABLE [cfl].[SapEntregaPosicionHistorial]
ADD CONSTRAINT [FK_SapEntregaPosicionHistorial_SapLipsRaw]
FOREIGN KEY ([IdLipsRaw]) REFERENCES [cfl].[SapLipsRaw] ([IdSapLipsRaw])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- SapEntregaDescarte → SapEntrega
ALTER TABLE [cfl].[SapEntregaDescarte]
ADD CONSTRAINT [FK_SapEntregaDescarte_SapEntrega]
FOREIGN KEY ([IdSapEntrega]) REFERENCES [cfl].[SapEntrega] ([IdSapEntrega])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- SapEntregaDescarte → Usuario (creador)
ALTER TABLE [cfl].[SapEntregaDescarte]
ADD CONSTRAINT [FK_SapEntregaDescarte_UsuarioCreadoPor]
FOREIGN KEY ([CreadoPor]) REFERENCES [cfl].[Usuario] ([IdUsuario])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- SapEntregaDescarte → Usuario (restaurador)
ALTER TABLE [cfl].[SapEntregaDescarte]
ADD CONSTRAINT [FK_SapEntregaDescarte_UsuarioRestauradoPor]
FOREIGN KEY ([RestauradoPor]) REFERENCES [cfl].[Usuario] ([IdUsuario])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- Temporada → Usuario (cierre)
ALTER TABLE [cfl].[Temporada]
ADD CONSTRAINT [FK_Temporada_UsuarioCierre]
FOREIGN KEY ([IdUsuarioCierre]) REFERENCES [cfl].[Usuario] ([IdUsuario])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- Folio → CentroCosto
ALTER TABLE [cfl].[Folio]
ADD CONSTRAINT [FK_Folio_CentroCosto]
FOREIGN KEY ([IdCentroCosto]) REFERENCES [cfl].[CentroCosto] ([IdCentroCosto])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- Folio → CuentaMayor
ALTER TABLE [cfl].[Folio]
ADD CONSTRAINT [FK_Folio_CuentaMayor]
FOREIGN KEY ([IdCuentaMayor]) REFERENCES [cfl].[CuentaMayor] ([IdCuentaMayor])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- Folio → Temporada
ALTER TABLE [cfl].[Folio]
ADD CONSTRAINT [FK_Folio_Temporada]
FOREIGN KEY ([IdTemporada]) REFERENCES [cfl].[Temporada] ([IdTemporada])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- Folio → Usuario (cierre)
ALTER TABLE [cfl].[Folio]
ADD CONSTRAINT [FK_Folio_UsuarioCierre]
FOREIGN KEY ([IdUsuarioCierre]) REFERENCES [cfl].[Usuario] ([IdUsuario])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- Ruta → NodoLogistico (origen)
ALTER TABLE [cfl].[Ruta]
ADD CONSTRAINT [FK_Ruta_NodoLogisticoOrigen]
FOREIGN KEY ([IdOrigenNodo]) REFERENCES [cfl].[NodoLogistico] ([IdNodo])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- Ruta → NodoLogistico (destino)
ALTER TABLE [cfl].[Ruta]
ADD CONSTRAINT [FK_Ruta_NodoLogisticoDestino]
FOREIGN KEY ([IdDestinoNodo]) REFERENCES [cfl].[NodoLogistico] ([IdNodo])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- Camion → TipoCamion
ALTER TABLE [cfl].[Camion]
ADD CONSTRAINT [FK_Camion_TipoCamion]
FOREIGN KEY ([IdTipoCamion]) REFERENCES [cfl].[TipoCamion] ([IdTipoCamion])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- Movil → Camion
ALTER TABLE [cfl].[Movil]
ADD CONSTRAINT [FK_Movil_Camion]
FOREIGN KEY ([IdCamion]) REFERENCES [cfl].[Camion] ([IdCamion])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- Movil → Chofer
ALTER TABLE [cfl].[Movil]
ADD CONSTRAINT [FK_Movil_Chofer]
FOREIGN KEY ([IdChofer]) REFERENCES [cfl].[Chofer] ([IdChofer])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- Movil → EmpresaTransporte
ALTER TABLE [cfl].[Movil]
ADD CONSTRAINT [FK_Movil_EmpresaTransporte]
FOREIGN KEY ([IdEmpresaTransporte]) REFERENCES [cfl].[EmpresaTransporte] ([IdEmpresa])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- ImputacionFlete → TipoFlete
ALTER TABLE [cfl].[ImputacionFlete]
ADD CONSTRAINT [FK_ImputacionFlete_TipoFlete]
FOREIGN KEY ([IdTipoFlete]) REFERENCES [cfl].[TipoFlete] ([IdTipoFlete])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- ImputacionFlete → CentroCosto
ALTER TABLE [cfl].[ImputacionFlete]
ADD CONSTRAINT [FK_ImputacionFlete_CentroCosto]
FOREIGN KEY ([IdCentroCosto]) REFERENCES [cfl].[CentroCosto] ([IdCentroCosto])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- ImputacionFlete → CuentaMayor
ALTER TABLE [cfl].[ImputacionFlete]
ADD CONSTRAINT [FK_ImputacionFlete_CuentaMayor]
FOREIGN KEY ([IdCuentaMayor]) REFERENCES [cfl].[CuentaMayor] ([IdCuentaMayor])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- Tarifa → Temporada
ALTER TABLE [cfl].[Tarifa]
ADD CONSTRAINT [FK_Tarifa_Temporada]
FOREIGN KEY ([IdTemporada]) REFERENCES [cfl].[Temporada] ([IdTemporada])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- Tarifa → Ruta
ALTER TABLE [cfl].[Tarifa]
ADD CONSTRAINT [FK_Tarifa_Ruta]
FOREIGN KEY ([IdRuta]) REFERENCES [cfl].[Ruta] ([IdRuta])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- Tarifa → TipoCamion
ALTER TABLE [cfl].[Tarifa]
ADD CONSTRAINT [FK_Tarifa_TipoCamion]
FOREIGN KEY ([IdTipoCamion]) REFERENCES [cfl].[TipoCamion] ([IdTipoCamion])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- CabeceraFlete → Folio
ALTER TABLE [cfl].[CabeceraFlete]
ADD CONSTRAINT [FK_CabeceraFlete_Folio]
FOREIGN KEY ([IdFolio]) REFERENCES [cfl].[Folio] ([IdFolio])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- CabeceraFlete → TipoFlete
ALTER TABLE [cfl].[CabeceraFlete]
ADD CONSTRAINT [FK_CabeceraFlete_TipoFlete]
FOREIGN KEY ([IdTipoFlete]) REFERENCES [cfl].[TipoFlete] ([IdTipoFlete])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- CabeceraFlete → DetalleViaje
ALTER TABLE [cfl].[CabeceraFlete]
ADD CONSTRAINT [FK_CabeceraFlete_DetalleViaje]
FOREIGN KEY ([IdDetalleViaje]) REFERENCES [cfl].[DetalleViaje] ([IdDetalleViaje])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- CabeceraFlete → Movil
ALTER TABLE [cfl].[CabeceraFlete]
ADD CONSTRAINT [FK_CabeceraFlete_Movil]
FOREIGN KEY ([IdMovil]) REFERENCES [cfl].[Movil] ([IdMovil])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- CabeceraFlete → Tarifa
ALTER TABLE [cfl].[CabeceraFlete]
ADD CONSTRAINT [FK_CabeceraFlete_Tarifa]
FOREIGN KEY ([IdTarifa]) REFERENCES [cfl].[Tarifa] ([IdTarifa])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- CabeceraFlete → Usuario (creador)
ALTER TABLE [cfl].[CabeceraFlete]
ADD CONSTRAINT [FK_CabeceraFlete_UsuarioCreador]
FOREIGN KEY ([IdUsuarioCreador]) REFERENCES [cfl].[Usuario] ([IdUsuario])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- CabeceraFlete → CentroCosto
ALTER TABLE [cfl].[CabeceraFlete]
ADD CONSTRAINT [FK_CabeceraFlete_CentroCosto]
FOREIGN KEY ([IdCentroCosto]) REFERENCES [cfl].[CentroCosto] ([IdCentroCosto])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- CabeceraFlete → Productor
ALTER TABLE [cfl].[CabeceraFlete]
ADD CONSTRAINT [FK_CabeceraFlete_Productor]
FOREIGN KEY ([IdProductor]) REFERENCES [cfl].[Productor] ([IdProductor])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- CabeceraFlete → CuentaMayor
ALTER TABLE [cfl].[CabeceraFlete]
ADD CONSTRAINT [FK_CabeceraFlete_CuentaMayor]
FOREIGN KEY ([IdCuentaMayor]) REFERENCES [cfl].[CuentaMayor] ([IdCuentaMayor])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- CabeceraFlete → ImputacionFlete
ALTER TABLE [cfl].[CabeceraFlete]
ADD CONSTRAINT [FK_CabeceraFlete_ImputacionFlete]
FOREIGN KEY ([IdImputacionFlete]) REFERENCES [cfl].[ImputacionFlete] ([IdImputacionFlete])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- CabeceraFlete → CabeceraFactura
ALTER TABLE [cfl].[CabeceraFlete]
ADD CONSTRAINT [FK_CabeceraFlete_CabeceraFactura]
FOREIGN KEY ([IdFactura]) REFERENCES [cfl].[CabeceraFactura] ([IdFactura])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- DetalleFlete → CabeceraFlete
ALTER TABLE [cfl].[DetalleFlete]
ADD CONSTRAINT [FK_DetalleFlete_CabeceraFlete]
FOREIGN KEY ([IdCabeceraFlete]) REFERENCES [cfl].[CabeceraFlete] ([IdCabeceraFlete])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- DetalleFlete → Especie
ALTER TABLE [cfl].[DetalleFlete]
ADD CONSTRAINT [FK_DetalleFlete_Especie]
FOREIGN KEY ([IdEspecie]) REFERENCES [cfl].[Especie] ([IdEspecie])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- FleteEstadoHistorial → CabeceraFlete
ALTER TABLE [cfl].[FleteEstadoHistorial]
ADD CONSTRAINT [FK_FleteEstadoHistorial_CabeceraFlete]
FOREIGN KEY ([IdCabeceraFlete]) REFERENCES [cfl].[CabeceraFlete] ([IdCabeceraFlete])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- FleteEstadoHistorial → Usuario
ALTER TABLE [cfl].[FleteEstadoHistorial]
ADD CONSTRAINT [FK_FleteEstadoHistorial_Usuario]
FOREIGN KEY ([IdUsuario]) REFERENCES [cfl].[Usuario] ([IdUsuario])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- CabeceraFactura → Folio (nullable: bridge FacturaFolio cubre n:m)
ALTER TABLE [cfl].[CabeceraFactura]
ADD CONSTRAINT [FK_CabeceraFactura_Folio]
FOREIGN KEY ([IdFolio]) REFERENCES [cfl].[Folio] ([IdFolio])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- CabeceraFactura → EmpresaTransporte
ALTER TABLE [cfl].[CabeceraFactura]
ADD CONSTRAINT [FK_CabeceraFactura_EmpresaTransporte]
FOREIGN KEY ([IdEmpresa]) REFERENCES [cfl].[EmpresaTransporte] ([IdEmpresa])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- FacturaFolio → CabeceraFactura
ALTER TABLE [cfl].[FacturaFolio]
ADD CONSTRAINT [FK_FacturaFolio_CabeceraFactura]
FOREIGN KEY ([IdFactura]) REFERENCES [cfl].[CabeceraFactura] ([IdFactura])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- FacturaFolio → Folio
ALTER TABLE [cfl].[FacturaFolio]
ADD CONSTRAINT [FK_FacturaFolio_Folio]
FOREIGN KEY ([IdFolio]) REFERENCES [cfl].[Folio] ([IdFolio])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- DetalleFactura → CabeceraFactura
ALTER TABLE [cfl].[DetalleFactura]
ADD CONSTRAINT [FK_DetalleFactura_CabeceraFactura]
FOREIGN KEY ([IdFactura]) REFERENCES [cfl].[CabeceraFactura] ([IdFactura])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- ConciliacionFacturaFlete → CabeceraFactura
ALTER TABLE [cfl].[ConciliacionFacturaFlete]
ADD CONSTRAINT [FK_ConciliacionFacturaFlete_CabeceraFactura]
FOREIGN KEY ([IdFactura]) REFERENCES [cfl].[CabeceraFactura] ([IdFactura])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- ConciliacionFacturaFlete → CabeceraFlete
ALTER TABLE [cfl].[ConciliacionFacturaFlete]
ADD CONSTRAINT [FK_ConciliacionFacturaFlete_CabeceraFlete]
FOREIGN KEY ([IdCabeceraFlete]) REFERENCES [cfl].[CabeceraFlete] ([IdCabeceraFlete])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- FleteSapEntrega → CabeceraFlete
ALTER TABLE [cfl].[FleteSapEntrega]
ADD CONSTRAINT [FK_FleteSapEntrega_CabeceraFlete]
FOREIGN KEY ([IdCabeceraFlete]) REFERENCES [cfl].[CabeceraFlete] ([IdCabeceraFlete])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- FleteSapEntrega → SapEntrega
ALTER TABLE [cfl].[FleteSapEntrega]
ADD CONSTRAINT [FK_FleteSapEntrega_SapEntrega]
FOREIGN KEY ([IdSapEntrega]) REFERENCES [cfl].[SapEntrega] ([IdSapEntrega])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- FleteSapEntrega → Usuario (creador)
ALTER TABLE [cfl].[FleteSapEntrega]
ADD CONSTRAINT [FK_FleteSapEntrega_UsuarioCreadoPor]
FOREIGN KEY ([CreadoPor]) REFERENCES [cfl].[Usuario] ([IdUsuario])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- UsuarioRol → Usuario
ALTER TABLE [cfl].[UsuarioRol]
ADD CONSTRAINT [FK_UsuarioRol_Usuario]
FOREIGN KEY ([IdUsuario]) REFERENCES [cfl].[Usuario] ([IdUsuario])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- UsuarioRol → Rol
ALTER TABLE [cfl].[UsuarioRol]
ADD CONSTRAINT [FK_UsuarioRol_Rol]
FOREIGN KEY ([IdRol]) REFERENCES [cfl].[Rol] ([IdRol])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- RolPermiso → Rol
ALTER TABLE [cfl].[RolPermiso]
ADD CONSTRAINT [FK_RolPermiso_Rol]
FOREIGN KEY ([IdRol]) REFERENCES [cfl].[Rol] ([IdRol])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- RolPermiso → Permiso
ALTER TABLE [cfl].[RolPermiso]
ADD CONSTRAINT [FK_RolPermiso_Permiso]
FOREIGN KEY ([IdPermiso]) REFERENCES [cfl].[Permiso] ([IdPermiso])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

-- Auditoria → Usuario
ALTER TABLE [cfl].[Auditoria]
ADD CONSTRAINT [FK_Auditoria_Usuario]
FOREIGN KEY ([IdUsuario]) REFERENCES [cfl].[Usuario] ([IdUsuario])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

/* ============================================================
   VISTA: cfl.VW_LikpActual  (ex vw_cfl_sap_likp_current)
   Última versión activa por BK (SistemaFuente, SapNumeroEntrega)
============================================================ */
CREATE OR ALTER VIEW [cfl].[VW_LikpActual]
AS
WITH ranked AS
(
    SELECT
        r.*,
        rn = ROW_NUMBER() OVER
        (
            PARTITION BY r.[SistemaFuente], r.[SapNumeroEntrega]
            ORDER BY r.[FechaExtraccion] DESC, r.[IdSapLikpRaw] DESC
        )
    FROM [cfl].[SapLikpRaw] r
    WHERE r.[EstadoFila] = 'ACTIVE'
)
SELECT
    SapNumeroEntrega,
    IdSapLikpRaw,
    FechaExtraccion,
    HashFila,
    EstadoFila,
    IdEjecucion,
    SistemaFuente,
    FechaCreacion,

    SapReferencia,
    SapPuestoExpedicion,
    SapDestinatario,
    SapOrganizacionVentas,
    SapCreadoPor,
    SapFechaCreacion,
    SapClaseEntrega,
    SapTipoEntrega,

    SapFechaCarga,
    SapHoraCarga,
    SapGuiaRemision,
    SapNombreChofer,
    SapIdFiscalChofer,
    SapEmpresaTransporte,
    SapPatente,
    SapCarro,
    SapFechaSalida,
    SapHoraSalida,
    SapCodigoTipoFlete,

    SapCentroCosto,
    SapCuentaMayor,

    SapPesoTotal,
    SapPesoNeto,
    SapFechaEntregaReal
FROM ranked
WHERE rn = 1;
GO

/* ============================================================
   VISTA: cfl.VW_LipsActual  (ex vw_cfl_sap_lips_current)
   Última versión activa por BK + resolución de posiciones hijo/padre
============================================================ */
CREATE OR ALTER VIEW [cfl].[VW_LipsActual]
AS
WITH ranked AS
(
    SELECT
        r.*,
        rn = ROW_NUMBER() OVER
        (
            PARTITION BY r.[SistemaFuente], r.[SapNumeroEntrega], r.[SapPosicion]
            ORDER BY
                CASE WHEN NULLIF(LTRIM(RTRIM(r.[SapPosicionSuperior])), '') IS NOT NULL THEN 0 ELSE 1 END,
                r.[FechaExtraccion] DESC,
                r.[IdSapLipsRaw] DESC
        )
    FROM [cfl].[SapLipsRaw] r
    WHERE r.[EstadoFila] = 'ACTIVE'
),
src AS
(
    SELECT
        SapNumeroEntrega,
        SapPosicion = RIGHT(CONCAT('000000', LTRIM(RTRIM(SapPosicion))), 6),
        SapPosicionSuperior =
            CASE
                WHEN NULLIF(LTRIM(RTRIM(SapPosicionSuperior)), '') IS NULL THEN NULL
                ELSE RIGHT(CONCAT('000000', LTRIM(RTRIM(SapPosicionSuperior))), 6)
            END,
        SapLote,
        IdSapLipsRaw,
        FechaExtraccion,
        HashFila,
        EstadoFila,
        IdEjecucion,
        SistemaFuente,
        FechaCreacion,
        SapMaterial,
        SapCantidadEntregada,
        SapUnidadPeso,
        SapDenominacionMaterial,
        SapCentro,
        SapAlmacen
    FROM ranked
    WHERE rn = 1
),
base AS
(
    SELECT * FROM src WHERE SapPosicionSuperior IS NULL
),
hijos AS
(
    SELECT * FROM src WHERE SapPosicionSuperior IS NOT NULL
),
base_flag AS
(
    SELECT
        b.*,
        has_children =
            CASE WHEN EXISTS (
                SELECT 1
                FROM hijos h
                WHERE h.SistemaFuente = b.SistemaFuente
                  AND h.SapNumeroEntrega = b.SapNumeroEntrega
                  AND h.SapPosicionSuperior = b.SapPosicion
            ) THEN 1 ELSE 0 END
    FROM base b
),
out_hijos AS
(
    SELECT
        SapNumeroEntrega      = h.SapNumeroEntrega,
        SapPosicion           = h.SapPosicion,
        SapPosicionSuperior   = h.SapPosicionSuperior,
        SapLote               = h.SapLote,
        IdSapLipsRaw          = h.IdSapLipsRaw,
        FechaExtraccion       = h.FechaExtraccion,
        HashFila              = h.HashFila,
        EstadoFila            = h.EstadoFila,
        IdEjecucion           = h.IdEjecucion,
        SistemaFuente         = h.SistemaFuente,
        FechaCreacion         = h.FechaCreacion,
        SapMaterial           = COALESCE(NULLIF(LTRIM(RTRIM(h.SapMaterial)), ''), b.SapMaterial),
        SapCantidadEntregada  = h.SapCantidadEntregada,
        SapUnidadPeso         = h.SapUnidadPeso,
        SapDenominacionMaterial = h.SapDenominacionMaterial,
        SapCentro             = h.SapCentro,
        SapAlmacen            = h.SapAlmacen,
        SapPosicionRaiz       = h.SapPosicionSuperior,
        SapPosicionEfectiva   = h.SapPosicion,
        IdSapLipsRawBase      = b.IdSapLipsRaw,
        FechaExtraccionBase   = b.FechaExtraccion,
        IdEjecucionBase       = b.IdEjecucion
    FROM hijos h
    LEFT JOIN base b
      ON b.SistemaFuente = h.SistemaFuente
     AND b.SapNumeroEntrega = h.SapNumeroEntrega
     AND b.SapPosicion = h.SapPosicionSuperior
),
out_base_sin_hijos AS
(
    SELECT
        SapNumeroEntrega      = b.SapNumeroEntrega,
        SapPosicion           = b.SapPosicion,
        SapPosicionSuperior   = CAST(NULL AS CHAR(6)),
        SapLote               = b.SapLote,
        IdSapLipsRaw          = b.IdSapLipsRaw,
        FechaExtraccion       = b.FechaExtraccion,
        HashFila              = b.HashFila,
        EstadoFila            = b.EstadoFila,
        IdEjecucion           = b.IdEjecucion,
        SistemaFuente         = b.SistemaFuente,
        FechaCreacion         = b.FechaCreacion,
        SapMaterial           = b.SapMaterial,
        SapCantidadEntregada  = b.SapCantidadEntregada,
        SapUnidadPeso         = b.SapUnidadPeso,
        SapDenominacionMaterial = b.SapDenominacionMaterial,
        SapCentro             = b.SapCentro,
        SapAlmacen            = b.SapAlmacen,
        SapPosicionRaiz       = b.SapPosicion,
        SapPosicionEfectiva   = b.SapPosicion,
        IdSapLipsRawBase      = b.IdSapLipsRaw,
        FechaExtraccionBase   = b.FechaExtraccion,
        IdEjecucionBase       = b.IdEjecucion
    FROM base_flag b
    WHERE b.has_children = 0
      AND b.SapCantidadEntregada > 0
)
SELECT
    SapNumeroEntrega,
    SapPosicion,
    SapPosicionSuperior,
    SapLote,
    IdSapLipsRaw,
    FechaExtraccion,
    HashFila,
    EstadoFila,
    IdEjecucion,
    SistemaFuente,
    FechaCreacion,
    SapMaterial,
    SapCantidadEntregada,
    SapUnidadPeso,
    SapDenominacionMaterial,
    SapCentro,
    SapAlmacen,
    SapPosicionRaiz,
    SapPosicionEfectiva,
    IdSapLipsRawBase,
    FechaExtraccionBase,
    IdEjecucionBase
FROM out_hijos
UNION ALL
SELECT
    SapNumeroEntrega,
    SapPosicion,
    SapPosicionSuperior,
    SapLote,
    IdSapLipsRaw,
    FechaExtraccion,
    HashFila,
    EstadoFila,
    IdEjecucion,
    SistemaFuente,
    FechaCreacion,
    SapMaterial,
    SapCantidadEntregada,
    SapUnidadPeso,
    SapDenominacionMaterial,
    SapCentro,
    SapAlmacen,
    SapPosicionRaiz,
    SapPosicionEfectiva,
    IdSapLipsRawBase,
    FechaExtraccionBase,
    IdEjecucionBase
FROM out_base_sin_hijos;
GO

/* ============================================================
   FUNCIÓN: cfl.Fn_LikpAPartirDe  (ex fn_cfl_sap_likp_as_of)
   Reconstruye "vigente a fecha" por FechaExtraccion <= @como_de_utc
============================================================ */
CREATE OR ALTER FUNCTION [cfl].[Fn_LikpAPartirDe]
(
    @como_de_utc DATETIME2(0)
)
RETURNS TABLE
AS
RETURN
WITH ranked AS
(
    SELECT
        r.*,
        rn = ROW_NUMBER() OVER
        (
            PARTITION BY r.[SistemaFuente], r.[SapNumeroEntrega]
            ORDER BY r.[FechaExtraccion] DESC, r.[IdSapLikpRaw] DESC
        )
    FROM [cfl].[SapLikpRaw] r
    WHERE r.[FechaExtraccion] <= @como_de_utc
)
SELECT
    SapNumeroEntrega,
    IdSapLikpRaw,
    FechaExtraccion,
    HashFila,
    EstadoFila,
    IdEjecucion,
    SistemaFuente,
    FechaCreacion,

    SapReferencia,
    SapPuestoExpedicion,
    SapDestinatario,
    SapOrganizacionVentas,
    SapCreadoPor,
    SapFechaCreacion,
    SapClaseEntrega,
    SapTipoEntrega,

    SapFechaCarga,
    SapHoraCarga,
    SapGuiaRemision,
    SapNombreChofer,
    SapIdFiscalChofer,
    SapEmpresaTransporte,
    SapPatente,
    SapCarro,
    SapFechaSalida,
    SapHoraSalida,
    SapCodigoTipoFlete,

    SapCentroCosto,
    SapCuentaMayor,

    SapPesoTotal,
    SapPesoNeto,
    SapFechaEntregaReal
FROM ranked
WHERE rn = 1;
GO

/* ============================================================
   FUNCIÓN: cfl.Fn_LipsAPartirDe  (ex fn_cfl_sap_lips_as_of)
   Reconstruye "vigente a fecha" por FechaExtraccion <= @como_de_utc
============================================================ */
CREATE OR ALTER FUNCTION [cfl].[Fn_LipsAPartirDe]
(
    @como_de_utc DATETIME2(0)
)
RETURNS TABLE
AS
RETURN
WITH ranked AS
(
    SELECT
        r.*,
        rn = ROW_NUMBER() OVER
        (
            PARTITION BY r.[SistemaFuente], r.[SapNumeroEntrega], r.[SapPosicion]
            ORDER BY r.[FechaExtraccion] DESC, r.[IdSapLipsRaw] DESC
        )
    FROM [cfl].[SapLipsRaw] r
    WHERE r.[FechaExtraccion] <= @como_de_utc
)
SELECT
    SapNumeroEntrega,
    SapPosicion,
    SapPosicionSuperior,
    SapLote,
    IdSapLipsRaw,
    FechaExtraccion,
    HashFila,
    EstadoFila,
    IdEjecucion,
    SistemaFuente,
    FechaCreacion,
    SapMaterial,
    SapCantidadEntregada,
    SapUnidadPeso,
    SapDenominacionMaterial,
    SapCentro,
    SapAlmacen
FROM ranked
WHERE rn = 1;
GO
