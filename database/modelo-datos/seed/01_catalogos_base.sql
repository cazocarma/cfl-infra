/* ============================================================================
   SEED 01 - CATALOGOS BASE
   Rol: poblar tablas maestras base (temporadas, centros, cuentas, detalles,
        especies, tipos de flete y tipos de camion).
   Idempotente: SI (MERGE)
============================================================================ */
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;
DECLARE @now DATETIME2(0) = SYSDATETIME();

;WITH src(codigo, nombre, FechaInicio, FechaFin, activa, cerrada) AS (
  SELECT *
  FROM (VALUES
  (N'2025-2026', N'Temporada 2025-2026', N'2025-08-25 00:00:00', N'2026-08-24 23:59:59', 1, 0)
  ) v(codigo, nombre, FechaInicio, FechaFin, activa, cerrada)
)
MERGE cfl.Temporada AS t
USING src AS s
ON t.codigo = s.codigo
WHEN MATCHED THEN
  UPDATE SET
    t.nombre = s.nombre,
    t.FechaInicio = CAST(s.FechaInicio AS DATETIME2(0)),
    t.FechaFin = CAST(s.FechaFin AS DATETIME2(0)),
    t.activa = CAST(s.activa AS BIT),
    t.cerrada = CAST(s.cerrada AS BIT),
    t.FechaActualizacion = @now
WHEN NOT MATCHED THEN
  INSERT (codigo, nombre, FechaInicio, FechaFin, activa, cerrada, FechaCreacion, FechaActualizacion)
  VALUES (s.codigo, s.nombre, CAST(s.FechaInicio AS DATETIME2(0)), CAST(s.FechaFin AS DATETIME2(0)), CAST(s.activa AS BIT), CAST(s.cerrada AS BIT), @now, @now);

;WITH src(SapCodigo, nombre, activo) AS (
  SELECT *
  FROM (VALUES
    (N'GC2010103', N'Proceso Maipo', 1),
    (N'GC1070101', N'Bodega Maipo', 1),
    (N'GC2010701', N'Linea Produccion Mercado Interno', 1),
    (N'GC2010401', N'Maipo ATM', 1),
    (N'GC5020101', N'Programa Maipo', 1),
    (N'GC2030106', N'Proceso Placilla', 1),
    (N'GC1070201', N'Bodega Placilla', 1),
    (N'GC2030301', N'Placilla Usda/Sag', 1),
    (N'GC2030401', N'Linea Produccion Uva', 1),
    (N'GC2030601', N'Linea Produccion Mercado Interno', 1),
    (N'GC2040401', N'Organik ATM', 1),
    (N'GC2040301', N'Organik Usda/Sag', 1),
    (N'GC3020101', N'Exp-Com-Comex', 1),
    (N'GC5020201', N'Programa Placilla', 1),
    (N'GC2050104', N'Proceso Callaqui', 1),
    (N'GC1070301', N'Bodega Los Angeles', 1),
    (N'GC2050301', N'Los Angeles Usda/Sag', 1),
    (N'GC2050401', N'Los Angeles ATM', 1),
    (N'GC5020301', N'Programa Los Angeles', 1)
  ) v(SapCodigo, nombre, activo)
)
MERGE cfl.CentroCosto AS t
USING src AS s
ON t.SapCodigo = s.SapCodigo
WHEN MATCHED THEN
  UPDATE SET
    t.nombre = s.nombre,
    t.activo = CAST(s.activo AS BIT)
WHEN NOT MATCHED THEN
  INSERT (SapCodigo, nombre, activo)
  VALUES (s.SapCodigo, s.nombre, CAST(s.activo AS BIT));

;WITH src(codigo, glosa) AS (
  SELECT *
  FROM (VALUES
  (N'51020314', N'FLETES INTERPLANTA / FRUTA EXPORTACION'),
  (N'51020315', N'FLETES MATERIALES / TRANSPORTE EXPORTACION'),
  (N'51020316', N'FLETES MERCADO NACIONAL'),
  (N'51020317', N'FLETES ATMOSFERA CONTROLADA'),
  (N'51020318', N'FLETES MUESTRAS USDA')
  ) v(codigo, glosa)
)
MERGE cfl.CuentaMayor AS t
USING src AS s
ON t.codigo = s.codigo
WHEN MATCHED THEN
  UPDATE SET t.glosa = s.glosa
WHEN NOT MATCHED THEN
  INSERT (codigo, glosa)
  VALUES (s.codigo, s.glosa);

;WITH src(descripcion, Observacion, activo) AS (
  SELECT *
  FROM (VALUES
  (N'ALAMBRE AMARRA', NULL, 1),
  (N'ALAMBRE AMARRA/CAJAS FORTIL', NULL, 1),
  (N'ARNE', NULL, 1),
  (N'BINS A PROCESO', NULL, 1),
  (N'BINS A PROCESO-BINS DEVOL.', NULL, 1),
  (N'BINS COMERCIAL', NULL, 1),
  (N'BINS COMERCIAL EN DEVOLUCION', NULL, 1),
  (N'BINS CON DESECHO', NULL, 1),
  (N'BINS CON ESTACAS-PLANTAS', NULL, 1),
  (N'BINS COSECHEROS-CAJAS 3/4', NULL, 1),
  (N'BINS MADERA', NULL, 1),
  (N'BINS MADERA EN DEVOLUCION', NULL, 1),
  (N'BINS MADERA FRUTA AC', NULL, 1),
  (N'BINS MADERA FRUTA COMERCIAL', NULL, 1),
  (N'BINS MADERA FRUTA DESECHO', NULL, 1),
  (N'BINS MADERA FRUTA PROCESO', NULL, 1),
  (N'BINS MADERA VACIO', NULL, 1),
  (N'BINS PLASTICO', NULL, 1),
  (N'BINS PLASTICO EN DEVOLUCION', NULL, 1),
  (N'BINS PLASTICO FRUTA AC', NULL, 1),
  (N'BINS PLASTICO FRUTA COMERCIAL', NULL, 1),
  (N'BINS PLASTICO FRUTA PROCESO', NULL, 1),
  (N'BINS PLASTICO VACIO', NULL, 1),
  (N'CAJAS 3/4 CON ESTACAS-PLANTAS', NULL, 1),
  (N'CAJAS A PROCESO', NULL, 1),
  (N'CAJAS CAPACHO', NULL, 1),
  (N'CAJAS CAPACHO-BINS', NULL, 1),
  (N'CAJAS EMBALADAS', NULL, 1),
  (N'CAJAS EMBALADAS DE EXPORTACION', NULL, 1),
  (N'CAJAS JUGUETES', NULL, 1),
  (N'CAJAS MUESTRA USDA-SAG', NULL, 1),
  (N'CAJAS PLASTICAS 3/4', NULL, 1),
  (N'CAJAS PLASTICAS 3/4 VACIA', NULL, 1),
  (N'CAJAS PLASTICAS 3/4/ BINS', NULL, 1),
  (N'CAJAS PLASTICAS FRUTA COMERCIAL', NULL, 1),
  (N'CAJAS PLASTICAS FRUTA PROCESO', NULL, 1),
  (N'CAJAS PLASTICAS FRUTA SUPERMERCADO', NULL, 1),
  (N'CAJAS PLASTICAS SUPERMERCADO VACIA', NULL, 1),
  (N'CAJAS SUPERMERCADO', NULL, 1),
  (N'CAJAS SUPERMERCADO CON FRUTA', NULL, 1),
  (N'CAJAS SUPERMERCADO EN DEV.', NULL, 1),
  (N'CAÑERIAS', NULL, 1),
  (N'CAPACHOS', NULL, 1),
  (N'CARRO CALIBRE', NULL, 1),
  (N'CARRO MAQUINA CHOPER', NULL, 1),
  (N'CARRO TRANSPORTADOR DE BINS', NULL, 1),
  (N'CILINDROS AMONIACOS', NULL, 1),
  (N'CILINDROS AMONIACOS VACIOS', NULL, 1),
  (N'CONTENEDOR BODEGA MIXTA', NULL, 1),
  (N'DIFERENCIA TARIFA', NULL, 1),
  (N'ESPONJAS', NULL, 1),
  (N'ESTACAS DE VID', NULL, 1),
  (N'ESTACAS DE VID/BINS COSECHEROS', NULL, 1),
  (N'FLETE FALSO', NULL, 1),
  (N'GRUA HORQUILLA', NULL, 1),
  (N'HORMIGONES', NULL, 1),
  (N'KILOS DE ALAMBRE', NULL, 1),
  (N'KILOS DE FRUTA COMERCIAL', NULL, 1),
  (N'MADERA', NULL, 1),
  (N'MAQUINA CORTADORA DE PASTO', NULL, 1),
  (N'MAQUINARIA AGRICOLA', NULL, 1),
  (N'MAQUINARIA DE COSECHA', NULL, 1),
  (N'MATERIAL DE CONSTRUCCION', NULL, 1),
  (N'MATERIAL DE COSECHA', NULL, 1),
  (N'MATERIAL DE EMBALAJE', NULL, 1),
  (N'MATERIAL DE INJERTO', NULL, 1),
  (N'MATERIAL DE VIVERO', NULL, 1),
  (N'MATERIAL EMBALAJE', NULL, 1),
  (N'MATERIAL EN DESUSO', NULL, 1),
  (N'MOVILIZACION INTERNA', NULL, 1),
  (N'MOVILIZACION INTERNA BINS', NULL, 1),
  (N'MOVILIZACION INTERNA MATERIAL', NULL, 1),
  (N'MTS.3 DE ASERRIN DE ALAMO', NULL, 1),
  (N'MTS.3 DE COMPOST', NULL, 1),
  (N'NEBULIZADORES', NULL, 1),
  (N'PALLETS', NULL, 1),
  (N'PALLETS FRUTA EMBALADA', NULL, 1),
  (N'PLANTAS', NULL, 1),
  (N'POSTES IMPREGNADOS', NULL, 1),
  (N'PULVERIZADORA', NULL, 1),
  (N'REGLAMENTO INTERNO', NULL, 1),
  (N'RESIDUOS SOLIDOS', NULL, 1),
  (N'RETROEXCAVADORA', NULL, 1),
  (N'REVOLVEDORA DE COMPOST', NULL, 1),
  (N'TAMBORES PROTEINA SOLUBLE', NULL, 1),
  (N'TINAS DE POLISULFURO', NULL, 1),
  (N'TRASLADO DE RASTRA', NULL, 1),
  (N'TRASLADO DE TRACTOR', NULL, 1),
  (N'TRASLADO LINEA DE UVA', NULL, 1),
  (N'TRASLADO PORTON METALICO', NULL, 1),
  (N'TURBA SUNSHINEE', NULL, 1),
  (N'VIAJE DESECHO', NULL, 1)
  ) v(descripcion, Observacion, activo)
)
MERGE cfl.DetalleViaje AS t
USING src AS s
ON t.descripcion = s.descripcion
WHEN MATCHED THEN
  UPDATE SET
    t.Observacion = s.Observacion,
    t.activo = CAST(s.activo AS BIT)
WHEN NOT MATCHED THEN
  INSERT (descripcion, Observacion, activo)
  VALUES (s.descripcion, s.Observacion, CAST(s.activo AS BIT));

;WITH src(glosa) AS (
  SELECT *
  FROM (VALUES
  (N'APIO FRANCIA'),
  (N'ARANDANO'),
  (N'CEREZA'),
  (N'CIRUELA'),
  (N'CIRUELA EUROPEA'),
  (N'CLEMENTINA'),
  (N'DAMASCO'),
  (N'DURAZNO'),
  (N'GRANADA'),
  (N'HAKUSAI'),
  (N'KIWI'),
  (N'LIMON'),
  (N'MANDARINA'),
  (N'MANZANA'),
  (N'MAQUI BERRIES DESHID'),
  (N'NARANJA'),
  (N'NECTARIN'),
  (N'NUEZ SECA C/CASCARA'),
  (N'NUEZ SECA S/CASCARA'),
  (N'NUEZ VERDE'),
  (N'PALTA'),
  (N'PERA ASIATICA'),
  (N'PERA EUROPEA'),
  (N'PLUMCOT'),
  (N'UVA')
  ) v(glosa)
)
MERGE cfl.Especie AS t
USING src AS s
ON t.glosa = s.glosa
WHEN NOT MATCHED THEN
  INSERT (glosa)
  VALUES (s.glosa);

;WITH src(SapCodigo, Nombre, Activo) AS (
  SELECT *
  FROM (VALUES
  (N'0001', N'TRASLADO DE FRUTA', 1),
  (N'0002', N'TRASLADO DE MATERIALES', 1),
  (N'0003', N'TRASLADO PUERTO - AEROPUERTO', 0),
  (N'0004', N'TRASLADO INTERPLANTA', 1),
  (N'0005', N'TRASLADO MERCADO NACIONAL', 1),
  (N'0006', N'TRASLADO MUESTRA USDA', 1)
  ) v(SapCodigo, Nombre, Activo)
)
MERGE cfl.TipoFlete AS t
USING src AS s
ON t.SapCodigo = s.SapCodigo
WHEN MATCHED THEN
  UPDATE SET
    t.Nombre = s.Nombre,
    t.Activo = CAST(s.Activo AS BIT)
WHEN NOT MATCHED THEN
  INSERT (SapCodigo, Nombre, Activo)
  VALUES (s.SapCodigo, s.Nombre, CAST(s.Activo AS BIT));

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
),
resolved AS (
  SELECT
    tf.IdTipoFlete,
    cc.IdCentroCosto,
    cm.IdCuentaMayor,
    s.Activo
  FROM src s
  INNER JOIN cfl.TipoFlete tf
    ON tf.SapCodigo = s.TipoSapCodigo
  INNER JOIN cfl.CentroCosto cc
    ON cc.SapCodigo = s.CentroSapCodigo
  INNER JOIN cfl.CuentaMayor cm
    ON cm.Codigo = s.CuentaCodigo
)
MERGE cfl.ImputacionFlete AS t
USING resolved AS s
ON t.IdTipoFlete = s.IdTipoFlete
 AND t.IdCentroCosto = s.IdCentroCosto
 AND t.IdCuentaMayor = s.IdCuentaMayor
WHEN MATCHED THEN
  UPDATE SET
    t.Activo = CAST(s.Activo AS BIT),
    t.FechaActualizacion = @now
WHEN NOT MATCHED THEN
  INSERT (
    IdTipoFlete,
    IdCentroCosto,
    IdCuentaMayor,
    Activo,
    FechaCreacion,
    FechaActualizacion
  )
  VALUES (
    s.IdTipoFlete,
    s.IdCentroCosto,
    s.IdCuentaMayor,
    CAST(s.Activo AS BIT),
    @now,
    @now
  );

;WITH src(nombre, categoria, CapacidadKg, RequiereTemperatura, descripcion, activo) AS (
  SELECT *
  FROM (VALUES
  (N'PLANO SOLO', N'PLANO', 24000, 0, NULL, 1),
  (N'PLANO SOLO (PLANTA)', N'PLANO', 24000, 0, NULL, 1),
  (N'PLANO 3/4', N'PLANO', 5000, 0, NULL, 1),
  (N'PLANO CON CARRO', N'PLANO', 32000, 0, NULL, 1),
  (N'TERMO CHICO', N'TERMO', 9000, 1, NULL, 1),
  (N'TERMO GRANDE', N'TERMO', 24000, 1, NULL, 1),
  (N'TERMO MEDIANO', N'TERMO', 18000, 1, NULL, 1),
  (N'CAMIONETA', N'OTRO', 1500, 0, NULL, 1),
  (N'PARTICULAR', N'OTRO', 800, 0, NULL, 1),
  (N'TOLVA', N'OTRO', 20000, 0, NULL, 1)
  ) v(nombre, categoria, CapacidadKg, RequiereTemperatura, descripcion, activo)
)
MERGE cfl.TipoCamion AS t
USING src AS s
ON t.nombre = s.nombre
WHEN MATCHED THEN
  UPDATE SET
    t.categoria = s.categoria,
    t.CapacidadKg = CAST(s.CapacidadKg AS DECIMAL(15,3)),
    t.RequiereTemperatura = CAST(s.RequiereTemperatura AS BIT),
    t.descripcion = s.descripcion,
    t.activo = CAST(s.activo AS BIT)
WHEN NOT MATCHED THEN
  INSERT (nombre, categoria, CapacidadKg, RequiereTemperatura, descripcion, activo)
  VALUES (s.nombre, s.categoria, CAST(s.CapacidadKg AS DECIMAL(15,3)), CAST(s.RequiereTemperatura AS BIT), s.descripcion, CAST(s.activo AS BIT));

COMMIT TRANSACTION;
