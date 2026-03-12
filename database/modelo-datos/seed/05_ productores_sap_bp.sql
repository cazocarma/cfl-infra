/* ============================================================================
   CARGA PRODUCTORES DESDE SAP
   Fuente : dbo.Sap_BP
   Destino: cfl.Productor
   Regla  : si hay duplicados por proveedor, solo se toma el primer registro
            (ordenado por FechaHoraOdata ascendente).
============================================================================ */

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'[cfl].[Productor]', N'U') IS NULL
        RAISERROR('La tabla [cfl].[Productor] no existe. Ejecuta UP.sql o migracion primero.', 16, 1);

    IF OBJECT_ID(N'[DBPRD].[dbo].[Sap_BP]', N'U') IS NULL
        RAISERROR('La tabla fuente [dbo].[Sap_BP] no existe.', 16, 1);

    ;WITH src AS (
        SELECT
            CodigoProveedor = NULLIF(LTRIM(RTRIM(CAST([BpDetalleProductores_Proveedor] AS NVARCHAR(20)))), ''),
            Rut = NULLIF(LTRIM(RTRIM(CAST([BpDetalleProductores_Rut] AS NVARCHAR(20)))), ''),
            Nombre = COALESCE(
                NULLIF(LTRIM(RTRIM(CAST([BpDetalleProductores_Nombre] AS NVARCHAR(150)))), ''),
                NULLIF(LTRIM(RTRIM(CAST([BpDetalleProductores_DenomacionBreve] AS NVARCHAR(150)))), ''),
                N'SIN_NOMBRE'
            ),
            Pais = NULLIF(LTRIM(RTRIM(CAST([BpDetalleProductores_Pais] AS NVARCHAR(2)))), ''),
            Region = NULLIF(LTRIM(RTRIM(CAST([BpDetalleProductores_Region] AS NVARCHAR(10)))), ''),
            Comuna = NULLIF(LTRIM(RTRIM(CAST([BpDetalleProductores_Poblacion] AS NVARCHAR(100)))), ''),
            Distrito = NULLIF(LTRIM(RTRIM(CAST([BpDetalleProductores_Distrito] AS NVARCHAR(100)))), ''),
            Calle = NULLIF(LTRIM(RTRIM(CAST([BpDetalleProductores_Calle] AS NVARCHAR(150)))), ''),
            Email = COALESCE(
                NULLIF(LTRIM(RTRIM(CAST([BpDetalleProductores_EmailProd] AS NVARCHAR(150)))), ''),
                NULLIF(LTRIM(RTRIM(CAST([BpDetalleProductores_EmailAdm] AS NVARCHAR(150)))), ''),
                NULLIF(LTRIM(RTRIM(CAST([BpDetalleProductores_Email] AS NVARCHAR(150)))), '')
            ),
            OrganizacionCompra = NULLIF(LTRIM(RTRIM(CAST([BpDetalleProductores_OrganizacionCompras] AS NVARCHAR(10)))), ''),
            MonedaPedido = NULLIF(LTRIM(RTRIM(CAST([BpDetalleProductores_MonedaPedido] AS NVARCHAR(3)))), ''),
            CondicionPago = NULLIF(LTRIM(RTRIM(CAST([BpDetalleProductores_CondicionPago] AS NVARCHAR(20)))), ''),
            Incoterm = NULLIF(LTRIM(RTRIM(CAST([BpDetalleProductores_Incoterm] AS NVARCHAR(10)))), ''),
            Sociedad = NULLIF(LTRIM(RTRIM(CAST([BpDetalleProductores_Sociedad] AS NVARCHAR(10)))), ''),
            CuentaAsociada = NULLIF(LTRIM(RTRIM(CAST([BpDetalleProductores_CuentaAsociada] AS NVARCHAR(30)))), ''),
            Activo = CASE WHEN TRY_CONVERT(INT, [BpDetalleProductores_PeticionBorradoSociedad]) = 1 THEN 0 ELSE 1 END,
            FechaActualizacionSap = TRY_CONVERT(DATETIME2(3), [BpDetalleProductores_FechaHoraOdata])
        FROM [DBPRD].[dbo].[Sap_BP]
    ),
    src_ranked AS (
        SELECT
            CodigoProveedor,
            Rut,
            Nombre,
            Pais,
            Region,
            Comuna,
            Distrito,
            Calle,
            Email,
            OrganizacionCompra,
            MonedaPedido,
            CondicionPago,
            Incoterm,
            Sociedad,
            CuentaAsociada,
            Activo,
            FechaActualizacionSap,
            rn = ROW_NUMBER() OVER (
                PARTITION BY CodigoProveedor
                ORDER BY
                    FechaActualizacionSap ASC,
                    Rut ASC,
                    Nombre ASC
            )
        FROM src
        WHERE CodigoProveedor IS NOT NULL
    )
    INSERT INTO [cfl].[Productor] (
        [CodigoProveedor],
        [Rut],
        [Nombre],
        [Pais],
        [Region],
        [Comuna],
        [Distrito],
        [Calle],
        [Email],
        [OrganizacionCompra],
        [MonedaPedido],
        [CondicionPago],
        [Incoterm],
        [Sociedad],
        [CuentaAsociada],
        [Activo],
        [FechaActualizacionSap],
        [FechaCreacion],
        [FechaActualizacion]
    )
    SELECT
        s.[CodigoProveedor],
        s.[Rut],
        s.[Nombre],
        s.[Pais],
        s.[Region],
        s.[Comuna],
        s.[Distrito],
        s.[Calle],
        s.[Email],
        s.[OrganizacionCompra],
        s.[MonedaPedido],
        s.[CondicionPago],
        s.[Incoterm],
        s.[Sociedad],
        s.[CuentaAsociada],
        s.[Activo],
        s.[FechaActualizacionSap],
        SYSUTCDATETIME(),
        SYSUTCDATETIME()
    FROM src_ranked s
    WHERE s.rn = 1
      AND NOT EXISTS (
          SELECT 1
          FROM [cfl].[Productor] t
          WHERE t.[CodigoProveedor] = s.[CodigoProveedor]
      );

    DECLARE @filasInsertadas INT = @@ROWCOUNT;

    COMMIT TRANSACTION;
    PRINT CONCAT('Carga de productores completada. Filas insertadas: ', @filasInsertadas);
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR('Carga de productores fallida: %s', 16, 1, @msg);
END CATCH;
GO

