BEGIN TRANSACTION;
SET NOCOUNT ON;

;WITH raw_normalized AS (
    SELECT
        sap_id_fiscal = NULLIF(LTRIM(RTRIM(sap_id_fiscal_chofer)), ''),
        sap_nombre    = NULLIF(LTRIM(RTRIM(sap_nombre_chofer)), ''),
        extracted_at,
        raw_id
    FROM [cfl].[CFL_sap_likp_raw]
),
raw_valid AS (
    SELECT
        sap_id_fiscal,
        sap_nombre,
        extracted_at,
        raw_id,
        rn = ROW_NUMBER() OVER (
            PARTITION BY sap_id_fiscal
            ORDER BY extracted_at DESC, raw_id DESC
        )
    FROM raw_normalized
    WHERE sap_id_fiscal IS NOT NULL
      AND sap_nombre IS NOT NULL
),
src AS (
    SELECT
        sap_id_fiscal,
        sap_nombre,
        telefono = CAST(NULL AS VARCHAR(20))
    FROM raw_valid
    WHERE rn = 1
)
MERGE [cfl].[CFL_chofer] AS t
USING src AS s
    ON t.sap_id_fiscal = s.sap_id_fiscal
WHEN MATCHED THEN
    UPDATE SET
        t.sap_nombre = s.sap_nombre,
        t.activo = 1
WHEN NOT MATCHED THEN
    INSERT (sap_id_fiscal, sap_nombre, telefono, activo)
    VALUES (s.sap_id_fiscal, s.sap_nombre, s.telefono, 1);

COMMIT TRANSACTION;
