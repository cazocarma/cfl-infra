/* ============================================================================
   PATCH LIVE - Refactor imputacion flete (fase incremental)
   Fecha: 2026-03-11
   Objetivo:
   - Formalizar regla TipoFlete + CentroCosto + CuentaMayor en cfl.ImputacionFlete.
   - Agregar IdCuentaMayor en cfl.Folio.
   - Agregar IdImputacionFlete en cfl.CabeceraFlete.
   - Mantener compatibilidad con datos y columnas historicas existentes.
============================================================================ */
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
  BEGIN TRANSACTION;

  DECLARE @now DATETIME2(0) = SYSDATETIME();

  /* ------------------------------------------------------------------------
     1) Ajustes estructurales incrementales
  ------------------------------------------------------------------------ */

  IF COL_LENGTH('cfl.Folio', 'IdCuentaMayor') IS NULL
  BEGIN
    ALTER TABLE [cfl].[Folio]
      ADD [IdCuentaMayor] BIGINT NULL;
  END;

  IF COL_LENGTH('cfl.CabeceraFlete', 'IdImputacionFlete') IS NULL
  BEGIN
    ALTER TABLE [cfl].[CabeceraFlete]
      ADD [IdImputacionFlete] BIGINT NULL;
  END;

  IF OBJECT_ID('cfl.ImputacionFlete', 'U') IS NULL
  BEGIN
    CREATE TABLE [cfl].[ImputacionFlete] (
      [IdImputacionFlete]  BIGINT NOT NULL IDENTITY(1,1),
      [IdTipoFlete]        BIGINT NOT NULL,
      [IdCentroCosto]      BIGINT NOT NULL,
      [IdCuentaMayor]      BIGINT NOT NULL,
      [Activo]             BIT NOT NULL CONSTRAINT [DF_ImputacionFlete_Activo] DEFAULT (1),
      [FechaCreacion]      DATETIME2(0) NOT NULL CONSTRAINT [DF_ImputacionFlete_FechaCreacion] DEFAULT (SYSDATETIME()),
      [FechaActualizacion] DATETIME2(0) NOT NULL CONSTRAINT [DF_ImputacionFlete_FechaActualizacion] DEFAULT (SYSDATETIME()),
      CONSTRAINT [PK_ImputacionFlete] PRIMARY KEY CLUSTERED ([IdImputacionFlete])
    );
  END
  ELSE
  BEGIN
    IF COL_LENGTH('cfl.ImputacionFlete', 'Activo') IS NULL
      ALTER TABLE [cfl].[ImputacionFlete] ADD [Activo] BIT NOT NULL CONSTRAINT [DF_ImputacionFlete_Activo] DEFAULT (1);

    IF COL_LENGTH('cfl.ImputacionFlete', 'FechaCreacion') IS NULL
      ALTER TABLE [cfl].[ImputacionFlete] ADD [FechaCreacion] DATETIME2(0) NOT NULL CONSTRAINT [DF_ImputacionFlete_FechaCreacion] DEFAULT (SYSDATETIME());

    IF COL_LENGTH('cfl.ImputacionFlete', 'FechaActualizacion') IS NULL
      ALTER TABLE [cfl].[ImputacionFlete] ADD [FechaActualizacion] DATETIME2(0) NOT NULL CONSTRAINT [DF_ImputacionFlete_FechaActualizacion] DEFAULT (SYSDATETIME());
  END;

  IF EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'FK_TipoFlete_CentroCosto'
      AND parent_object_id = OBJECT_ID('cfl.TipoFlete')
  )
  BEGIN
    ALTER TABLE [cfl].[TipoFlete] DROP CONSTRAINT [FK_TipoFlete_CentroCosto];
  END;

  IF COL_LENGTH('cfl.TipoFlete', 'IdCentroCosto') IS NOT NULL
  BEGIN
    IF EXISTS (
      SELECT 1
      FROM sys.columns
      WHERE object_id = OBJECT_ID('cfl.TipoFlete')
        AND name = 'IdCentroCosto'
        AND is_nullable = 0
    )
    BEGIN
      ALTER TABLE [cfl].[TipoFlete] ALTER COLUMN [IdCentroCosto] BIGINT NULL;
    END;
  END;

  /* ------------------------------------------------------------------------
     2) Catalogos maestros idempotentes (tipos, centros, cuentas)
  ------------------------------------------------------------------------ */

  ;WITH src(SapCodigo, Nombre, Activo) AS (
    SELECT *
    FROM (VALUES
      (N'GC1010301', N'POR DEFINIR', 1),
      (N'GC2010103', N'Proceso', 1),
      (N'GC1070101', N'Bodega Maipo', 1),
      (N'GC2010701', N'Linea Produccion Mercado Interno', 1),
      (N'GC2010401', N'Maipo ATM', 1),
      (N'GC5020101', N'Programa Maipo', 1),
      (N'GC2030106', N'Proceso', 1),
      (N'GC1070201', N'Bodega Placilla', 1),
      (N'GC2030301', N'Placilla Usda/Sag', 1),
      (N'GC2030401', N'Linea Produccion Uva', 1),
      (N'GC2030601', N'Linea Produccion Mercado Interno', 1),
      (N'GC2040401', N'Organik ATM', 1),
      (N'GC2040301', N'Organik Usda/Sag', 1),
      (N'GC3020101', N'Exp-Com-Comex', 1),
      (N'GC5020201', N'Programa Placilla', 1),
      (N'GC2050104', N'Proceso', 1),
      (N'GC1070301', N'Bodega Los Angeles', 1),
      (N'GC2050301', N'Los Angeles Usda/Sag', 1),
      (N'GC2050401', N'Los Angeles ATM', 1),
      (N'GC5020301', N'Programa Los Angeles', 1)
    ) v(SapCodigo, Nombre, Activo)
  )
  MERGE [cfl].[CentroCosto] AS t
  USING src AS s
    ON t.SapCodigo = s.SapCodigo
  WHEN MATCHED THEN
    UPDATE SET
      t.Nombre = s.Nombre,
      t.Activo = CAST(s.Activo AS BIT)
  WHEN NOT MATCHED THEN
    INSERT (SapCodigo, Nombre, Activo)
    VALUES (s.SapCodigo, s.Nombre, CAST(s.Activo AS BIT));

  ;WITH src(Codigo, Glosa) AS (
    SELECT *
    FROM (VALUES
      (N'51020314', N'FLETES INTERPLANTA / FRUTA EXPORTACION'),
      (N'51020315', N'FLETES MATERIALES / TRANSPORTE EXPORTACION'),
      (N'51020316', N'FLETES MERCADO NACIONAL'),
      (N'51020317', N'FLETES ATMOSFERA CONTROLADA'),
      (N'51020318', N'FLETES MUESTRAS USDA')
    ) v(Codigo, Glosa)
  )
  MERGE [cfl].[CuentaMayor] AS t
  USING src AS s
    ON t.Codigo = s.Codigo
  WHEN MATCHED THEN
    UPDATE SET t.Glosa = s.Glosa
  WHEN NOT MATCHED THEN
    INSERT (Codigo, Glosa)
    VALUES (s.Codigo, s.Glosa);

  IF COL_LENGTH('cfl.TipoFlete', 'IdCentroCosto') IS NULL
  BEGIN
    ;WITH src(SapCodigo, Nombre, Activo) AS (
      SELECT *
      FROM (VALUES
        (N'0001', N'TRASLADO DE FRUTA', 1),
        (N'0002', N'TRASLADO DE MATERIALES', 1),
        (N'0003', N'TRASLADO PUERTO - AEROPUERTO', 1),
        (N'0004', N'TRASLADO INTERPLANTA', 1),
        (N'0005', N'TRASLADO MERCADO NACIONAL', 1),
        (N'0006', N'TRASLADO MUESTRA USDA', 1)
      ) v(SapCodigo, Nombre, Activo)
    )
    MERGE [cfl].[TipoFlete] AS t
    USING src AS s
      ON t.SapCodigo = s.SapCodigo
    WHEN MATCHED THEN
      UPDATE SET
        t.Nombre = s.Nombre,
        t.Activo = CAST(s.Activo AS BIT)
    WHEN NOT MATCHED THEN
      INSERT (SapCodigo, Nombre, Activo)
      VALUES (s.SapCodigo, s.Nombre, CAST(s.Activo AS BIT));
  END
  ELSE
  BEGIN
    ;WITH src(SapCodigo, Nombre, Activo) AS (
      SELECT *
      FROM (VALUES
        (N'0001', N'TRASLADO DE FRUTA', 1),
        (N'0002', N'TRASLADO DE MATERIALES', 1),
        (N'0003', N'TRASLADO PUERTO - AEROPUERTO', 1),
        (N'0004', N'TRASLADO INTERPLANTA', 1),
        (N'0005', N'TRASLADO MERCADO NACIONAL', 1),
        (N'0006', N'TRASLADO MUESTRA USDA', 1)
      ) v(SapCodigo, Nombre, Activo)
    ), fallback_cc AS (
      SELECT TOP 1 IdCentroCosto
      FROM [cfl].[CentroCosto]
      WHERE SapCodigo = N'GC1010301'
      ORDER BY IdCentroCosto ASC
    )
    MERGE [cfl].[TipoFlete] AS t
    USING (
      SELECT
        s.SapCodigo,
        s.Nombre,
        s.Activo,
        IdCentroCosto = COALESCE(fc.IdCentroCosto, cc.IdCentroCosto)
      FROM src s
      CROSS APPLY (
        SELECT TOP 1 IdCentroCosto
        FROM [cfl].[CentroCosto]
        ORDER BY IdCentroCosto ASC
      ) cc
      OUTER APPLY (
        SELECT TOP 1 IdCentroCosto
        FROM fallback_cc
      ) fc
    ) AS s
      ON t.SapCodigo = s.SapCodigo
    WHEN MATCHED THEN
      UPDATE SET
        t.Nombre = s.Nombre,
        t.Activo = CAST(s.Activo AS BIT)
    WHEN NOT MATCHED THEN
      INSERT (SapCodigo, Nombre, Activo, IdCentroCosto)
      VALUES (s.SapCodigo, s.Nombre, CAST(s.Activo AS BIT), s.IdCentroCosto);
  END;

  /* ------------------------------------------------------------------------
     3) Seed de reglas de imputacion
  ------------------------------------------------------------------------ */

  ;WITH src(TipoSapCodigo, CentroSapCodigo, CuentaCodigo, Activo) AS (
    SELECT *
    FROM (VALUES
      (N'0004', N'GC2010103', N'51020314', 1),
      (N'0002', N'GC1070101', N'51020315', 1),
      (N'0005', N'GC2010701', N'51020316', 1),
      (N'0004', N'GC2010401', N'51020317', 1),
      (N'0001', N'GC5020101', N'51020314', 1),
      (N'0004', N'GC2030106', N'51020314', 1),
      (N'0002', N'GC1070201', N'51020315', 1),
      (N'0006', N'GC2030301', N'51020318', 1),
      (N'0004', N'GC2030401', N'51020314', 1),
      (N'0005', N'GC2030601', N'51020316', 1),
      (N'0004', N'GC2040401', N'51020317', 1),
      (N'0006', N'GC2040301', N'51020318', 1),
      (N'0003', N'GC3020101', N'51020315', 1),
      (N'0001', N'GC5020201', N'51020314', 1),
      (N'0004', N'GC2050104', N'51020314', 1),
      (N'0002', N'GC1070301', N'51020315', 1),
      (N'0006', N'GC2050301', N'51020318', 1),
      (N'0004', N'GC2050401', N'51020317', 1),
      (N'0001', N'GC5020301', N'51020314', 1)
    ) v(TipoSapCodigo, CentroSapCodigo, CuentaCodigo, Activo)
  ), resolved AS (
    SELECT
      tf.IdTipoFlete,
      cc.IdCentroCosto,
      cm.IdCuentaMayor,
      s.Activo
    FROM src s
    INNER JOIN [cfl].[TipoFlete] tf ON tf.SapCodigo = s.TipoSapCodigo
    INNER JOIN [cfl].[CentroCosto] cc ON cc.SapCodigo = s.CentroSapCodigo
    INNER JOIN [cfl].[CuentaMayor] cm ON cm.Codigo = s.CuentaCodigo
  )
  MERGE [cfl].[ImputacionFlete] AS t
  USING resolved AS s
    ON t.IdTipoFlete = s.IdTipoFlete
   AND t.IdCentroCosto = s.IdCentroCosto
   AND t.IdCuentaMayor = s.IdCuentaMayor
  WHEN MATCHED THEN
    UPDATE SET
      t.Activo = CAST(s.Activo AS BIT),
      t.FechaActualizacion = @now
  WHEN NOT MATCHED THEN
    INSERT (IdTipoFlete, IdCentroCosto, IdCuentaMayor, Activo, FechaCreacion, FechaActualizacion)
    VALUES (s.IdTipoFlete, s.IdCentroCosto, s.IdCuentaMayor, CAST(s.Activo AS BIT), @now, @now);

  /* ------------------------------------------------------------------------
     4) Backfill progresivo
  ------------------------------------------------------------------------ */

  UPDATE cf
  SET
    cf.IdCuentaMayor = cm.IdCuentaMayor,
    cf.FechaActualizacion = @now
  FROM [cfl].[CabeceraFlete] cf
  INNER JOIN [cfl].[CuentaMayor] cm
    ON cm.Codigo = NULLIF(LTRIM(RTRIM(cf.SapCuentaMayor)), '')
  WHERE cf.IdCuentaMayor IS NULL
    AND NULLIF(LTRIM(RTRIM(cf.SapCuentaMayor)), '') IS NOT NULL;

  ;WITH frecuencia AS (
    SELECT
      cf.IdFolio,
      cf.IdCuentaMayor,
      Cnt = COUNT_BIG(1)
    FROM [cfl].[CabeceraFlete] cf
    WHERE cf.IdFolio IS NOT NULL
      AND cf.IdCuentaMayor IS NOT NULL
    GROUP BY cf.IdFolio, cf.IdCuentaMayor
  ), ranked AS (
    SELECT
      f.IdFolio,
      f.IdCuentaMayor,
      rn = ROW_NUMBER() OVER (
        PARTITION BY f.IdFolio
        ORDER BY f.Cnt DESC, f.IdCuentaMayor ASC
      )
    FROM frecuencia f
  )
  UPDATE f
  SET f.IdCuentaMayor = r.IdCuentaMayor
  FROM [cfl].[Folio] f
  INNER JOIN ranked r
    ON r.IdFolio = f.IdFolio
   AND r.rn = 1
  WHERE f.IdCuentaMayor IS NULL;

  UPDATE cf
  SET
    cf.IdImputacionFlete = im.IdImputacionFlete,
    cf.FechaActualizacion = @now
  FROM [cfl].[CabeceraFlete] cf
  INNER JOIN [cfl].[ImputacionFlete] im
    ON im.IdTipoFlete = cf.IdTipoFlete
   AND im.IdCentroCosto = cf.IdCentroCosto
   AND im.IdCuentaMayor = cf.IdCuentaMayor
  WHERE cf.IdImputacionFlete IS NULL
    AND cf.IdTipoFlete IS NOT NULL
    AND cf.IdCentroCosto IS NOT NULL
    AND cf.IdCuentaMayor IS NOT NULL;

  /* ------------------------------------------------------------------------
     5) Constraints e indices (idempotentes)
  ------------------------------------------------------------------------ */

  IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('cfl.Folio')
      AND name = 'UQ_Folio_TemporadaCc'
  )
  BEGIN
    DROP INDEX [UQ_Folio_TemporadaCc] ON [cfl].[Folio];
  END;

  IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('cfl.Folio')
      AND name = 'UQ_Folio_TemporadaCcCuenta'
  )
  BEGIN
    CREATE UNIQUE INDEX [UQ_Folio_TemporadaCcCuenta]
      ON [cfl].[Folio] ([IdTemporada], [IdCentroCosto], [IdCuentaMayor], [FolioNumero]);
  END;

  IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('cfl.ImputacionFlete')
      AND name = 'UQ_ImputacionFlete_Combo'
  )
  BEGIN
    CREATE UNIQUE INDEX [UQ_ImputacionFlete_Combo]
      ON [cfl].[ImputacionFlete] ([IdTipoFlete], [IdCentroCosto], [IdCuentaMayor]);
  END;

  IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('cfl.ImputacionFlete')
      AND name = 'IX_ImputacionFlete_TipoActivo'
  )
  BEGIN
    CREATE INDEX [IX_ImputacionFlete_TipoActivo]
      ON [cfl].[ImputacionFlete] ([IdTipoFlete], [Activo], [IdCentroCosto], [IdCuentaMayor]);
  END;

  IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('cfl.CabeceraFlete')
      AND name = 'IX_CabeceraFlete_IdImputacionFlete'
  )
  BEGIN
    CREATE INDEX [IX_CabeceraFlete_IdImputacionFlete]
      ON [cfl].[CabeceraFlete] ([IdImputacionFlete]);
  END;

  IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'FK_ImputacionFlete_TipoFlete'
      AND parent_object_id = OBJECT_ID('cfl.ImputacionFlete')
  )
  BEGIN
    ALTER TABLE [cfl].[ImputacionFlete]
      ADD CONSTRAINT [FK_ImputacionFlete_TipoFlete]
      FOREIGN KEY ([IdTipoFlete]) REFERENCES [cfl].[TipoFlete] ([IdTipoFlete]);
  END;

  IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'FK_ImputacionFlete_CentroCosto'
      AND parent_object_id = OBJECT_ID('cfl.ImputacionFlete')
  )
  BEGIN
    ALTER TABLE [cfl].[ImputacionFlete]
      ADD CONSTRAINT [FK_ImputacionFlete_CentroCosto]
      FOREIGN KEY ([IdCentroCosto]) REFERENCES [cfl].[CentroCosto] ([IdCentroCosto]);
  END;

  IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'FK_ImputacionFlete_CuentaMayor'
      AND parent_object_id = OBJECT_ID('cfl.ImputacionFlete')
  )
  BEGIN
    ALTER TABLE [cfl].[ImputacionFlete]
      ADD CONSTRAINT [FK_ImputacionFlete_CuentaMayor]
      FOREIGN KEY ([IdCuentaMayor]) REFERENCES [cfl].[CuentaMayor] ([IdCuentaMayor]);
  END;

  IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'FK_Folio_CuentaMayor'
      AND parent_object_id = OBJECT_ID('cfl.Folio')
  )
  BEGIN
    ALTER TABLE [cfl].[Folio]
      ADD CONSTRAINT [FK_Folio_CuentaMayor]
      FOREIGN KEY ([IdCuentaMayor]) REFERENCES [cfl].[CuentaMayor] ([IdCuentaMayor]);
  END;

  IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'FK_CabeceraFlete_ImputacionFlete'
      AND parent_object_id = OBJECT_ID('cfl.CabeceraFlete')
  )
  BEGIN
    ALTER TABLE [cfl].[CabeceraFlete]
      ADD CONSTRAINT [FK_CabeceraFlete_ImputacionFlete]
      FOREIGN KEY ([IdImputacionFlete]) REFERENCES [cfl].[ImputacionFlete] ([IdImputacionFlete]);
  END;

  COMMIT TRANSACTION;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;

  THROW;
END CATCH;
