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

;WITH src(codigo, nombre, fecha_inicio, fecha_fin, activa, cerrada) AS (
  SELECT *
  FROM (VALUES
  (N'2025-2026', N'Temporada 2025-2026', N'2025-08-25 00:00:00', N'2026-08-24 23:59:59', 1, 0)
  ) v(codigo, nombre, fecha_inicio, fecha_fin, activa, cerrada)
)
MERGE cfl.CFL_temporada AS t
USING src AS s
ON t.codigo = s.codigo
WHEN MATCHED THEN
  UPDATE SET
    t.nombre = s.nombre,
    t.fecha_inicio = CAST(s.fecha_inicio AS DATETIME2(0)),
    t.fecha_fin = CAST(s.fecha_fin AS DATETIME2(0)),
    t.activa = CAST(s.activa AS BIT),
    t.cerrada = CAST(s.cerrada AS BIT),
    t.updated_at = @now
WHEN NOT MATCHED THEN
  INSERT (codigo, nombre, fecha_inicio, fecha_fin, activa, cerrada, created_at, updated_at)
  VALUES (s.codigo, s.nombre, CAST(s.fecha_inicio AS DATETIME2(0)), CAST(s.fecha_fin AS DATETIME2(0)), CAST(s.activa AS BIT), CAST(s.cerrada AS BIT), @now, @now);

;WITH src(sap_codigo, nombre, activo) AS (
  SELECT *
  FROM (VALUES
  (N'GC2010101', N'Gerencia Operaciones | Plta Maipo', 1),
  (N'GC2010102', N'Gerencia Operaciones | Plta Maipo', 1),
  (N'GC2010103', N'Gerencia Operaciones | Plta Maipo', 1),
  (N'GC2010104', N'Gerencia Operaciones | Plta Maipo', 1),
  (N'GC2010201', N'Gerencia Operaciones | Plta Maipo', 1),
  (N'GC2010301', N'Gerencia Operaciones | Plta Maipo', 1),
  (N'GC2010401', N'Gerencia Operaciones | Plta Maipo', 1),
  (N'GC2010501', N'Gerencia Operaciones | Plta Maipo', 1),
  (N'GC2010502', N'Gerencia Operaciones | Plta Maipo', 1),
  (N'GC2010601', N'Gerencia Operaciones | Plta Maipo', 1),
  (N'GC2010701', N'Gerencia Operaciones | Plta Maipo', 1),
  (N'GC2010801', N'Gerencia Operaciones | Plta Maipo', 1),
  (N'GC2010802', N'Gerencia Operaciones | Plta Maipo', 1),
  (N'GC2010803', N'Gerencia Operaciones | Plta Maipo', 1),
  (N'GC2010804', N'Gerencia Operaciones | Plta Maipo', 1),
  (N'GC2020101', N'Gerencia Operaciones | Plta FSD', 1),
  (N'GC2020301', N'Gerencia Operaciones | Plta FSD', 1),
  (N'GC2020302', N'Gerencia Operaciones | Plta FSD', 1),
  (N'GC2020303', N'Gerencia Operaciones | Plta FSD', 1),
  (N'GC2020304', N'Gerencia Operaciones | Plta FSD', 1),
  (N'GC2020305', N'Gerencia Operaciones | Plta FSD', 1),
  (N'GC2020306', N'Gerencia Operaciones | Plta FSD', 1),
  (N'GC2020307', N'Gerencia Operaciones | Plta FSD', 1),
  (N'GC2020308', N'Gerencia Operaciones | Plta FSD', 1),
  (N'GC2020401', N'Gerencia Operaciones | Plta FSD', 1),
  (N'GC2020501', N'Gerencia Operaciones | Plta FSD', 1),
  (N'GC2020502', N'Gerencia Operaciones | Plta FSD', 1),
  (N'GC2030101', N'Gerencia Operaciones | Plta Placill', 1),
  (N'GC2030102', N'Gerencia Operaciones | Plta Placill', 1),
  (N'GC2030103', N'Gerencia Operaciones | Plta Placill', 1),
  (N'GC2030104', N'Gerencia Operaciones | Plta Placill', 1),
  (N'GC2030105', N'Gerencia Operaciones | Plta Placill', 1),
  (N'GC2030106', N'Gerencia Operaciones | Plta Placill', 1),
  (N'GC2030107', N'Gerencia Operaciones | Plta Placill', 1),
  (N'GC2030108', N'Gerencia Operaciones | Plta Placill', 1),
  (N'GC2030201', N'Gerencia Operaciones | Plta Placill', 1),
  (N'GC2030301', N'Gerencia Operaciones | Plta Placill', 1),
  (N'GC2030401', N'Gerencia Operaciones | Plta Placill', 1),
  (N'GC2030501', N'Gerencia Operaciones | Plta Placill', 1),
  (N'GC2030601', N'Gerencia Operaciones | Plta Placill', 1),
  (N'GC2030701', N'Gerencia Operaciones | Plta Placill', 1),
  (N'GC2030702', N'Gerencia Operaciones | Plta Placill', 1),
  (N'GC2030703', N'Gerencia Operaciones | Plta Placill', 1),
  (N'GC2040101', N'Gerencia Operaciones | Plta Organic', 1),
  (N'GC2040201', N'Gerencia Operaciones | Plta Organic', 1),
  (N'GC2040301', N'Gerencia Operaciones | Plta Organic', 1),
  (N'GC2040401', N'Gerencia Operaciones | Plta Organic', 1),
  (N'GC2040501', N'Gerencia Operaciones | Plta Organik', 1),
  (N'GC2040502', N'Gerencia Operaciones | Plta Organik', 1),
  (N'GC2040503', N'Gerencia Operaciones | Plta Organik', 1),
  (N'GC2050101', N'Gerencia Operaciones | Plta LA', 1),
  (N'GC2050102', N'Gerencia Operaciones | Plta LA', 1),
  (N'GC2050103', N'Gerencia Operaciones | Plta LA', 1),
  (N'GC2050104', N'Gerencia Operaciones | Plta LA', 1),
  (N'GC2050105', N'Gerencia Operaciones | Plta LA', 1),
  (N'GC2050106', N'Gerencia Operaciones | Plta LA', 1),
  (N'GC2050201', N'Gerencia Operaciones | Plta LA', 1),
  (N'GC2050301', N'Gerencia Operaciones | Plta LA', 1),
  (N'GC2050401', N'Gerencia Operaciones | Plta LA', 1),
  (N'GC2050450', N'Gerencia Operaciones | Plta LA', 1),
  (N'GC2050501', N'Gerencia Operaciones | Plta LA', 1),
  (N'GC2050502', N'Gerencia Operaciones | Plta LA', 1),
  (N'GC2050503', N'Gerencia Operaciones | Plta LA', 1),
  (N'GC2050601', N'Gerencia Operaciones | Plta LA', 1),
  (N'GC2060101', N'Gerencia Operaciones | Mat Cosecha', 1),
  (N'GC2060201', N'Gerencia Operaciones | Mat Cosecha', 1),
  (N'GC2060301', N'Gerencia Operaciones | Mat Cosecha', 1),
  (N'GC2070101', N'Gerencia Operaciones | Bodega', 1),
  (N'GC2070201', N'Gerencia Operaciones | Bodega', 1),
  (N'GC2070301', N'Gerencia Operaciones | Bodega', 1),
  (N'GC3020101', N'Gerencia Comercial | Transporte', 1),
  (N'GC6010101', N'Gerencia Agricola | Campo', 1),
  (N'GC6010102', N'Gerencia Agricola | Campo', 1),
  (N'GC6010103', N'Gerencia Agricola | Campo', 1),
  (N'GC6010104', N'Gerencia Agricola | Campo', 1),
  (N'GC6010105', N'Gerencia Agricola | Campo', 1),
  (N'GC6010201', N'Gerencia Agricola | Campo', 1),
  (N'GC7020101', N'Gerencia Operaciones | Plta Maipo', 1),
  (N'GC7030101', N'Gerencia Operaciones | Plta Placill', 1),
  (N'GC7040101', N'Gerencia Operaciones | Plta LA', 1),
  (N'POR DEFINIR', N'POR DEFINIR', 1)
  ) v(sap_codigo, nombre, activo)
)
MERGE cfl.CFL_centro_costo AS t
USING src AS s
ON t.sap_codigo = s.sap_codigo
WHEN MATCHED THEN
  UPDATE SET
    t.nombre = s.nombre,
    t.activo = CAST(s.activo AS BIT)
WHEN NOT MATCHED THEN
  INSERT (sap_codigo, nombre, activo)
  VALUES (s.sap_codigo, s.nombre, CAST(s.activo AS BIT));

;WITH src(codigo, glosa) AS (
  SELECT *
  FROM (VALUES
  (N'51020314', N''),
  (N'51020315', N''),
  (N'51020316', N''),
  (N'51020317', N''),
  (N'51020318', N''),
  (N'51020502', N''),
  (N'61010221', N'')
  ) v(codigo, glosa)
)
MERGE cfl.CFL_cuenta_mayor AS t
USING src AS s
ON t.codigo = s.codigo
WHEN MATCHED THEN
  UPDATE SET t.glosa = s.glosa
WHEN NOT MATCHED THEN
  INSERT (codigo, glosa)
  VALUES (s.codigo, s.glosa);

;WITH src(descripcion, observacion, activo) AS (
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
  ) v(descripcion, observacion, activo)
)
MERGE cfl.CFL_detalle_viaje AS t
USING src AS s
ON t.descripcion = s.descripcion
WHEN MATCHED THEN
  UPDATE SET
    t.observacion = s.observacion,
    t.activo = CAST(s.activo AS BIT)
WHEN NOT MATCHED THEN
  INSERT (descripcion, observacion, activo)
  VALUES (s.descripcion, s.observacion, CAST(s.activo AS BIT));

;WITH src(glosa) AS (
  SELECT *
  FROM (VALUES
  (N'APIO FRANCIA'),
  (N'ARANDANO'),
  (N'CEREZA'),
  (N'CIRUELA'),
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
MERGE cfl.CFL_especie AS t
USING src AS s
ON t.glosa = s.glosa
WHEN NOT MATCHED THEN
  INSERT (glosa)
  VALUES (s.glosa);

;WITH src(sap_codigo, nombre, activo, centro_sap_codigo) AS (
  SELECT *
  FROM (VALUES
  (N'0001', N'TRASLADO DE FRUTA', 1, N'POR DEFINIR'),
  (N'0002', N'TRASLADO DE MATERIALES', 1, N'POR DEFINIR'),
  (N'0003', N'TRASLADO PUERTO - AEROPUERTO', 1, N'POR DEFINIR'),
  (N'0004', N'TRASLADO INTERPLANTA', 1, N'POR DEFINIR'),
  (N'0005', N'TRASLADO MERCADO NACIONAL', 1, N'POR DEFINIR'),
  (N'0006', N'TRASLADO MUESTRA USDA', 1, N'POR DEFINIR')
  ) v(sap_codigo, nombre, activo, centro_sap_codigo)
), resolved AS (
  SELECT
    s.sap_codigo,
    s.nombre,
    s.activo,
    cc.id_centro_costo
  FROM src s
  INNER JOIN cfl.CFL_centro_costo cc ON cc.sap_codigo = s.centro_sap_codigo
)
MERGE cfl.CFL_tipo_flete AS t
USING resolved AS s
ON t.sap_codigo = s.sap_codigo
WHEN MATCHED THEN
  UPDATE SET
    t.nombre = s.nombre,
    t.activo = CAST(s.activo AS BIT),
    t.id_centro_costo = s.id_centro_costo
WHEN NOT MATCHED THEN
  INSERT (sap_codigo, nombre, activo, id_centro_costo)
  VALUES (s.sap_codigo, s.nombre, CAST(s.activo AS BIT), s.id_centro_costo);

;WITH src(nombre, categoria, capacidad_kg, requiere_temperatura, descripcion, activo) AS (
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
  ) v(nombre, categoria, capacidad_kg, requiere_temperatura, descripcion, activo)
)
MERGE cfl.CFL_tipo_camion AS t
USING src AS s
ON t.nombre = s.nombre
WHEN MATCHED THEN
  UPDATE SET
    t.categoria = s.categoria,
    t.capacidad_kg = CAST(s.capacidad_kg AS DECIMAL(15,3)),
    t.requiere_temperatura = CAST(s.requiere_temperatura AS BIT),
    t.descripcion = s.descripcion,
    t.activo = CAST(s.activo AS BIT)
WHEN NOT MATCHED THEN
  INSERT (nombre, categoria, capacidad_kg, requiere_temperatura, descripcion, activo)
  VALUES (s.nombre, s.categoria, CAST(s.capacidad_kg AS DECIMAL(15,3)), CAST(s.requiere_temperatura AS BIT), s.descripcion, CAST(s.activo AS BIT));

COMMIT TRANSACTION;
