BEGIN TRANSACTION;
SET NOCOUNT ON;

;WITH raw_normalized AS (
    SELECT
        SapIdFiscal = NULLIF(LTRIM(RTRIM(SapIdFiscalChofer)), ''),
        SapNombre    = NULLIF(LTRIM(RTRIM(SapNombreChofer)), ''),
        FechaExtraccion,
        IdSapLikpRaw
    FROM [cfl].[SapLikpRaw]
),
raw_valid AS (
    SELECT
        SapIdFiscal,
        SapNombre,
        FechaExtraccion,
        IdSapLikpRaw,
        rn = ROW_NUMBER() OVER (
            PARTITION BY SapIdFiscal
            ORDER BY FechaExtraccion DESC, IdSapLikpRaw DESC
        )
    FROM raw_normalized
    WHERE SapIdFiscal IS NOT NULL
      AND SapNombre IS NOT NULL
),
src AS (
    SELECT
        SapIdFiscal,
        SapNombre,
        telefono = CAST(NULL AS VARCHAR(20))
    FROM raw_valid
    WHERE rn = 1
)
MERGE [cfl].[Chofer] AS t
USING src AS s
    ON t.SapIdFiscal = s.SapIdFiscal
WHEN MATCHED THEN
    UPDATE SET
        t.SapNombre = s.SapNombre,
        t.activo = 1
WHEN NOT MATCHED THEN
    INSERT (SapIdFiscal, SapNombre, telefono, activo)
    VALUES (s.SapIdFiscal, s.SapNombre, s.telefono, 1);

COMMIT TRANSACTION;
