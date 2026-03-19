/* ============================================================================
   PATCH 20260318 - Tablas de staging permanentes para pipeline SAP on-demand
   Objetivo:
   - Reemplazar tablas temporales locales (#stg_likp, #stg_lips) que no son
     visibles entre requests mssql cuando MARS esta habilitado.
   - Las filas se scopean por IdEjecucion y se eliminan al finalizar cada job.
   Idempotente: SI
============================================================================ */
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

IF OBJECT_ID(N'[cfl].[StgLikp]', N'U') IS NULL
BEGIN
  CREATE TABLE [cfl].[StgLikp] (
    IdEjecucion           UNIQUEIDENTIFIER NOT NULL,
    FechaExtraccion       DATETIME2(0)     NOT NULL,
    SistemaFuente         NVARCHAR(50)     NOT NULL,
    HashFila              BINARY(32)       NOT NULL,
    EstadoFila            NVARCHAR(20)     NOT NULL,
    FechaCreacion         DATETIME2(0)     NOT NULL,
    SapNumeroEntrega      NVARCHAR(20)     NOT NULL,
    SapReferencia         CHAR(25)         NOT NULL,
    SapPuestoExpedicion   CHAR(4)          NOT NULL,
    SapDestinatario       NVARCHAR(20)     NULL,
    SapOrganizacionVentas CHAR(4)          NOT NULL,
    SapCreadoPor          CHAR(12)         NOT NULL,
    SapFechaCreacion      DATE             NOT NULL,
    SapClaseEntrega       CHAR(4)          NOT NULL,
    SapTipoEntrega        NVARCHAR(20)     NOT NULL,
    SapFechaCarga         DATE             NOT NULL,
    SapHoraCarga          VARCHAR(8)       NOT NULL,
    SapGuiaRemision       CHAR(25)         NOT NULL,
    SapNombreChofer       NVARCHAR(40)     NOT NULL,
    SapIdFiscalChofer     NVARCHAR(20)     NOT NULL,
    SapEmpresaTransporte  CHAR(3)          NOT NULL,
    SapPatente            NVARCHAR(20)     NOT NULL,
    SapCarro              NVARCHAR(20)     NOT NULL,
    SapFechaSalida        DATE             NOT NULL,
    SapHoraSalida         VARCHAR(8)       NOT NULL,
    SapCodigoTipoFlete    CHAR(4)          NOT NULL,
    SapCentroCosto        CHAR(10)         NULL,
    SapCuentaMayor        CHAR(10)         NULL,
    SapPesoTotal          DECIMAL(15,3)    NOT NULL,
    SapPesoNeto           DECIMAL(15,3)    NOT NULL,
    SapFechaEntregaReal   DATE             NOT NULL
  );

  CREATE INDEX [IX_StgLikp_Ejecucion]
    ON [cfl].[StgLikp] (IdEjecucion);
END;

IF OBJECT_ID(N'[cfl].[StgLips]', N'U') IS NULL
BEGIN
  CREATE TABLE [cfl].[StgLips] (
    IdEjecucion             UNIQUEIDENTIFIER NOT NULL,
    FechaExtraccion         DATETIME2(0)     NOT NULL,
    SistemaFuente           NVARCHAR(50)     NOT NULL,
    HashFila                BINARY(32)       NOT NULL,
    EstadoFila              NVARCHAR(20)     NOT NULL,
    FechaCreacion           DATETIME2(0)     NOT NULL,
    SapNumeroEntrega        NVARCHAR(20)     NOT NULL,
    SapPosicion             CHAR(6)          NOT NULL,
    SapPosicionSuperior     CHAR(6)          NULL,
    SapLote                 NVARCHAR(20)     NULL,
    SapMaterial             NVARCHAR(40)     NOT NULL,
    SapCantidadEntregada    DECIMAL(13,3)    NOT NULL,
    SapUnidadPeso           CHAR(3)          NOT NULL,
    SapDenominacionMaterial NVARCHAR(40)     NOT NULL,
    SapCentro               CHAR(4)          NOT NULL,
    SapAlmacen              CHAR(4)          NOT NULL
  );

  CREATE INDEX [IX_StgLips_Ejecucion]
    ON [cfl].[StgLips] (IdEjecucion);
END;

COMMIT TRANSACTION;
