/* ============================================================================
   DROP completo del esquema [cfl]
   - Elimina FKs que estén EN o APUNTEN a tablas del esquema cfl
   - Elimina objetos del esquema cfl (views/procs/functions/synonyms/sequences) por si existen
   - Elimina tablas del esquema cfl
   - Elimina el esquema cfl

   Nota: Esto es destructivo. Úsalo en el ambiente correcto.
============================================================================ */

IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'cfl')
BEGIN
    DECLARE @sql NVARCHAR(MAX);

    /* 1) Drop Foreign Keys (padre en cfl o referenciando a cfl) */
    SET @sql = N'';
    SELECT @sql = @sql
        + N'ALTER TABLE ' + QUOTENAME(ps.name) + N'.' + QUOTENAME(pt.name)
        + N' DROP CONSTRAINT ' + QUOTENAME(fk.name) + N';' + CHAR(10)
    FROM sys.foreign_keys fk
    JOIN sys.tables pt ON fk.parent_object_id = pt.object_id
    JOIN sys.schemas ps ON pt.schema_id = ps.schema_id
    JOIN sys.tables rt ON fk.referenced_object_id = rt.object_id
    JOIN sys.schemas rs ON rt.schema_id = rs.schema_id
    WHERE ps.name = N'cfl' OR rs.name = N'cfl';

    IF @sql <> N'' EXEC sys.sp_executesql @sql;

    /* 2) Drop Views en cfl (si existieran) */
    SET @sql = N'';
    SELECT @sql = @sql
        + N'DROP VIEW ' + QUOTENAME(s.name) + N'.' + QUOTENAME(v.name) + N';' + CHAR(10)
    FROM sys.views v
    JOIN sys.schemas s ON v.schema_id = s.schema_id
    WHERE s.name = N'cfl';

    IF @sql <> N'' EXEC sys.sp_executesql @sql;

    /* 3) Drop Procedures en cfl (si existieran) */
    SET @sql = N'';
    SELECT @sql = @sql
        + N'DROP PROCEDURE ' + QUOTENAME(s.name) + N'.' + QUOTENAME(p.name) + N';' + CHAR(10)
    FROM sys.procedures p
    JOIN sys.schemas s ON p.schema_id = s.schema_id
    WHERE s.name = N'cfl';

    IF @sql <> N'' EXEC sys.sp_executesql @sql;

    /* 4) Drop Functions en cfl (si existieran) */
    SET @sql = N'';
    SELECT @sql = @sql
        + N'DROP FUNCTION ' + QUOTENAME(s.name) + N'.' + QUOTENAME(o.name) + N';' + CHAR(10)
    FROM sys.objects o
    JOIN sys.schemas s ON o.schema_id = s.schema_id
    WHERE s.name = N'cfl'
      AND o.type IN ('FN','IF','TF'); -- Scalar / Inline TVF / Multi-statement TVF

    IF @sql <> N'' EXEC sys.sp_executesql @sql;

    /* 5) Drop Synonyms en cfl (si existieran) */
    SET @sql = N'';
    SELECT @sql = @sql
        + N'DROP SYNONYM ' + QUOTENAME(s.name) + N'.' + QUOTENAME(sn.name) + N';' + CHAR(10)
    FROM sys.synonyms sn
    JOIN sys.schemas s ON sn.schema_id = s.schema_id
    WHERE s.name = N'cfl';

    IF @sql <> N'' EXEC sys.sp_executesql @sql;

    /* 6) Drop Sequences en cfl (si existieran) */
    SET @sql = N'';
    SELECT @sql = @sql
        + N'DROP SEQUENCE ' + QUOTENAME(s.name) + N'.' + QUOTENAME(seq.name) + N';' + CHAR(10)
    FROM sys.sequences seq
    JOIN sys.schemas s ON seq.schema_id = s.schema_id
    WHERE s.name = N'cfl';

    IF @sql <> N'' EXEC sys.sp_executesql @sql;

    /* 7) Drop Tables en cfl (ya sin FKs) */
    SET @sql = N'';
    SELECT @sql = @sql
        + N'DROP TABLE ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N';' + CHAR(10)
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = N'cfl';

    IF @sql <> N'' EXEC sys.sp_executesql @sql;

    /* 8) Drop Schema */
    DROP SCHEMA [cfl];
END
GO
