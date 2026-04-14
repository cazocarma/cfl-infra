/* ============================================================================
   FIX: Romana Cabecera Raw — fechas con día y mes intercambiados

   Contexto:
     El cliente ETL de Romana (romana-etl-client.js) leía `Erdat`/`Aedat`
     desde SAP como strings "DD-MM-YYYY" y los entregaba directo a sql.Date.
     El driver (vía `new Date(...)`) los interpretaba como MM-DD-YYYY,
     persistiendo las fechas con día y mes swapeados en BD.

     Ejemplo: SAP envía "09-02-2026" (9 feb) → BD queda con "2026-09-02"
     (2 de septiembre).

   Alcance de este script:
     Corrige filas en `[cfl].[RomanaCabeceraRaw]` donde día y mes son ambos
     ≤ 12 (swap reversible). NO toca filas con día > 12, porque ésas no
     pudieron haber sido swapeadas (si el día original fuera > 12, new Date
     habría devuelto Invalid Date y el insert habría fallado — no están en BD).

   Idempotente: SI (solo cambia filas que cumplen el patrón de swap).
============================================================================ */
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

-- FechaCreacionSap
UPDATE [cfl].[RomanaCabeceraRaw]
SET FechaCreacionSap = DATEFROMPARTS(
  YEAR(FechaCreacionSap),
  DAY(FechaCreacionSap),   -- antes estaba como MES
  MONTH(FechaCreacionSap)  -- antes estaba como DÍA
)
WHERE FechaCreacionSap IS NOT NULL
  AND DAY(FechaCreacionSap)   BETWEEN 1 AND 12
  AND MONTH(FechaCreacionSap) BETWEEN 1 AND 12;

-- FechaModificacionSap
UPDATE [cfl].[RomanaCabeceraRaw]
SET FechaModificacionSap = DATEFROMPARTS(
  YEAR(FechaModificacionSap),
  DAY(FechaModificacionSap),
  MONTH(FechaModificacionSap)
)
WHERE FechaModificacionSap IS NOT NULL
  AND DAY(FechaModificacionSap)   BETWEEN 1 AND 12
  AND MONTH(FechaModificacionSap) BETWEEN 1 AND 12;

COMMIT;

/* NOTA: las filas donde el día original era > 12 quedaron bien (el driver
   habría devuelto Invalid Date y el INSERT habría fallado). Por eso no se
   tocan. Si en el futuro aparecen fechas dudosas, revisar logs de ingesta
   junto a estas tablas. */
