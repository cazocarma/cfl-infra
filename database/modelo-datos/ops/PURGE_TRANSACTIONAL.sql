/* ============================================================================
   SQL Server - PURGA SELECTIVA: solo datos transaccionales del esquema [cfl]
   ============================================================================
   Elimina toda la data operativa/transaccional manteniendo los mantenedores
   base (catalogos, seguridad, logistica, tarifas, transporte).

   Tablas PRESERVADAS (mantenedores / seed):
     Temporada, CentroCosto, CuentaMayor, DetalleViaje, Especie, TipoFlete,
     ImputacionFlete, TipoCamion, NodoLogistico, Ruta, Tarifa,
     EmpresaTransporte, Chofer, Camion, Movil, Productor,
     Usuario, Rol, Permiso, UsuarioRol, RolPermiso

   Tablas PURGADAS (transaccional):
     -- ETL
     EtlEjecucion
     -- SAP raw
     SapLikpRaw, SapLipsRaw
     -- SAP canonicas + historial
     SapEntregaPosicionHistorial, SapEntregaPosicion,
     SapEntregaHistorial, SapEntrega, SapEntregaDescarte
     -- Fletes
     DetalleFlete, FleteEstadoHistorial, FleteSapEntrega, CabeceraFlete
     -- Facturas y planillas
     PlanillaSapLinea, PlanillaSapDocumento, PlanillaSap,
     ConciliacionFacturaFlete, CabeceraFactura
     -- Auditoria
     Auditoria

   Flags:
     @DRY_RUN            = 1  ->  solo imprime el SQL generado (default)
     @RESEED_IDENTITIES  = 1  ->  reinicia identity seeds a 0
   ============================================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @DRY_RUN           bit = 0;   -- 1 = solo imprime, 0 = ejecuta
DECLARE @RESEED_IDENTITIES bit = 1;   -- 1 = reseed identidades a 0

/* ----------------------------------------------------------------------------
   Orden de DELETE: hijos antes que padres (respetar FK).
   ---------------------------------------------------------------------------- */
DECLARE @tables TABLE (ord int IDENTITY(1,1), tabla sysname);

INSERT INTO @tables (tabla) VALUES
    /* ── Auditoria ── */
    ('Auditoria'),

    /* ── Planillas SAP (hijos primero) ── */
    ('PlanillaSapLinea'),
    ('PlanillaSapDocumento'),
    ('PlanillaSap'),

    /* ── Facturas (hijos primero) ── */
    ('ConciliacionFacturaFlete'),
    ('CabeceraFactura'),

    /* ── Fletes (hijos primero) ── */
    ('DetalleFlete'),
    ('FleteEstadoHistorial'),
    ('FleteSapEntrega'),
    ('CabeceraFlete'),

    /* ── SAP canonicas (hijos primero) ── */
    ('SapEntregaPosicionHistorial'),
    ('SapEntregaPosicion'),
    ('SapEntregaHistorial'),
    ('SapEntregaDescarte'),
    ('SapEntrega'),

    /* ── SAP raw ── */
    ('SapLipsRaw'),
    ('SapLikpRaw'),

    /* ── ETL ── */
    ('EtlEjecucion');

/* ============================================================================
   Construccion del script dinamico
   ============================================================================ */
DECLARE @sql  nvarchar(max) = N'';
DECLARE @crlf nchar(2)      = NCHAR(13) + NCHAR(10);

BEGIN TRY
    BEGIN TRAN;

    /* 1) Deshabilitar triggers en tablas a purgar */
    SELECT @sql = @sql
        + N'ALTER TABLE [cfl].' + QUOTENAME(t.tabla)
        + N' DISABLE TRIGGER ALL;' + @crlf
    FROM @tables t;

    /* 2) Deshabilitar FK/CHECK en tablas a purgar */
    SELECT @sql = @sql
        + N'ALTER TABLE [cfl].' + QUOTENAME(t.tabla)
        + N' NOCHECK CONSTRAINT ALL;' + @crlf
    FROM @tables t;

    /* 3) DELETE en orden topologico */
    SELECT @sql = @sql
        + N'DELETE FROM [cfl].' + QUOTENAME(t.tabla) + N';' + @crlf
    FROM @tables t
    ORDER BY t.ord;

    /* 4) Reseed identidades (opcional) */
    IF (@RESEED_IDENTITIES = 1)
    BEGIN
        SELECT @sql = @sql
            + N'DBCC CHECKIDENT (''[cfl].' + QUOTENAME(t.tabla)
            + N''', RESEED, 0);' + @crlf
        FROM @tables t
        WHERE EXISTS (
            SELECT 1
            FROM sys.tables    st
            JOIN sys.schemas   ss ON ss.schema_id = st.schema_id
            JOIN sys.columns   sc ON sc.object_id = st.object_id
            WHERE ss.name     = 'cfl'
              AND st.name     = t.tabla
              AND sc.is_identity = 1
        );
    END

    /* 5) Rehabilitar FK/CHECK (con revalidacion) */
    SELECT @sql = @sql
        + N'ALTER TABLE [cfl].' + QUOTENAME(t.tabla)
        + N' WITH CHECK CHECK CONSTRAINT ALL;' + @crlf
    FROM @tables t;

    /* 6) Rehabilitar triggers */
    SELECT @sql = @sql
        + N'ALTER TABLE [cfl].' + QUOTENAME(t.tabla)
        + N' ENABLE TRIGGER ALL;' + @crlf
    FROM @tables t;

    /* ========================================================================
       Ejecucion o dry-run
       ======================================================================== */
    IF (@DRY_RUN = 1)
    BEGIN
        PRINT N'================================================================';
        PRINT N'  DRY_RUN = 1  -  NO se ejecuto nada.';
        PRINT N'  Cambia @DRY_RUN a 0 para ejecutar la purga.';
        PRINT N'================================================================';
        PRINT @sql;
        ROLLBACK TRAN;
    END
    ELSE
    BEGIN
        EXEC sp_executesql @sql;

        /* Resumen de filas restantes (deberian ser 0) */
        DECLARE @check nvarchar(max) = N'';
        SELECT @check = @check
            + N'SELECT ''' + t.tabla + N''' AS Tabla, COUNT(*) AS Filas '
            + N'FROM [cfl].' + QUOTENAME(t.tabla) + N' UNION ALL ' + @crlf
        FROM @tables t;

        /* Quitar ultimo UNION ALL */
        SET @check = LEFT(@check, LEN(@check) - LEN(N'UNION ALL ' + @crlf));
        SET @check = @check + N' ORDER BY Tabla;';
        EXEC sp_executesql @check;

        COMMIT TRAN;
        PRINT N'================================================================';
        PRINT N'  Purga transaccional completada.';
        PRINT N'  Mantenedores intactos.';
        PRINT N'================================================================';
    END
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;

    DECLARE @err_msg    nvarchar(4000) = ERROR_MESSAGE();
    DECLARE @err_sev    int            = ERROR_SEVERITY();
    DECLARE @err_state  int            = ERROR_STATE();
    RAISERROR(N'Error en purga transaccional [cfl]: %s', @err_sev, @err_state, @err_msg);
END CATCH;
