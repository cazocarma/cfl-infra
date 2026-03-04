BEGIN TRANSACTION;
SET NOCOUNT ON;

DECLARE @now DATETIME2(0) = SYSDATETIME();
DECLARE @id_tc_plano_solo BIGINT = (
    SELECT TOP (1) id_tipo_camion
    FROM [cfl].[CFL_tipo_camion]
    WHERE nombre = 'PLANO SOLO'
);
DECLARE @id_tc_plano_carro BIGINT = (
    SELECT TOP (1) id_tipo_camion
    FROM [cfl].[CFL_tipo_camion]
    WHERE nombre = 'PLANO CON CARRO'
);

IF @id_tc_plano_solo IS NULL OR @id_tc_plano_carro IS NULL
BEGIN
    ROLLBACK TRANSACTION;
    THROW 50001, 'No existen los tipos de camion base (PLANO SOLO / PLANO CON CARRO).', 1;
END;

;WITH raw_normalized AS (
    SELECT
        sap_patente = NULLIF(LTRIM(RTRIM(sap_patente)), ''),
        sap_carro = CASE
            WHEN NULLIF(LTRIM(RTRIM(sap_carro)), '') IS NULL THEN 'SIN-CARRO'
            ELSE LTRIM(RTRIM(sap_carro))
        END,
        extracted_at,
        raw_id
    FROM [cfl].[CFL_sap_likp_raw]
),
raw_valid AS (
    SELECT
        sap_patente,
        sap_carro,
        extracted_at,
        raw_id,
        rn = ROW_NUMBER() OVER (
            PARTITION BY sap_patente, sap_carro
            ORDER BY extracted_at DESC, raw_id DESC
        )
    FROM raw_normalized
    WHERE sap_patente IS NOT NULL
),
src AS (
    SELECT
        id_tipo_camion = CASE
            WHEN sap_carro = 'SIN-CARRO' THEN @id_tc_plano_solo
            ELSE @id_tc_plano_carro
        END,
        sap_patente,
        sap_carro,
        activo = CAST(1 AS BIT)
    FROM raw_valid
    WHERE rn = 1
)
MERGE [cfl].[CFL_camion] AS t
USING src AS s
    ON t.sap_patente = s.sap_patente
   AND t.sap_carro = s.sap_carro
WHEN MATCHED THEN
    UPDATE SET
        t.id_tipo_camion = s.id_tipo_camion,
        t.activo = s.activo,
        t.updated_at = @now
WHEN NOT MATCHED THEN
    INSERT (id_tipo_camion, sap_patente, sap_carro, activo, created_at, updated_at)
    VALUES (s.id_tipo_camion, s.sap_patente, s.sap_carro, s.activo, @now, @now);

COMMIT TRANSACTION;
