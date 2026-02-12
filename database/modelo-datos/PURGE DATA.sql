/* ============================================================
   SQL Server – PURGA (DELETE FROM) SOLO ESQUEMA [cfl]
   - Deshabilita triggers y constraints involucradas
   - DELETE FROM en todas las tablas [cfl].*
   - (Opcional) Reseed identidades
   - Rehabilita constraints y triggers
   ============================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @DRY_RUN bit = 1;              -- 1 = solo imprime, 0 = ejecuta
DECLARE @RESEED_IDENTITIES bit = 1;    -- 1 = reseed identidades a 0

DECLARE @sql nvarchar(max) = N'';
DECLARE @crlf nchar(2) = NCHAR(13) + NCHAR(10);

BEGIN TRY
    BEGIN TRAN;

    /* 1) Deshabilitar triggers DML en tablas [cfl] */
    SELECT @sql = @sql +
        N'ALTER TABLE [cfl].' + QUOTENAME(t.name) + N' DISABLE TRIGGER ALL;' + @crlf
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
      AND s.name = 'cfl';

    /* 2) Deshabilitar FK/CHECK en tablas [cfl] */
    SELECT @sql = @sql +
        N'ALTER TABLE [cfl].' + QUOTENAME(t.name) + N' NOCHECK CONSTRAINT ALL;' + @crlf
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
      AND s.name = 'cfl';

    /* 3) DELETE FROM en todas las tablas [cfl] */
    SELECT @sql = @sql +
        N'DELETE FROM [cfl].' + QUOTENAME(t.name) + N';' + @crlf
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
      AND s.name = 'cfl';

    /* 4) (Opcional) Reseed identidades en [cfl] */
    IF (@RESEED_IDENTITIES = 1)
    BEGIN
        SELECT @sql = @sql +
            N'DBCC CHECKIDENT (''' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N''', RESEED, 0);' + @crlf
        FROM sys.tables t
        JOIN sys.schemas s ON s.schema_id = t.schema_id
        WHERE t.is_ms_shipped = 0
          AND s.name = 'cfl'
          AND EXISTS (
              SELECT 1
              FROM sys.columns c
              WHERE c.object_id = t.object_id
                AND c.is_identity = 1
          );
    END

    /* 5) Rehabilitar constraints en [cfl] (y revalidar) */
    SELECT @sql = @sql +
        N'ALTER TABLE [cfl].' + QUOTENAME(t.name) + N' WITH CHECK CHECK CONSTRAINT ALL;' + @crlf
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
      AND s.name = 'cfl';

    /* 6) Rehabilitar triggers en [cfl] */
    SELECT @sql = @sql +
        N'ALTER TABLE [cfl].' + QUOTENAME(t.name) + N' ENABLE TRIGGER ALL;' + @crlf
    FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE t.is_ms_shipped = 0
      AND s.name = 'cfl';

    IF (@DRY_RUN = 1)
    BEGIN
        PRINT N'*** DRY_RUN=1 (NO se ejecutó). Cambia @DRY_RUN a 0 para ejecutar. ***';
        PRINT @sql;
        ROLLBACK TRAN;
    END
    ELSE
    BEGIN
        EXEC sp_executesql @sql;
        COMMIT TRAN;
        PRINT N'Purga [cfl] ejecutada (DELETE FROM) + constraints/triggers restaurados.';
    END
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    DECLARE @msg nvarchar(4000) = ERROR_MESSAGE();
    RAISERROR(N'Error en purga [cfl]: %s', 16, 1, @msg);
END CATCH;
