BEGIN TRANSACTION;
SET NOCOUNT ON;

DECLARE @now DATETIME2(0) = SYSDATETIME();
DECLARE @id_tc_plano_solo BIGINT = (
    SELECT TOP (1) IdTipoCamion
    FROM [cfl].[TipoCamion]
    WHERE nombre = 'PLANO SOLO'
);
DECLARE @id_tc_plano_carro BIGINT = (
    SELECT TOP (1) IdTipoCamion
    FROM [cfl].[TipoCamion]
    WHERE nombre = 'PLANO CON CARRO'
);

IF @id_tc_plano_solo IS NULL OR @id_tc_plano_carro IS NULL
BEGIN
    ROLLBACK TRANSACTION;
    THROW 50001, 'No existen los tipos de camion base (PLANO SOLO / PLANO CON CARRO).', 1;
END;

;WITH raw_normalized AS (
    SELECT
        SapPatente = NULLIF(LTRIM(RTRIM(SapPatente)), ''),
        SapCarro = CASE
            WHEN NULLIF(LTRIM(RTRIM(SapCarro)), '') IS NULL THEN 'SIN-CARRO'
            ELSE LTRIM(RTRIM(SapCarro))
        END,
        FechaExtraccion,
        IdSapLikpRaw
    FROM [cfl].[SapLikpRaw]
),
raw_valid AS (
    SELECT
        SapPatente,
        SapCarro,
        FechaExtraccion,
        IdSapLikpRaw,
        rn = ROW_NUMBER() OVER (
            PARTITION BY SapPatente, SapCarro
            ORDER BY FechaExtraccion DESC, IdSapLikpRaw DESC
        )
    FROM raw_normalized
    WHERE SapPatente IS NOT NULL
),
src AS (
    SELECT
        IdTipoCamion = CASE
            WHEN SapCarro = 'SIN-CARRO' THEN @id_tc_plano_solo
            ELSE @id_tc_plano_carro
        END,
        SapPatente,
        SapCarro,
        activo = CAST(1 AS BIT)
    FROM raw_valid
    WHERE rn = 1
)
MERGE [cfl].[Camion] AS t
USING src AS s
    ON t.SapPatente = s.SapPatente
   AND t.SapCarro = s.SapCarro
WHEN MATCHED THEN
    UPDATE SET
        t.IdTipoCamion = s.IdTipoCamion,
        t.activo = s.activo,
        t.FechaActualizacion = @now
WHEN NOT MATCHED THEN
    INSERT (IdTipoCamion, SapPatente, SapCarro, activo, FechaCreacion, FechaActualizacion)
    VALUES (s.IdTipoCamion, s.SapPatente, s.SapCarro, s.activo, @now, @now);

COMMIT TRANSACTION;
