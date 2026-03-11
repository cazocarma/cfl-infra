/* ============================================================================
   MIGRACIÓN: Crea Productor y extiende CabeceraFlete
   Fecha: 2026-03-10
   Cambios:
   - Nueva tabla [cfl].[Productor] (fuente: dbo.Sap_BP)
   - Nuevas columnas en [cfl].[CabeceraFlete]: [IdProductor], [SentidoFlete]
   - FK [FK_CabeceraFlete_Productor] + índice [IX_CabeceraFlete_IdProductor]
============================================================================ */

BEGIN TRY
    BEGIN TRANSACTION;

    IF NOT EXISTS (
        SELECT 1
        FROM sys.tables t
        INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
        WHERE s.name = N'cfl' AND t.name = N'Productor'
    )
    BEGIN
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
            CONSTRAINT [PK_Productor] PRIMARY KEY ([IdProductor])
        );

        CREATE UNIQUE INDEX [UQ_Productor_CodigoProveedor]
            ON [cfl].[Productor] ([CodigoProveedor]);

        CREATE INDEX [IX_Productor_Rut]
            ON [cfl].[Productor] ([Rut]);
    END

    IF NOT EXISTS (
        SELECT 1 FROM sys.columns
        WHERE object_id = OBJECT_ID(N'[cfl].[CabeceraFlete]') AND name = N'IdProductor'
    )
    BEGIN
        ALTER TABLE [cfl].[CabeceraFlete]
            ADD [IdProductor] BIGINT NULL;
    END

    IF NOT EXISTS (
        SELECT 1 FROM sys.columns
        WHERE object_id = OBJECT_ID(N'[cfl].[CabeceraFlete]') AND name = N'SentidoFlete'
    )
    BEGIN
        ALTER TABLE [cfl].[CabeceraFlete]
            ADD [SentidoFlete] NVARCHAR(20) NULL;
    END

    IF NOT EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE name = N'IX_CabeceraFlete_IdProductor'
          AND object_id = OBJECT_ID(N'[cfl].[CabeceraFlete]')
    )
    BEGIN
        CREATE INDEX [IX_CabeceraFlete_IdProductor]
            ON [cfl].[CabeceraFlete] ([IdProductor]);
    END

    IF NOT EXISTS (
        SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_CabeceraFlete_Productor'
    )
    BEGIN
        ALTER TABLE [cfl].[CabeceraFlete]
        ADD CONSTRAINT [FK_CabeceraFlete_Productor]
        FOREIGN KEY ([IdProductor]) REFERENCES [cfl].[Productor] ([IdProductor])
        ON UPDATE NO ACTION ON DELETE NO ACTION;
    END

    COMMIT TRANSACTION;
    PRINT 'Migracion 20260310_add_productor_and_sentido_flete completada.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR('Migracion fallida: %s', 16, 1, @msg);
END CATCH;
GO
