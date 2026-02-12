/* ============================================================
   CFL – SEED FINAL (EXPANDIDO) + ÍNDICES DE CATÁLOGO
   - Idempotente (MERGE / INSERT WHERE NOT EXISTS).
   - Carga: Detalle Viaje, Temporada, Tipos Camión, Especies,
            Nodo Logístico (COMPLETO), Rutas (desde tarifas),
            Tipos de Flete, Roles/Usuarios, Choferes, Empresas,
            Camiones de prueba, Tarifas (PLANO y TERMOS).
   - Moneda: CLP, Regla: BASE, Prioridad: 1
   - Temporada: 2025-2026 (25-08-2025 a 24-08-2026)
   ============================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRAN;

DECLARE @now datetime2(0) = SYSDATETIME();

/* ============================================================
   0) ÍNDICES (cuando corresponde / catálogos)
   - OJO: No creo UNIQUE en Nodo_Logistico.nombre porque tu lista
     trae duplicados (ej. SANTO DOMINGO, SAN CARLOS ÑUBLE, etc.)
   ============================================================ */
IF NOT EXISTS (
  SELECT 1 FROM sys.indexes
  WHERE name = 'IX_detalle_viaje_descripcion' AND object_id = OBJECT_ID('cfl.CFL_detalle_viaje')
)
BEGIN
  CREATE INDEX IX_detalle_viaje_descripcion ON cfl.CFL_detalle_viaje(descripcion);
END;

IF NOT EXISTS (
  SELECT 1 FROM sys.indexes
  WHERE name = 'IX_tipo_camion_nombre' AND object_id = OBJECT_ID('cfl.CFL_tipo_camion')
)
BEGIN
  CREATE INDEX IX_tipo_camion_nombre ON cfl.CFL_tipo_camion(nombre);
END;

IF NOT EXISTS (
  SELECT 1 FROM sys.indexes
  WHERE name = 'IX_nodo_logistico_nombre' AND object_id = OBJECT_ID('cfl.CFL_nodo_logistico')
)
BEGIN
  CREATE INDEX IX_nodo_logistico_nombre ON cfl.CFL_nodo_logistico(nombre);
END;

IF NOT EXISTS (
  SELECT 1 FROM sys.indexes
  WHERE name = 'IX_empresa_transporte_razon_social' AND object_id = OBJECT_ID('cfl.CFL_empresa_transporte')
)
BEGIN
  CREATE INDEX IX_empresa_transporte_razon_social ON cfl.CFL_empresa_transporte(razon_social);
END;

IF NOT EXISTS (
  SELECT 1 FROM sys.indexes
  WHERE name = 'IX_chofer_nombre' AND object_id = OBJECT_ID('cfl.CFL_chofer')
)
BEGIN
  CREATE INDEX IX_chofer_nombre ON cfl.CFL_chofer(sap_nombre);
END;

/* ============================================================
   1) CFL_detalle_viaje
   ============================================================ */
;WITH src AS (
    SELECT v.codigo, v.descripcion
    FROM (VALUES
      (0,  N'.'),
      (1,  N'BINS PLASTICO'),
      (2,  N'BINS MADERA'),
      (3,  N'MATERIAL EMBALAJE'),
      (4,  N'CAJAS A PROCESO'),
      (5,  N'BINS A PROCESO'),
      (6,  N'CAJAS EMBALADAS'),
      (7,  N'VIAJE DESECHO'),
      (8,  N'PLANTAS'),
      (9,  N'BINS MADERA EN DEVOLUCION'),
      (10, N'BINS PLASTICO EN DEVOLUCION'),
      (11, N'BINS COMERCIAL EN DEVOLUCION'),
      (12, N'TRASLADO DE TRACTOR'),
      (13, N'KILOS DE FRUTA COMERCIAL'),
      (14, N'CAJAS CAPACHO'),
      (15, N'MTS.3 DE COMPOST'),
      (16, N'MTS.3 DE ASERRIN DE ALAMO'),
      (17, N'MATERIAL EN DESUSO'),
      (18, N'BINS COMERCIAL'),
      (19, N'CAJAS SUPERMERCADO'),
      (20, N'CAJAS SUPERMERCADO CON FRUTA'),
      (21, N'CAJAS SUPERMERCADO EN DEV.'),
      (22, N'CAJAS PLASTICAS 3/4'),
      (23, N'TRASLADO LINEA DE UVA'),
      (24, N'MATERIAL DE COSECHA'),
      (25, N'ARNE'),
      (26, N'MOVILIZACION INTERNA'),
      (27, N'TINAS DE POLISULFURO'),
      (28, N'PULVERIZADORA'),
      (29, N'TRASLADO PORTON METALICO'),
      (30, N'CAÑERIAS'),
      (31, N'CARRO TRANSPORTADOR DE BINS'),
      (32, N'NEBULIZADORES'),
      (33, N'MATERIAL DE INJERTO'),
      (34, N'GRUA HORQUILLA'),
      (35, N'REVOLVEDORA DE COMPOST'),
      (36, N'CARRO MAQUINA CHOPER'),
      (37, N'CAJAS 3/4 CON ESTACAS-PLANTAS'),
      (38, N'BINS CON ESTACAS-PLANTAS'),
      (39, N'TAMBORES PROTEINA SOLUBLE'),
      (40, N'MAQUINARIA DE COSECHA'),
      (41, N'RETROEXCAVADORA'),
      (42, N'MAQUINA CORTADORA DE PASTO'),
      (43, N'BINS CON DESECHO'),
      (44, N'POSTES IMPREGNADOS'),
      (45, N'HORMIGONES'),
      (46, N'CARRO CALIBRE'),
      (47, N'KILOS DE ALAMBRE'),
      (48, N'CONTENEDOR BODEGA MIXTA'),
      (49, N'PALLETS'),
      (50, N'REGLAMENTO INTERNO'),
      (51, N'PALLETS FRUTA EMBALADA'),
      (52, N'CAJAS MUESTRA USDA-SAG'),
      (53, N'CAJAS CAPACHO-BINS'),
      (54, N'BINS COSECHEROS-CAJAS 3/4'),
      (55, N'BINS A PROCESO-BINS DEVOL.'),
      (56, N'CILINDROS AMONIACOS'),
      (57, N'CILINDROS AMONIACOS VACIOS'),
      (58, N'MADERA'),
      (59, N'ALAMBRE AMARRA/CAJAS FORTIL'),
      (60, N'ALAMBRE AMARRA'),
      (61, N'MATERIAL DE VIVERO'),
      (62, N'CAJAS PLASTICAS 3/4/ BINS'),
      (63, N'RESIDUOS SOLIDOS'),
      (64, N'ESTACAS DE VID'),
      (65, N'ESTACAS DE VID/BINS COSECHEROS'),
      (66, N'TRASLADO DE RASTRA'),
      (67, N'TURBA SUNSHINEE'),
      (68, N'CAJAS JUGUETES'),
      (69, N'ESPONJAS'),
      (200, N'BINS PLASTICO VACIO'),
      (201, N'BINS PLASTICO FRUTA PROCESO'),
      (202, N'BINS PLASTICO FRUTA COMERCIAL'),
      (203, N'BINS PLASTICO FRUTA AC'),
      (204, N'BINS MADERA VACIO'),
      (205, N'BINS MADERA FRUTA PROCESO'),
      (206, N'BINS MADERA FRUTA COMERCIAL'),
      (207, N'BINS MADERA FRUTA DESECHO'),
      (208, N'BINS MADERA FRUTA AC'),
      (209, N'CAJAS PLASTICAS 3/4 VACIA'),
      (210, N'CAJAS PLASTICAS SUPERMERCADO VACIA'),
      (211, N'CAJAS PLASTICAS FRUTA PROCESO'),
      (212, N'CAJAS PLASTICAS FRUTA SUPERMERCADO'),
      (213, N'MATERIAL DE EMBALAJE'),
      (214, N'MATERIAL DE COSECHA'),
      (215, N'MATERIAL DE CONSTRUCCION'),
      (216, N'MAQUINARIA AGRICOLA'),
      (217, N'MOVILIZACION INTERNA MATERIAL'),
      (218, N'MOVILIZACION INTERNA BINS'),
      (219, N'CAJAS EMBALADAS DE EXPORTACION'),
      (220, N'CAJAS MUESTRA USDA-SAG'),
      (221, N'FLETE FALSO'),
      (222, N'CAPACHOS'),
      (223, N'DIFERENCIA TARIFA'),
      (224, N'CAJAS PLASTICAS FRUTA COMERCIAL')
    ) v(codigo, descripcion)
)
MERGE cfl.CFL_detalle_viaje AS t
USING src AS s
ON t.descripcion = s.descripcion
WHEN MATCHED THEN
  UPDATE SET t.activo = 1
WHEN NOT MATCHED THEN
  INSERT (descripcion, observacion, activo)
  VALUES (s.descripcion, NULL, 1);

/* ============================================================
   2) CFL_temporada
   ============================================================ */
MERGE cfl.CFL_temporada AS t
USING (SELECT
          '2025-2026' AS codigo,
          'Temporada 2025-2026' AS nombre,
          CAST('2025-08-25T00:00:00' AS datetime2(0)) AS fecha_inicio,
          CAST('2026-08-24T23:59:59' AS datetime2(0)) AS fecha_fin
      ) s
ON t.codigo = s.codigo
WHEN MATCHED THEN
  UPDATE SET
    t.nombre = s.nombre,
    t.fecha_inicio = s.fecha_inicio,
    t.fecha_fin = s.fecha_fin,
    t.updated_at = @now
WHEN NOT MATCHED THEN
  INSERT (codigo, nombre, fecha_inicio, fecha_fin, activa, cerrada, created_at, updated_at)
  VALUES (s.codigo, s.nombre, s.fecha_inicio, s.fecha_fin, 1, 0, @now, @now);

DECLARE @id_temporada bigint = (SELECT id_temporada FROM cfl.CFL_temporada WHERE codigo='2025-2026');

/* ============================================================
   3) CFL_tipo_camion
   ============================================================ */
;WITH src AS (
    SELECT nombre, categoria, capacidad_kg, requiere_temperatura, descripcion, activo
    FROM (VALUES
      ('PLANO SOLO',          'PLANO', 24000.000, 0, NULL, 1),
      ('PLANO CON CARRO',     'PLANO', 32000.000, 0, NULL, 1),
      ('TERMO GRANDE',        'TERMO', 24000.000, 1, NULL, 1),
      ('TERMO MEDIANO',       'TERMO', 18000.000, 1, NULL, 1),
      ('TERMO CHICO',         'TERMO',  9000.000, 1, NULL, 1),
      ('CAMIONETA',           'OTRO',   1500.000, 0, NULL, 1),
      ('PARTICULAR',          'OTRO',    800.000, 0, NULL, 1),
      ('PLANO SOLO (PLANTA)', 'PLANO', 24000.000, 0, NULL, 1),
      ('PLANO 3/4',           'PLANO',  5000.000, 0, NULL, 1),
      ('TOLVA',               'OTRO',  20000.000, 0, NULL, 1)
    ) v(nombre, categoria, capacidad_kg, requiere_temperatura, descripcion, activo)
)
MERGE cfl.CFL_tipo_camion AS t
USING src AS s
ON t.nombre = s.nombre
WHEN MATCHED THEN
  UPDATE SET
    t.categoria = s.categoria,
    t.capacidad_kg = s.capacidad_kg,
    t.requiere_temperatura = s.requiere_temperatura,
    t.descripcion = s.descripcion,
    t.activo = s.activo
WHEN NOT MATCHED THEN
  INSERT (nombre, categoria, capacidad_kg, requiere_temperatura, descripcion, activo)
  VALUES (s.nombre, s.categoria, s.capacidad_kg, s.requiere_temperatura, s.descripcion, s.activo);

DECLARE @id_tc_plano_solo bigint   = (SELECT id_tipo_camion FROM cfl.CFL_tipo_camion WHERE nombre='PLANO SOLO');
DECLARE @id_tc_plano_carro bigint  = (SELECT id_tipo_camion FROM cfl.CFL_tipo_camion WHERE nombre='PLANO CON CARRO');
DECLARE @id_tc_termo_chico bigint  = (SELECT id_tipo_camion FROM cfl.CFL_tipo_camion WHERE nombre='TERMO CHICO');
DECLARE @id_tc_termo_mediano bigint= (SELECT id_tipo_camion FROM cfl.CFL_tipo_camion WHERE nombre='TERMO MEDIANO');
DECLARE @id_tc_termo_grande bigint = (SELECT id_tipo_camion FROM cfl.CFL_tipo_camion WHERE nombre='TERMO GRANDE');

/* ============================================================
   4) CFL_especie (solo glosa según tu modelo)
   ============================================================ */
;WITH src AS (
    SELECT glosa
    FROM (VALUES
      ('LIMON'),('PALTA'),('NECTARIN'),('DURAZNO'),('CIRUELA'),('UVA'),
      ('PERA ASIATICA'),('KIWI'),('CEREZA'),('PERA EUROPEA'),('MANZANA'),
      ('DAMASCO'),('MANDARINA'),('ARANDANO'),('NARANJA'),('PLUMCOT'),
      ('CLEMENTINA'),('MAQUI BERRIES DESHID'),('HAKUSAI'),
      ('NUEZ VERDE'),('NUEZ SECA C/CASCARA'),('NUEZ SECA S/CASCARA'),
      ('APIO FRANCIA'),('GRANADA')
    ) v(glosa)
)
MERGE cfl.CFL_especie AS t
USING src AS s
ON t.glosa = s.glosa
WHEN NOT MATCHED THEN
  INSERT (glosa) VALUES (s.glosa);

/* ============================================================
   5) CFL_nodo_logistico (LISTA COMPLETA)
   - Se insertan DISTINCT por nombre para evitar duplicados.
   - Campos de dirección quedan POR DEFINIR (tu input solo trae glosa).
   ============================================================ */
;WITH raw_list AS (
  SELECT v.nombre
  FROM (VALUES
    (N'GLOSA.'),
    (N'PLANTA MAIPO'),
    (N'PLANTA PLACILLA'),
    (N'PLANTA PAINE'),
    (N'PLANTA SAN LUIS'),
    (N'PLANTA CONFEL'),
    (N'PLANTA GRIFFIN'),
    (N'BUIN'),
    (N'AGUA BUENA'),
    (N'ANGOSTURA'),
    (N'ANGOL'),
    (N'PAINE'),
    (N'PARRAL'),
    (N'CALERA DE TANGO'),
    (N'CASABLANCA'),
    (N'CAUQUENES'),
    (N'CHEPICA'),
    (N'CHILLAN'),
    (N'CHIMBARONGO'),
    (N'CODEGUA'),
    (N'COLINA'),
    (N'COLTAUCO'),
    (N'CUMPEO'),
    (N'CUNACO'),
    (N'CURICO'),
    (N'DOÑIHUE'),
    (N'EL CARMEN'),
    (N'EL MANZANO'),
    (N'EL TAMBO'),
    (N'GRANEROS'),
    (N'HALCONES'),
    (N'HUEMUL'),
    (N'ISLA DE MAIPO'),
    (N'LA DEHESA'),
    (N'LA GLORIA'),
    (N'LA PALMA'),
    (N'LA RAMADA'),
    (N'LA TUNA'),
    (N'LAS CABRAS'),
    (N'LINARES'),
    (N'LINDEROS'),
    (N'LO MOSCOSO'),
    (N'LOLOL'),
    (N'LONGAVI'),
    (N'LONQUEN'),
    (N'LONTUE'),
    (N'LOS LINGUES'),
    (N'LOS LIRIOS'),
    (N'LOS NICHES'),
    (N'LOS ROBLES'),
    (N'MACHALI'),
    (N'MAIPO'),
    (N'MANANTIALES'),
    (N'MARCHIGUE'),
    (N'MOLINA'),
    (N'MULCHEN'),
    (N'NANCAGUA'),
    (N'NINCUNLAUTA'),
    (N'OLIVAR'),
    (N'OSORNO'),
    (N'EL ESPINO'),
    (N'PALMILLA'),
    (N'COQUIMBO'),
    (N'PEDEHUE'),
    (N'PELEQUEN'),
    (N'PEÑUELAS'),
    (N'PERALILLO'),
    (N'PEUMO'),
    (N'PICHILEMU'),
    (N'PLACILLA'),
    (N'AEROPUERTO'),
    (N'POBLACION'),
    (N'POLONIA'),
    (N'PUENTE NEGRO'),
    (N'PUQUILLAY'),
    (N'QUILLOTA'),
    (N'RANCAGUA'),
    (N'RAUCO'),
    (N'RENGO'),
    (N'REQUINOA'),
    (N'RETIRO'),
    (N'RIO CLARO'),
    (N'ROMA'),
    (N'ROMERAL'),
    (N'ROSARIO'),
    (N'SAGRADA FAMILIA'),
    (N'SAN BERNARDO'),
    (N'SAN CLEMENTE'),
    (N'SAN FRANCISCO MOSTAZAL'),
    (N'SAN FERNANDO'),
    (N'SAN JAVIER'),
    (N'SAN VICENTE'),
    (N'SANTA CRUZ'),
    (N'SANTIAGO'),
    (N'TALCA'),
    (N'TALCAREHUE'),
    (N'TAULEMU'),
    (N'TENO'),
    (N'TINGUIRIRICA'),
    (N'TOME'),
    (N'VILLA ALEGRE(SEXTA)'),
    (N'VILLARRICA'),
    (N'VILUCO MAIPO'),
    (N'YAQUIL'),
    (N'YERBAS BUENAS'),
    (N'LO HERRERA'),
    (N'MALLOA'),
    (N'SANTA ISABEL'),
    (N'MAIPU'),
    (N'QUICHARCO'),
    (N'TIL TIL'),
    (N'CAÑADILLA'),
    (N'LLALLAGUA'),
    (N'LOS MAITENES'),
    (N'SAN ANTONIO'),
    (N'VILLA ALEGRE(SEPTIMA)'),
    (N'VALPARAISO'),
    (N'LISONJERAS'),
    (N'COLCHAGUA'),
    (N'EL MONTE'),
    (N'MELIPILLA'),
    (N'ESTACION CENTRAL'),
    (N'PUDAHUEL'),
    (N'POLPAICO'),
    (N'CURACAVI'),
    (N'QUINTA DE TILCOCO'),
    (N'VALDIVIA DE PAINE'),
    (N'D&S'),
    (N'LAS CONDES'),
    (N'BILBAO'),
    (N'LA REINA'),
    (N'LA FLORIDA'),
    (N'MAS'),
    (N'CHEPICA/TENO'),
    (N'PICHIDEGUA'),
    (N'SAN JAVIER (INTERIOR)'),
    (N'LOS ANGELES'),
    (N'ALTO JAHUEL'),
    (N'PIRQUE'),
    (N'VILLA PRAT'),
    (N'CHAMONATE'),
    (N'SERVIEXPORT'),
    (N'LOS ANDES'),
    (N'ORILLA DE AUQUINCO'),
    (N'GB SERVICES'),
    (N'RECOLETA'),
    (N'FRIGOQUALITY'),
    (N'COLBUN'),
    (N'RIO CLARO (EL BOLSICO)'),
    (N'PELARCO'),
    (N'BOYERUCA'),
    (N'ARGENTINA'),
    (N'PUCON'),
    (N'L. ANGELES'),
    (N'CURARREHUE'),
    (N'CHIMBARONGO-CODEGUA'),
    (N'PLANTA LOS ANGELES'),
    (N'NEGRETE'),
    (N'CABRERO'),
    (N'GORBEA'),
    (N'RIO NEGRO ARGENTINA'),
    (N'PELARCO INTERIOR'),
    (N'PARRAL (AGR. MIARARIOS)'),
    (N'RENGO INTERIOR'),
    (N'FUTRONO'),
    (N'PAILLACO'),
    (N'ANTUCO'),
    (N'PACK.CODEGUA'),
    (N'INTEGRITY'),
    (N'SAN NICOLAS'),
    (N'LINARES (DON VICENTE)'),
    (N'VIÑA DEL MAR'),
    (N'CAMARICO'),
    (N'SAN CARLOS ÑUBLE'),
    (N'PARRAL ( STA. ANGELA)'),
    (N'M.GONZALES'),
    (N'PARRAL (F. HUECHUN)'),
    (N'CHILLAN COHIUECO'),
    (N'EL CALABOZO'),
    (N'COLLIPULLI'),
    (N'EL PERAL'),
    (N'CERRO COLORADO'),
    (N'ROSARIO (STA MARGARITA)'),
    (N'MULCHEN PILE'),
    (N'LAMPA'),
    (N'PUENTE ALTO'),
    (N'ROMERAL-AGROFRIO'),
    (N'CHIMBARONGO-FRUIT'),
    (N'TALAGANTE'),
    (N'RIO BUENO'),
    (N'LA PALOMA (CERASUS)'),
    (N'LINARES (FOR. EL PEUMO)'),
    (N'SANTO DOMINGO'),
    (N'NAVIDAD'),
    (N'CORONEL'),
    (N'SARMIENTO'),
    (N'CAHUIL'),
    (N'CABILDO'),
    (N'TRICAHUE'),
    (N'TOTIHUE'),
    (N'COLTAUCO (LOS BRONCES)'),
    (N'TRAPICHE'),
    (N'PUANGUE'),
    (N'RAPEL'),
    (N'DUAO'),
    (N'CONCEPCION'),
    (N'APALTA'),
    (N'LINARES (INTERIOR)'),
    (N'LINARES (EL BOSQUE)'),
    (N'PANQUEHUE'),
    (N'LITUECHE'),
    (N'TUTUQUEN'),
    (N'BULNES'),
    (N'BARRIALES'),
    (N'SAN FELIPE'),
    (N'SAN CARLOS'),
    (N'COYA'),
    (N'LA LAJUELA'),
    (N'CUNCUMEN'),
    (N'CALERA'),
    (N'SAN GREGORIO'),
    (N'MALLARAUCO'),
    (N'HUALAÑE'),
    (N'TILTIL'),
    (N'PETORCA'),
    (N'SAN PEDRO DE ALCANTARA'),
    (N'SAGRADA FAMILIA (PTA SAN LUIS)'),
    (N'PAINE (MULTIFRUTA)'),
    (N'PANGUIPULLI'),
    (N'QUILICURA'),
    (N'LOS ANGELES (INTEGRITY)'),
    (N'TRAIGUEN'),
    (N'MELIPILLA (MARIA PINTO)'),
    (N'BARBA RUBIA'),
    (N'CHUMACO'),
    (N'UVA BLANCA (CHEPICA)'),
    (N'ALHUE'),
    (N'COINCO'),
    (N'CENFRUTAL'),
    (N'CHIMBARONGO-FRUSAN'),
    (N'ROSARIO ( AQUAGRO )'),
    (N'CODEGUA ( GREENEX )'),
    (N'MELOZAL'),
    (N'AUQUINCO'),
    (N'PENCAHUE'),
    (N'LOS ANDES ( AG II )'),
    (N'LA CABRERIA'),
    (N'YERBAS BUENAS.'),
    (N'CERRILLOS'),
    (N'BUIN (EL COMINO)'),
    (N'AGROROSARIO'),
    (N'CURICÓ (SUR)'),
    (N'LOS LINGUES (FCO ALEMAN)'),
    (N'VILLA ALEGRE (SEMINARIO)'),
    (N'SAN RAFAEL'),
    (N'SAN ESTEBAN'),
    (N'LLAY LLAY'),
    (N'LOS ESPEJOS'),
    (N'EL HUIQUE')
  ) v(nombre)
),
src AS (
  SELECT DISTINCT LTRIM(RTRIM(nombre)) AS nombre
  FROM raw_list
  WHERE nombre IS NOT NULL AND LTRIM(RTRIM(nombre)) <> N''
)
MERGE cfl.CFL_nodo_logistico AS t
USING src AS s
ON t.nombre = s.nombre
WHEN MATCHED THEN
  UPDATE SET t.activo = 1
WHEN NOT MATCHED THEN
  INSERT (nombre, region, comuna, ciudad, calle, activo)
  VALUES (s.nombre, 'POR DEFINIR', 'POR DEFINIR', 'POR DEFINIR', 'POR DEFINIR', 1);

/* ============================================================
   6) CFL_ruta – generadas desde TARIFAS (PLANO + TERMOS)
   ============================================================ */
DECLARE @Rutas TABLE (origen nvarchar(200), destino nvarchar(200), distancia_km decimal(10,2));

/* --- RUTAS PLANO SOLO / CARRO (184 filas, expandido) --- */
INSERT INTO @Rutas(origen, destino, distancia_km)
VALUES
(N'Planta Placilla',N'La Gloria',4),
(N'Planta Placilla',N'Villa Alegre',7),
(N'Planta Placilla',N'Taulemu',7),
(N'Planta Placilla',N'Santa Isabel',7),
(N'Planta Placilla',N'Placilla',7),
(N'Planta Placilla',N'Nancagua',7),
(N'Planta Placilla',N'La Tuna',7),
(N'Planta Placilla',N'La Dehesa',7),
(N'Chimbarongo',N'Cenfrutal',10),
(N'Planta Placilla',N'Manantiales',12),
(N'Planta Placilla',N'Peñuelas',13),
(N'Planta Placilla',N'Cunaco',14),
(N'Planta Placilla',N'Nancagua ( La Cabreria )',16),
(N'Planta Maipo',N'Isla de Maipo',17),
(N'Planta Placilla',N'Viveros Guillaume ( Uva Blanca )',18),
(N'Planta Placilla',N'Pedehue',19),
(N'San Fernando',N'Chimbarongo',20),
(N'Planta Maipo',N'Paine',21),
(N'Planta Placilla',N'San Fernando',22),
(N'Planta Placilla',N'Cañadilla',22),
(N'Planta Placilla',N'Agua Buena',23),
(N'Planta Placilla',N'Santa Cruz',24),
(N'Planta Placilla',N'Polonia',28),
(N'Los Andes ( AG II )',N'San Felipe ( Centro de Armado )',30),
(N'Molina',N'Romeral',30),
(N'Planta Maipo',N'Olivar',30),
(N'Planta Placilla',N'Los Lingues',30),
(N'Planta Placilla',N'Tinguiririca',32),
(N'Planta Placilla',N'Talcarehue',32),
(N'Planta Placilla',N'Roma',32),
(N'Planta Placilla',N'Puente Negro',32),
(N'Planta Placilla',N'El Tambo',33),
(N'Curico ( UAC )',N'Chimbarongo ( Cenfrutal )',35),
(N'Planta Placilla',N'Malloa',36),
(N'Planta Placilla',N'Chepica',39),
(N'San Fernando ( Casas del Romeral )',N'Requinoa ( Del Monte )',39),
(N'Romeral',N'Chimbarongo',40),
(N'Los Lingues',N'Chimbarongo',41),
(N'Planta Placilla',N'Rosario',44),
(N'Planta Placilla',N'Chimbarongo',44),
(N'Molina',N'Chimbarongo',45),
(N'Planta Maipo',N'Codegua',45),
(N'Planta Placilla',N'Rengo',46),
(N'Planta Placilla',N'Teno',48),
(N'Planta Los Angeles',N'Angol',52),
(N'Planta Placilla',N'Requinoa',53),
(N'San Fernando',N'Romeral',57),
(N'Paine',N'Requinoa',60),
(N'Chimbarongo ( Casas del Romeral )',N'Requinoa ( Del Monte )',61),
(N'Planta Placilla',N'Los Lirios',61),
(N'Planta Placilla',N'Chumaco',61),
(N'Planta Maipo',N'Pudahuel ( Pallet Chep )',62),
(N'Planta Placilla',N'Quinta de Tilcoco',62),
(N'Planta Placilla',N'Olivar',67),
(N'Planta Maipo',N'Machalí',68),
(N'Planta Maipo',N'Rancagua',69),
(N'Planta Placilla',N'Rancagua',69),
(N'Planta Placilla',N'Coltauco',70),
(N'Planta Placilla',N'Romeral',71),
(N'Rosario',N'Teno',72),
(N'Planta Placilla',N'Las Cabras',73),
(N'Planta Maipo',N'Requinoa',75),
(N'Planta Placilla',N'Coltauco ( Calvari - La Parra )',76),
(N'Planta Placilla',N'Sarmiento',76),
(N'Planta Maipo',N'Rosario',80),
(N'Planta Placilla',N'Machalí',80),
(N'Rosario',N'Romeral',80),
(N'Planta Placilla',N'Pichidegua',81),
(N'Planta Placilla',N'Lontué',82),
(N'Planta Placilla',N'Graneros',82),
(N'Planta Placilla',N'Rauco',84),
(N'Planta Maipo',N'Coya',85),
(N'Rosario',N'Curico',86),
(N'Planta Placilla',N'Doñihue',89),
(N'Planta Maipo',N'Rengo ( Terrafrut )',90),
(N'Planta Placilla',N'Molina',91),
(N'Planta Placilla',N'San Fco. Mostazal',92),
(N'Planta Placilla',N'El Manzano',93),
(N'Planta Maipo',N'Rengo ( Los Notros )',95),
(N'Planta Placilla',N'Sagrada Familia',95),
(N'Planta Maipo',N'Malloa ( Frusal )',96),
(N'Planta Maipo',N'Coltauco',97),
(N'Planta Maipo',N'Quinta de Tilcoco',100),
(N'Rosario',N'Sagrada Familia',105),
(N'Planta Maipo',N'San Fernando',108),
(N'Planta Maipo',N'El Tambo',108),
(N'Planta Maipo',N'Roma',111),
(N'Planta Placilla',N'Raphel ( verfrut )',111),
(N'Planta Placilla',N'Los Niches',112),
(N'Planta Placilla',N'Paine',114),
(N'Chimbarongo',N'San Javier',123),
(N'Planta Placilla',N'Cumpeo',123),
(N'Planta Placilla',N'Buin',123),
(N'Planta Placilla',N'Planta Maipo',125),
(N'Planta Maipo',N'Nancagua',130),
(N'Planta Placilla',N'Lo Herrera',132),
(N'Planta Placilla',N'Isla de Maipo',132),
(N'Planta Placilla',N'Polonia - Planta Maipo ( Agricola Doña Constanza )',133),
(N'Planta Placilla',N'Molloa - Planta Maipo  ( Santa Ines de Malloa )',134),
(N'Planta Placilla',N'Calera de Tango',134),
(N'Planta Placilla',N'Talca',135),
(N'Yerbas Buenas ( Flor Oriente )',N'Chimbarongo',136),
(N'Planta Placilla',N'Talagante',140),
(N'Planta Maipo',N'Chimbarongo',142),
(N'Planta Maipo',N'Tinguiririca',142),
(N'Planta Placilla',N'Villa Prat',142),
(N'Planta Maipo',N'Las Cabras',143),
(N'Planta Maipo',N'Peumo',145),
(N'Planta Maipo',N'San Vicente',145),
(N'Planta Maipo',N'Nancagua ( La Cabreria )',145),
(N'Planta Placilla',N'Santiago',147),
(N'Planta Placilla',N'Rio Claro',148),
(N'Planta Maipo',N'Santa Cruz',149),
(N'Planta Placilla',N'San Clemente',150),
(N'Planta Placilla',N'Melipilla',150),
(N'Planta Placilla',N'San Javier',151),
(N'Planta Placilla',N'Doñihue - Planta Maipo ( Copello )',151),
(N'Planta Maipo',N'Teno',154),
(N'Planta Maipo',N'San Felipe',160),
(N'Rosario',N'San Javier',168),
(N'Quilicura',N'Planta Placilla',169),
(N'Planta Los Angeles',N'Chillan ( Agrobureo - Mayi Martinez - Santa Blanca )',171),
(N'Planta Maipo',N'Romeral',171),
(N'Planta Maipo',N'Curico',171),
(N'Planta Maipo',N'Sagrada Familia',171),
(N'Planta Placilla',N'Yerbas Buenas',173),
(N'Planta Placilla',N'San Javier (interior)',175),
(N'Planta Maipo',N'Rauco',178),
(N'Planta Placilla',N'Lampa',180),
(N'Planta Placilla',N'Colina',180),
(N'Planta Placilla',N'Melozal',182),
(N'San Javier ( Pajonal )',N'Requinoa ( Del Monte )',183),
(N'Planta Placilla',N'Linares',185),
(N'Planta Maipo',N'Molina',187),
(N'San Javier ( Cassacia )',N'Requinoa ( Del Monte )',187),
(N'Rosario',N'Yerbas Buenas',195),
(N'Planta Placilla',N'Retiro',200),
(N'Yerbas Buenas ( Flor Oriente )',N'Requinoa ( Del Monte )',201),
(N'Planta Maipo',N'Los Niches',206),
(N'Planta Placilla',N'Colbun',206),
(N'Planta Placilla',N'Coya',208),
(N'Planta Placilla',N'Villa Alegre',210),
(N'Planta Placilla',N'Longavi',215),
(N'Planta Los Angeles',N'Longavi  ( Agricola la Quinta - Terrasur )',220),
(N'Planta Los Angeles',N'Yerbas Buenas',226),
(N'Planta Placilla',N'Parral',226),
(N'Planta Placilla',N'Los Andes',226),
(N'Planta Los Angeles',N'Parral ( Palomar )',230),
(N'Planta Placilla',N'San Felipe',242),
(N'Planta Placilla',N'Los Andes ( AG II )',242),
(N'Planta Los Angeles',N'San Javier',249),
(N'Planta Placilla',N'San Carlos',254),
(N'Talagante',N'San Javier',258),
(N'Planta Maipo',N'San Clemente',262),
(N'Planta Maipo',N'San Javier',262),
(N'Planta Maipo',N'Yerbas Buenas',262),
(N'Planta Maipo',N'Villa Alegre',263),
(N'Planta Placilla',N'Valparaiso',265),
(N'Planta Maipo',N'Linares',280),
(N'Talagante',N'Yerbas Buenas',285),
(N'Planta Placilla',N'Cauquenes',287),
(N'Planta Los Angeles',N'Panguipulli',288),
(N'Talagante',N'Colbun',290),
(N'Planta Maipo',N'Longavi',294),
(N'Planta Maipo',N'Parral',301),
(N'Planta Maipo',N'Retiro',309),
(N'Planta Placilla',N'Chillan',312),
(N'Planta Los Angeles',N'Rio Claro  ( San Carlos )',325),
(N'Planta Los Angeles',N'Sagrada Familia',325),
(N'Planta Maipo',N'Parral',331),
(N'Planta Los Angeles',N'Romeral',333),
(N'Planta Los Angeles',N'Teno',351),
(N'Planta Maipo',N'Chillan',380),
(N'Planta Los Angeles',N'Rosario',400),
(N'Planta Los Angeles',N'Rengo',400),
(N'Planta Placilla',N'Planta Los Angeles',407),
(N'Planta Placilla',N'Mulchén',440),
(N'Planta Placilla',N'Angol',463),
(N'Planta Maipo',N'Planta Los Angeles',490),
(N'Planta Maipo',N'Los Angeles ( Cantarrana )',496),
(N'Planta Los Angeles',N'Santiago',513),
(N'Planta Placilla',N'Panguipulli',690),
(N'Planta Maipo',N'Panguipulli',840),
(N'Planta Maipo',N'Futrono',900);

/* --- RUTAS TERMOS (63 filas, expandido) --- */
INSERT INTO @Rutas(origen, destino, distancia_km)
VALUES
(N'Planta Placilla',N'Viveros Guillaume ( Uva Blanca )',18),
(N'Planta Maipo',N'Paine',21),
(N'Planta Placilla',N'San Fernando ( Pedehue )',22),
(N'Planta Placilla',N'Cañadilla',22),
(N'Planta Placilla',N'Santa Cruz',24),
(N'Planta Los Angeles',N'Mulchen ( Claudio Sepulveda - Arrayan )',26),
(N'Planta Los Angeles',N'Los Angeles ( Advanta - Agrifor Doña Luisa - El Durazno )',29),
(N'Planta Placilla',N'Los Lingues',30),
(N'Planta Placilla',N'Tinguiririca',32),
(N'Planta Placilla',N'Agua Buena',32),
(N'Planta Placilla',N'Roma',32),
(N'Planta Placilla',N'Puente Negro',32),
(N'Planta Placilla',N'Chepica',39),
(N'Planta Los Angeles',N'Mulchén ( Entre Bosques - Quitralman - Greenwich Pile )',42),
(N'Planta Placilla',N'Rosario',44),
(N'Planta Placilla',N'Chimbarongo',44),
(N'Planta Placilla',N'Teno',48),
(N'Planta Placilla',N'Los Lirios',61),
(N'Planta Placilla',N'Quinta de Tilcoco',62),
(N'Planta Los Angeles',N'Cabrero',67),
(N'Planta Placilla',N'Olivar',67),
(N'Planta Placilla',N'Rancagua',69),
(N'Planta Placilla',N'Curico',69),
(N'Planta Placilla',N'Romeral',71),
(N'Planta Placilla',N'Las Cabras',73),
(N'Planta Placilla',N'Machalí',80),
(N'Planta Placilla',N'Graneros',82),
(N'Planta Placilla',N'Rauco',84),
(N'Planta Maipo',N'Rengo ( Terrafrut )',90),
(N'Planta Placilla',N'Molina',91),
(N'Planta Placilla',N'Sagrada Familia',95),
(N'Planta Placilla',N'Los Niches',112),
(N'Planta Placilla',N'Paine',114),
(N'Planta Placilla',N'Cumpeo',123),
(N'Planta Placilla',N'Planta Maipo',125),
(N'Planta Placilla',N'Lo Herrera',132),
(N'Planta Placilla',N'Talca',135),
(N'Planta Placilla',N'Talagante',140),
(N'Planta Placilla',N'Villa Prat',142),
(N'Planta Placilla',N'Santiago',147),
(N'Planta Placilla',N'Rio Claro',148),
(N'Planta Placilla',N'San Clemente',150),
(N'Planta Placilla',N'Melipilla',150),
(N'Planta Placilla',N'San Javier',151),
(N'Planta Placilla',N'Doñihue - Planta Maipo ( Copello )',151),
(N'Planta Placilla',N'Yerbas Buenas',173),
(N'Planta Placilla',N'San Javier (interior)',175),
(N'Planta Placilla',N'Melozal',182),
(N'Planta Placilla',N'Linares',185),
(N'Planta Placilla',N'Retiro',200),
(N'Planta Placilla',N'Colbun',206),
(N'Planta Placilla',N'Longavi',215),
(N'Planta Los Angeles',N'Cauquenes',245),
(N'Planta Los Angeles',N'San Javier',249),
(N'Planta Los Angeles',N'Talca',282),
(N'Planta Placilla',N'Cauquenes',287),
(N'Planta Los Angeles',N'Panguipulli',288),
(N'Planta Placilla',N'Chillan',312),
(N'Planta Placilla',N'Planta Los Angeles',407),
(N'Planta Los Angeles',N'Futrono',350),
(N'Planta Placilla',N'Mulchén',440),
(N'Planta Placilla',N'Panguipulli',690),
(N'Planta Los Angeles',N'Pencahue',424);

/* Inserta nodos adicionales que aparecen en rutas y no estaban en lista (normalizados) */
;WITH nodes_from_routes AS (
  SELECT DISTINCT LTRIM(RTRIM(origen))  AS nombre FROM @Rutas
  UNION
  SELECT DISTINCT LTRIM(RTRIM(destino)) AS nombre FROM @Rutas
),
src_nodes AS (
  SELECT nombre
  FROM nodes_from_routes
  WHERE nombre IS NOT NULL AND nombre <> N''
)
MERGE cfl.CFL_nodo_logistico AS t
USING src_nodes AS s
ON t.nombre = s.nombre
WHEN MATCHED THEN
  UPDATE SET t.activo = 1
WHEN NOT MATCHED THEN
  INSERT (nombre, region, comuna, ciudad, calle, activo)
  VALUES (s.nombre, 'POR DEFINIR', 'POR DEFINIR', 'POR DEFINIR', 'POR DEFINIR', 1);

/* Inserta/actualiza rutas (dedupe por clave antes del MERGE) */
;WITH rutas_norm AS (
  SELECT
    LTRIM(RTRIM(r.origen))  AS origen_norm,
    LTRIM(RTRIM(r.destino)) AS destino_norm,
    CAST(r.distancia_km AS decimal(10,2)) AS distancia_km
  FROM @Rutas r
  WHERE r.origen IS NOT NULL AND r.destino IS NOT NULL
    AND LTRIM(RTRIM(r.origen))  <> N''
    AND LTRIM(RTRIM(r.destino)) <> N''
),
rutas_join AS (
  SELECT
    o.id_nodo AS id_origen_nodo,
    d.id_nodo AS id_destino_nodo,
    rn.origen_norm  AS origen,
    rn.destino_norm AS destino,
    rn.distancia_km
  FROM rutas_norm rn
  JOIN cfl.CFL_nodo_logistico o ON o.nombre = rn.origen_norm
  JOIN cfl.CFL_nodo_logistico d ON d.nombre = rn.destino_norm
),
rutas_dedup AS (
  SELECT
    id_origen_nodo,
    id_destino_nodo,
    origen,
    destino,
    distancia_km,
    ROW_NUMBER() OVER (
      PARTITION BY id_origen_nodo, id_destino_nodo
      ORDER BY distancia_km DESC, origen, destino
    ) AS rn
  FROM rutas_join
)
MERGE cfl.CFL_ruta AS t
USING (
  SELECT
    id_origen_nodo,
    id_destino_nodo,
    origen,
    destino,
    distancia_km
  FROM rutas_dedup
  WHERE rn = 1
) AS s
ON  t.id_origen_nodo  = s.id_origen_nodo
AND t.id_destino_nodo = s.id_destino_nodo
WHEN MATCHED THEN
  UPDATE SET
    t.distancia_km = s.distancia_km,
    t.nombre_ruta  = CONCAT(s.origen, ' -> ', s.destino),
    t.activo       = 1,
    t.updated_at   = @now
WHEN NOT MATCHED THEN
  INSERT (id_origen_nodo, id_destino_nodo, nombre_ruta, distancia_km, activo, created_at, updated_at)
  VALUES (s.id_origen_nodo, s.id_destino_nodo, CONCAT(s.origen, ' -> ', s.destino), s.distancia_km, 1, @now, @now);


/* ============================================================
   7) CFL_centro_costo POR DEFINIR + CFL_tipo_flete (0001..0006)
   ============================================================ */
MERGE cfl.CFL_centro_costo AS t
USING (SELECT 'POR DEFINIR' AS sap_codigo, 'POR DEFINIR' AS nombre) s
ON t.sap_codigo = s.sap_codigo
WHEN NOT MATCHED THEN
  INSERT (sap_codigo, nombre, activo) VALUES (s.sap_codigo, s.nombre, 1);

DECLARE @id_cc_por_definir bigint = (SELECT TOP 1 id_centro_costo FROM cfl.CFL_centro_costo WHERE sap_codigo='POR DEFINIR');

;WITH src AS (
    SELECT sap_codigo, nombre, @id_cc_por_definir AS id_centro_costo, 1 AS activo
    FROM (VALUES
      ('0001', N'TRASLADO DE FRUTA'),
      ('0002', N'TRASLADO DE MATERIALES'),
      ('0003', N'TRASLADO PUERTO - AEROPUERTO'),
      ('0004', N'TRASLADO INTERPLANTA'),
      ('0005', N'TRASLADO MERCADO NACIONAL'),
      ('0006', N'TRASLADO MUESTRA USDA')
    ) v(sap_codigo, nombre)
)
MERGE cfl.CFL_tipo_flete AS t
USING src AS s
ON t.sap_codigo = s.sap_codigo
WHEN MATCHED THEN
  UPDATE SET
    t.nombre = s.nombre,
    t.activo = s.activo,
    t.id_centro_costo = s.id_centro_costo
WHEN NOT MATCHED THEN
  INSERT (sap_codigo, nombre, activo, id_centro_costo)
  VALUES (s.sap_codigo, s.nombre, s.activo, s.id_centro_costo);

/* ============================================================
   8) Roles + Usuarios + asignación
   ============================================================ */
;WITH src AS (
  SELECT nombre, descripcion, activo
  FROM (VALUES
    ('Administrador', 'Acceso total al sistema', 1),
    ('Autorizador',   'Aprueba/cierra folios y autoriza cambios', 1),
    ('Ingresador',    'Registra/edita fletes y conciliaciones', 1)
  ) v(nombre, descripcion, activo)
)
MERGE cfl.CFL_rol AS t
USING src AS s
ON t.nombre = s.nombre
WHEN MATCHED THEN
  UPDATE SET t.descripcion = s.descripcion, t.activo = s.activo
WHEN NOT MATCHED THEN
  INSERT (nombre, descripcion, activo) VALUES (s.nombre, s.descripcion, s.activo);

DECLARE @pwd nvarchar(200) = '123456';
DECLARE @pwd_hash varchar(255) = CONVERT(varchar(255), HASHBYTES('SHA2_256', CONVERT(varbinary(max), @pwd)), 2);

;WITH src AS (
  SELECT username, email, nombre, apellido, activo
  FROM (VALUES
    ('admin',      'admin@local.test',      'Usuario', 'Administrador', 1),
    ('autorizador','autorizador@local.test','Usuario', 'Autorizador',   1),
    ('ingresador', 'ingresador@local.test', 'Usuario', 'Ingresador',    1)
  ) v(username, email, nombre, apellido, activo)
)
MERGE cfl.CFL_usuario AS t
USING src AS s
ON t.username = s.username
WHEN MATCHED THEN
  UPDATE SET
    t.email = s.email,
    t.nombre = s.nombre,
    t.apellido = s.apellido,
    t.activo = s.activo,
    t.password_hash = @pwd_hash,
    t.updated_at = @now
WHEN NOT MATCHED THEN
  INSERT (username, email, password_hash, nombre, apellido, activo, created_at, updated_at)
  VALUES (s.username, s.email, @pwd_hash, s.nombre, s.apellido, s.activo, @now, @now);

DECLARE @id_admin bigint = (SELECT id_usuario FROM cfl.CFL_usuario WHERE username='admin');
DECLARE @id_aut   bigint = (SELECT id_usuario FROM cfl.CFL_usuario WHERE username='autorizador');
DECLARE @id_ing   bigint = (SELECT id_usuario FROM cfl.CFL_usuario WHERE username='ingresador');

DECLARE @rol_admin bigint = (SELECT id_rol FROM cfl.CFL_rol WHERE nombre='Administrador');
DECLARE @rol_aut   bigint = (SELECT id_rol FROM cfl.CFL_rol WHERE nombre='Autorizador');
DECLARE @rol_ing   bigint = (SELECT id_rol FROM cfl.CFL_rol WHERE nombre='Ingresador');

MERGE cfl.CFL_usuario_rol AS t
USING (VALUES
  (@id_admin, @rol_admin),
  (@id_aut,   @rol_aut),
  (@id_ing,   @rol_ing)
) s(id_usuario, id_rol)
ON t.id_usuario = s.id_usuario AND t.id_rol = s.id_rol
WHEN NOT MATCHED THEN
  INSERT (id_usuario, id_rol) VALUES (s.id_usuario, s.id_rol);

/* ============================================================
   9) Choferes (lista completa)
   ============================================================ */
;WITH src AS (
  SELECT sap_id_fiscal, sap_nombre, telefono
  FROM (VALUES
    ('10612195','MARCEL GONZALEZ','993512344'),
    ('16374184','CAMILO ROJAS','978725444'),
    ('8238400','ROBERTO RODRIGUEZ','940017205'),
    ('10741492','CLAUDIO GALVEZ','893352114'),
    ('16973328','SEBASTIAN DINAMARCA','124753323'),
    ('8859361','HERNAN INOSTROZA','99645671'),
    ('4649320','HECTOR JIMENEZ','99587461'),
    ('11368008','FRANCISCO DURAN','99542191'),
    ('6835261','LUIS MOLINA','99534412'),
    ('10757678','JAIME DURAN','99158631'),
    ('10014019','LUIS UBILLA A.','99090395'),
    ('13099767','JOSE ORELLANA','98541724'),
    ('11145086','EDUARDO TREJOS','98273081'),
    ('7644257','RENATO MADRID','98180340'),
    ('11368900','JUAN VILLANUEVA','97803731'),
    ('13002997','CESAR CORNEJO','97577488'),
    ('14048783','RONALD SUAZO ROJAS','97444998'),
    ('13859969','JORGE TRONCOSO VEJAR','96680569'),
    ('10019478','CAMILO VALDERRAMA','95422197'),
    ('9137502','PATRICIO MOLINA','95169526'),
    ('11952016','HECTOR LIZANA','94873483'),
    ('11555256','PEDRO ROMERO','94673249'),
    ('11536525','SERGIO VIELMA','94582283'),
    ('8606289','DAGOBERTO ALIAGA','94481513'),
    ('8416079','JOSE LEIVA','93776863'),
    ('10982779','SANDRO BECERRA ROJAS','93611571'),
    ('14463165','JUAN CARLOS VERDEJO BAQUEDANO','93325769'),
    ('9871353','SERGIO ALIAGA','93221758'),
    ('7561534','NARCISO MIRANDA','93179092'),
    ('4404258','VICTOR ARENAS','92648421'),
    ('7462618','LUIS FARIAS','92298224'),
    ('8884419','LUIS IBAÑEZ','92274643'),
    ('10887223','ENRIQUE REHBEIN','91596497'),
    ('9138107','JUAN MEDINA','90873994'),
    ('12228501','MARCO MALDONADO','90339448'),
    ('12723988','HUGO MARTINEZ','90114018'),
    ('7944342','LUIS LIZANA','89997059'),
    ('10563286','JAVIER TORO','89948390'),
    ('9606507','EDO VILLALOBOS (NO)','89721131'),
    ('9606537','EDUARDO VILLALOBOS','89721131'),
    ('6958288','JOSE RAMIREZ','88690744'),
    ('8623735','MANUEL ARMIJO','88668625'),
    ('13064934','MAGDIEL OLIVEROS','88065408'),
    ('4402594','JUAN DE DIOS LOPEZ MORALES','85782031'),
    ('13780197','MAX SOTO','85448939'),
    ('12249000','JUAN CONTRERAS','85397963'),
    ('7423374','JOSE ARANCIBIA','85056834'),
    ('10439408','RICARDO CARVAJAL','84620115'),
    ('6515982','AMBROSIO ZAMORANO','83755010'),
    ('11282851','GERMAN NEGRETE','83116519'),
    ('14421269','MARIO LETELIER','83060684'),
    ('12373615','LUIS ALEJABDRO TORRES PARRA','82032483'),
    ('11701610','LIUS LASTRA','81895210'),
    ('6663736','AGUSTIN BRIONES','81770607'),
    ('9695159','LUIS AGUILERA','81485071'),
    ('14337764','CLAUDIO ESTRADA','81485071'),
    ('10502507','NADIM SARRUA REYES','81485071'),
    ('15526982','FRANCISCO FIGUEROA SEPULVEDA','81485071'),
    ('12261713','NELSON ACEVEDO GUZMAN','81485071'),
    ('16223705','FELIPE ROMERO','81453214'),
    ('9508995','JORGE ROJAS','78394668')
  ) v(sap_id_fiscal, sap_nombre, telefono)
)
MERGE cfl.CFL_chofer AS t
USING src AS s
ON t.sap_id_fiscal = s.sap_id_fiscal
WHEN MATCHED THEN
  UPDATE SET
    t.sap_nombre = s.sap_nombre,
    t.telefono = s.telefono,
    t.activo = 1
WHEN NOT MATCHED THEN
  INSERT (sap_id_fiscal, sap_nombre, telefono, activo)
  VALUES (s.sap_id_fiscal, s.sap_nombre, s.telefono, 1);

/* ============================================================
   10) Empresas de transporte (varias, desde tu lista)
   ============================================================ */
;WITH src AS (
  SELECT rut, razon_social, telefono, correo, nombre_rep
  FROM (VALUES
    ('78597540-5', 'TRANSPORTES PIEMONTE', '722714529', NULL, NULL),
    ('9647113-0',  'ARTURO VENEGAS', NULL, NULL, NULL),
    ('76673592-4', 'TRANS.ANDREA CORNEJO PARRAGUEZ', '954151478', NULL, NULL),
    ('76406384-8', 'SOC. DE TRANS.AGUILERA LATINSU', '81485071', NULL, NULL),
    ('15953537-1', 'FELIPE MARIN FUENTES', NULL, NULL, 'FELIPE MARIN'),
    ('53219990-5', 'SUCESION OSVALDO ERBETTA', '72366987', NULL, NULL),
    ('14017534-K', 'ANGELICA DEL CARMEN LABRA MALD', '89206536', NULL, NULL),
    ('12373615-K', 'LUIS ALEJANDRO TORRES PARRA', NULL, NULL, NULL),
    ('76684363-8', 'TRANS. JAVIER TORO E.I.R.L.', '974778216', NULL, NULL),
    ('78918420-8', 'AGRICOLA SAA LTDA', NULL, NULL, NULL)
  ) v(rut, razon_social, telefono, correo, nombre_rep)
)
MERGE cfl.CFL_empresa_transporte AS t
USING src AS s
ON t.rut = s.rut
WHEN MATCHED THEN
  UPDATE SET
    t.razon_social = s.razon_social,
    t.telefono = COALESCE(s.telefono, t.telefono),
    t.correo = COALESCE(s.correo, t.correo),
    t.nombre_rep = COALESCE(s.nombre_rep, t.nombre_rep),
    t.activo = 1,
    t.updated_at = @now
WHEN NOT MATCHED THEN
  INSERT (sap_codigo, rut, razon_social, nombre_rep, correo, telefono, activo, created_at, updated_at)
  VALUES (NULL, s.rut, s.razon_social, s.nombre_rep, s.correo, s.telefono, 1, @now, @now);

/* ============================================================
   11) Camiones de prueba (2)
   ============================================================ */
;WITH src AS (
  SELECT id_tipo_camion, sap_patente, sap_carro, activo
  FROM (VALUES
    (@id_tc_plano_solo,  'AA-BB-11', 'CARRO-01', 1),
    (@id_tc_termo_chico, 'CC-DD-22', 'SIN-CARRO', 1)
  ) v(id_tipo_camion, sap_patente, sap_carro, activo)
)
MERGE cfl.CFL_camion AS t
USING src AS s
ON t.sap_patente = s.sap_patente AND t.sap_carro = s.sap_carro
WHEN MATCHED THEN
  UPDATE SET
    t.id_tipo_camion = s.id_tipo_camion,
    t.activo = s.activo,
    t.updated_at = @now
WHEN NOT MATCHED THEN
  INSERT (id_tipo_camion, sap_patente, sap_carro, activo, created_at, updated_at)
  VALUES (s.id_tipo_camion, s.sap_patente, s.sap_carro, s.activo, @now, @now);

/* ============================================================
   12) TARIFAS – PLANO SOLO / CARRO (184 filas, expandido)
   ============================================================ */
DECLARE @TarifasPlano TABLE(
  origen nvarchar(200),
  destino nvarchar(200),
  distancia_km decimal(10,2),
  monto_solo decimal(18,2),
  monto_carro decimal(18,2)
);

INSERT INTO @TarifasPlano(origen,destino,distancia_km,monto_solo,monto_carro)
VALUES
(N'Planta Placilla',N'La Gloria',4,47000,58000),
(N'Planta Placilla',N'Villa Alegre',7,47000,58000),
(N'Planta Placilla',N'Taulemu',7,47000,58000),
(N'Planta Placilla',N'Santa Isabel',7,47000,58000),
(N'Planta Placilla',N'Placilla',7,47000,58000),
(N'Planta Placilla',N'Nancagua',7,47000,58000),
(N'Planta Placilla',N'La Tuna',7,47000,58000),
(N'Planta Placilla',N'La Dehesa',7,47000,58000),
(N'Chimbarongo',N'Cenfrutal',10,47000,58000),
(N'Planta Placilla',N'Manantiales',12,53000,61000),
(N'Planta Placilla',N'Peñuelas',13,53000,61000),
(N'Planta Placilla',N'Cunaco',14,53000,61000),
(N'Planta Placilla',N'Nancagua ( La Cabreria )',16,58000,65000),
(N'Planta Maipo',N'Isla de Maipo',17,58000,65000),
(N'Planta Placilla',N'Viveros Guillaume ( Uva Blanca )',18,58000,70000),
(N'Planta Placilla',N'Pedehue',19,58000,70000),
(N'San Fernando',N'Chimbarongo',20,63000,74000),
(N'Planta Maipo',N'Paine',21,63000,77000),
(N'Planta Placilla',N'San Fernando',22,63000,77000),
(N'Planta Placilla',N'Cañadilla',22,63000,77000),
(N'Planta Placilla',N'Agua Buena',23,68000,80000),
(N'Planta Placilla',N'Santa Cruz',24,68000,80000),
(N'Planta Placilla',N'Polonia',28,77000,90000),
(N'Los Andes ( AG II )',N'San Felipe ( Centro de Armado )',30,77000,99000),
(N'Molina',N'Romeral',30,77000,99000),
(N'Planta Maipo',N'Olivar',30,77000,99000),
(N'Planta Placilla',N'Los Lingues',30,77000,99000),
(N'Planta Placilla',N'Tinguiririca',32,84000,105000),
(N'Planta Placilla',N'Talcarehue',32,84000,105000),
(N'Planta Placilla',N'Roma',32,84000,105000),
(N'Planta Placilla',N'Puente Negro',32,84000,105000),
(N'Planta Placilla',N'El Tambo',33,84000,110000),
(N'Curico ( UAC )',N'Chimbarongo ( Cenfrutal )',35,84000,110000),
(N'Planta Placilla',N'Malloa',36,89000,120000),
(N'Planta Placilla',N'Chepica',39,89000,120000),
(N'San Fernando ( Casas del Romeral )',N'Requinoa ( Del Monte )',39,89000,120000),
(N'Romeral',N'Chimbarongo',40,95000,120000),
(N'Los Lingues',N'Chimbarongo',41,95000,129000),
(N'Planta Placilla',N'Rosario',44,100000,131000),
(N'Planta Placilla',N'Chimbarongo',44,100000,131000),
(N'Molina',N'Chimbarongo',45,100000,131000),
(N'Planta Maipo',N'Codegua',45,100000,131000),
(N'Planta Placilla',N'Rengo',46,100000,137000),
(N'Planta Placilla',N'Teno',48,105000,137000),
(N'Planta Los Angeles',N'Angol',52,110000,147000),
(N'Planta Placilla',N'Requinoa',53,116000,152000),
(N'San Fernando',N'Romeral',57,116000,158000),
(N'Paine',N'Requinoa',60,121000,163000),
(N'Chimbarongo ( Casas del Romeral )',N'Requinoa ( Del Monte )',61,126000,168000),
(N'Planta Placilla',N'Los Lirios',61,126000,168000),
(N'Planta Placilla',N'Chumaco',61,126000,168000),
(N'Planta Maipo',N'Pudahuel ( Pallet Chep )',62,126000,168000),
(N'Planta Placilla',N'Quinta de Tilcoco',62,126000,168000),
(N'Planta Placilla',N'Olivar',67,131000,175000),
(N'Planta Maipo',N'Machalí',68,131000,184000),
(N'Planta Maipo',N'Rancagua',69,137000,184000),
(N'Planta Placilla',N'Rancagua',69,137000,184000),
(N'Planta Placilla',N'Coltauco',70,137000,184000),
(N'Planta Placilla',N'Romeral',71,137000,184000),
(N'Rosario',N'Teno',72,142000,194000),
(N'Planta Placilla',N'Las Cabras',73,142000,194000),
(N'Planta Maipo',N'Requinoa',75,142000,194000),
(N'Planta Placilla',N'Coltauco ( Calvari - La Parra )',76,147000,194000),
(N'Planta Placilla',N'Sarmiento',76,147000,194000),
(N'Planta Maipo',N'Rosario',80,152000,200000),
(N'Planta Placilla',N'Machalí',80,152000,200000),
(N'Rosario',N'Romeral',80,152000,200000),
(N'Planta Placilla',N'Pichidegua',81,152000,210000),
(N'Planta Placilla',N'Lontué',82,158000,210000),
(N'Planta Placilla',N'Graneros',82,158000,210000),
(N'Planta Placilla',N'Rauco',84,158000,210000),
(N'Planta Maipo',N'Coya',85,158000,215000),
(N'Rosario',N'Curico',86,160000,218000),
(N'Planta Placilla',N'Doñihue',89,163000,215000),
(N'Planta Maipo',N'Rengo ( Terrafrut )',90,168000,226000),
(N'Planta Placilla',N'Molina',91,168000,226000),
(N'Planta Placilla',N'San Fco. Mostazal',92,168000,231000),
(N'Planta Placilla',N'El Manzano',93,168000,231000),
(N'Planta Maipo',N'Rengo ( Los Notros )',95,173000,231000),
(N'Planta Placilla',N'Sagrada Familia',95,173000,263000),
(N'Planta Maipo',N'Malloa ( Frusal )',96,171000,240000),
(N'Planta Maipo',N'Coltauco',97,173000,242000),
(N'Planta Maipo',N'Quinta de Tilcoco',100,189000,263000),
(N'Rosario',N'Sagrada Familia',105,189000,263000),
(N'Planta Maipo',N'San Fernando',108,189000,263000),
(N'Planta Maipo',N'El Tambo',108,189000,263000),
(N'Planta Maipo',N'Roma',111,194000,275000),
(N'Planta Placilla',N'Raphel ( verfrut )',111,194000,275000),
(N'Planta Placilla',N'Los Niches',112,194000,275000),
(N'Planta Placilla',N'Paine',114,200000,275000),
(N'Chimbarongo',N'San Javier',123,210000,294000),
(N'Planta Placilla',N'Cumpeo',123,210000,294000),
(N'Planta Placilla',N'Buin',123,210000,294000),
(N'Planta Placilla',N'Planta Maipo',125,215000,301000),
(N'Planta Maipo',N'Nancagua',130,221000,310000),
(N'Planta Placilla',N'Lo Herrera',132,221000,310000),
(N'Planta Placilla',N'Isla de Maipo',132,221000,310000),
(N'Planta Placilla',N'Polonia - Planta Maipo ( Agricola Doña Constanza )',133,231000,315000),
(N'Planta Placilla',N'Molloa - Planta Maipo  ( Santa Ines de Malloa )',134,231000,315000),
(N'Planta Placilla',N'Calera de Tango',134,231000,315000),
(N'Planta Placilla',N'Talca',135,231000,315000),
(N'Yerbas Buenas ( Flor Oriente )',N'Chimbarongo',136,233000,317000),
(N'Planta Placilla',N'Talagante',140,231000,331000),
(N'Planta Maipo',N'Chimbarongo',142,236000,341000),
(N'Planta Maipo',N'Tinguiririca',142,236000,341000),
(N'Planta Placilla',N'Villa Prat',142,236000,341000),
(N'Planta Maipo',N'Las Cabras',143,242000,341000),
(N'Planta Maipo',N'Peumo',145,242000,341000),
(N'Planta Maipo',N'San Vicente',145,242000,341000),
(N'Planta Maipo',N'Nancagua ( La Cabreria )',145,242000,341000),
(N'Planta Placilla',N'Santiago',147,243000,349000),
(N'Planta Placilla',N'Rio Claro',148,247000,349000),
(N'Planta Maipo',N'Santa Cruz',149,247000,349000),
(N'Planta Placilla',N'San Clemente',150,252000,349000),
(N'Planta Placilla',N'Melipilla',150,252000,349000),
(N'Planta Placilla',N'San Javier',151,252000,357000),
(N'Planta Placilla',N'Doñihue - Planta Maipo ( Copello )',151,252000,357000),
(N'Planta Maipo',N'Teno',154,257000,357000),
(N'Planta Maipo',N'San Felipe',160,257000,368000),
(N'Rosario',N'San Javier',168,280000,394000),
(N'Quilicura',N'Planta Placilla',169,282000,396000),
(N'Planta Los Angeles',N'Chillan ( Agrobureo - Mayi Martinez - Santa Blanca )',171,284000,401000),
(N'Planta Maipo',N'Romeral',171,284000,401000),
(N'Planta Maipo',N'Curico',171,284000,401000),
(N'Planta Maipo',N'Sagrada Familia',171,284000,401000),
(N'Planta Placilla',N'Yerbas Buenas',173,284000,401000),
(N'Planta Placilla',N'San Javier (interior)',175,284000,410000),
(N'Planta Maipo',N'Rauco',178,294000,410000),
(N'Planta Placilla',N'Lampa',180,294000,416000),
(N'Planta Placilla',N'Colina',180,294000,416000),
(N'Planta Placilla',N'Melozal',182,294000,416000),
(N'San Javier ( Pajonal )',N'Requinoa ( Del Monte )',183,296000,418000),
(N'Planta Placilla',N'Linares',185,305000,429000),
(N'Planta Maipo',N'Molina',187,305000,429000),
(N'San Javier ( Cassacia )',N'Requinoa ( Del Monte )',187,305000,429000),
(N'Rosario',N'Yerbas Buenas',195,320000,450000),
(N'Planta Placilla',N'Retiro',200,320000,450000),
(N'Yerbas Buenas ( Flor Oriente )',N'Requinoa ( Del Monte )',201,322000,452000),
(N'Planta Maipo',N'Los Niches',206,331000,473000),
(N'Planta Placilla',N'Colbun',206,331000,473000),
(N'Planta Placilla',N'Coya',208,331000,473000),
(N'Planta Placilla',N'Villa Alegre',210,336000,473000),
(N'Planta Placilla',N'Longavi',215,347000,500000),
(N'Planta Los Angeles',N'Longavi  ( Agricola la Quinta - Terrasur )',220,347000,500000),
(N'Planta Los Angeles',N'Yerbas Buenas',226,357000,510000),
(N'Planta Placilla',N'Parral',226,357000,510000),
(N'Planta Placilla',N'Los Andes',226,357000,510000),
(N'Planta Los Angeles',N'Parral ( Palomar )',230,368000,525000),
(N'Planta Placilla',N'San Felipe',242,383000,540000),
(N'Planta Placilla',N'Los Andes ( AG II )',242,383000,540000),
(N'Planta Los Angeles',N'San Javier',249,383000,557000),
(N'Planta Placilla',N'San Carlos',254,394000,562000),
(N'Talagante',N'San Javier',258,400000,571000),
(N'Planta Maipo',N'San Clemente',262,410000,588000),
(N'Planta Maipo',N'San Javier',262,410000,588000),
(N'Planta Maipo',N'Yerbas Buenas',262,410000,588000),
(N'Planta Maipo',N'Villa Alegre',263,410000,588000),
(N'Planta Placilla',N'Valparaiso',265,420000,600000),
(N'Planta Maipo',N'Linares',280,431000,620000),
(N'Talagante',N'Yerbas Buenas',285,441000,635000),
(N'Planta Placilla',N'Cauquenes',287,441000,635000),
(N'Planta Los Angeles',N'Panguipulli',288,441000,635000),
(N'Talagante',N'Colbun',290,457000,656000),
(N'Planta Maipo',N'Longavi',294,457000,656000),
(N'Planta Maipo',N'Parral',301,468000,675000),
(N'Planta Maipo',N'Retiro',309,474000,684000),
(N'Planta Placilla',N'Chillan',312,483000,700000),
(N'Planta Los Angeles',N'Rio Claro  ( San Carlos )',325,494000,714000),
(N'Planta Los Angeles',N'Sagrada Familia',325,494000,714000),
(N'Planta Maipo',N'Parral',331,504000,735000),
(N'Planta Los Angeles',N'Romeral',333,504000,735000),
(N'Planta Los Angeles',N'Teno',351,525000,763000),
(N'Planta Maipo',N'Chillan',380,567000,824000),
(N'Planta Los Angeles',N'Rosario',400,599000,866000),
(N'Planta Los Angeles',N'Rengo',400,599000,866000),
(N'Planta Placilla',N'Planta Los Angeles',407,609000,877000),
(N'Planta Placilla',N'Mulchén',440,656000,945000),
(N'Planta Placilla',N'Angol',463,683000,992000),
(N'Planta Maipo',N'Planta Los Angeles',490,735000,1050000),
(N'Planta Maipo',N'Los Angeles ( Cantarrana )',496,744000,1063000),
(N'Planta Los Angeles',N'Santiago',513,756000,1097000),
(N'Planta Placilla',N'Panguipulli',690,982000,1449000),
(N'Planta Maipo',N'Panguipulli',840,1229000,1785000),
(N'Planta Maipo',N'Futrono',900,1302000,1890000);

/* Inserta tarifas PLANO SOLO y PLANO CON CARRO (DEDUP antes del MERGE) */
;WITH tp_norm AS (
  SELECT
    LTRIM(RTRIM(origen))  AS origen,
    LTRIM(RTRIM(destino)) AS destino,
    CAST(distancia_km AS decimal(10,2)) AS distancia_km,
    CAST(monto_solo  AS decimal(18,2))  AS monto_solo,
    CAST(monto_carro AS decimal(18,2))  AS monto_carro
  FROM @TarifasPlano
),
tp_dedup AS (
  /* 1 fila por (origen,destino); si hay duplicados toma el mayor monto/distancia */
  SELECT
    origen, destino,
    MAX(distancia_km) AS distancia_km,
    MAX(monto_solo)   AS monto_solo,
    MAX(monto_carro)  AS monto_carro
  FROM tp_norm
  GROUP BY origen, destino
),
r AS (
  SELECT
    rt.id_ruta,
    t.monto_solo,
    t.monto_carro
  FROM tp_dedup t
  JOIN cfl.CFL_nodo_logistico o ON o.nombre = t.origen
  JOIN cfl.CFL_nodo_logistico d ON d.nombre = t.destino
  JOIN cfl.CFL_ruta rt ON rt.id_origen_nodo = o.id_nodo AND rt.id_destino_nodo = d.id_nodo
),
src_raw AS (
  SELECT
    @id_tc_plano_solo AS id_tipo_camion,
    @id_temporada     AS id_temporada,
    id_ruta,
    CAST('2025-08-25' AS date) AS vigencia_desde,
    CAST(NULL AS date)         AS vigencia_hasta,
    1 AS prioridad,
    'BASE' AS regla,
    'CLP'  AS moneda,
    monto_solo AS monto_fijo,
    1 AS activo
  FROM r
  UNION ALL
  SELECT
    @id_tc_plano_carro,
    @id_temporada,
    id_ruta,
    CAST('2025-08-25' AS date),
    NULL,
    1,
    'BASE',
    'CLP',
    monto_carro,
    1
  FROM r
),
src AS (
  /* 1 fila por la clave del unique UX_tarifa_combo */
  SELECT
    id_tipo_camion, id_temporada, id_ruta, vigencia_desde, vigencia_hasta,
    prioridad, regla, moneda, monto_fijo, activo
  FROM (
    SELECT *,
      ROW_NUMBER() OVER (
        PARTITION BY id_tipo_camion, id_temporada, id_ruta, vigencia_desde, regla, prioridad
        ORDER BY monto_fijo DESC
      ) AS rn
    FROM src_raw
  ) x
  WHERE rn = 1
)
MERGE cfl.CFL_tarifa AS T
USING src AS S
ON  T.id_temporada   = S.id_temporada
AND T.id_tipo_camion = S.id_tipo_camion
AND T.id_ruta        = S.id_ruta
AND T.vigencia_desde = S.vigencia_desde
AND T.regla          = S.regla
AND T.prioridad      = S.prioridad
WHEN MATCHED THEN
  UPDATE SET
    T.monto_fijo  = S.monto_fijo,
    T.activo      = 1,
    T.updated_at  = @now
WHEN NOT MATCHED THEN
  INSERT (id_tipo_camion, id_temporada, id_ruta, vigencia_desde, vigencia_hasta, prioridad, regla, moneda, monto_fijo, activo, created_at, updated_at)
  VALUES (S.id_tipo_camion, S.id_temporada, S.id_ruta, S.vigencia_desde, S.vigencia_hasta, S.prioridad, S.regla, S.moneda, S.monto_fijo, S.activo, @now, @now);


/* ============================================================
   13) TARIFAS TERMOS (63 filas, expandido)
   ============================================================ */
DECLARE @TarifasTermo TABLE(
  origen nvarchar(200),
  destino nvarchar(200),
  distancia_km decimal(10,2),
  monto_chico decimal(18,2),
  monto_mediano decimal(18,2),
  monto_grande decimal(18,2)
);

INSERT INTO @TarifasTermo(origen,destino,distancia_km,monto_chico,monto_mediano,monto_grande)
VALUES
(N'Planta Placilla',N'Viveros Guillaume ( Uva Blanca )',18,110000,155000,200000),
(N'Planta Maipo',N'Paine',21,120000,170000,220000),
(N'Planta Placilla',N'San Fernando ( Pedehue )',22,120000,170000,220000),
(N'Planta Placilla',N'Cañadilla',22,120000,170000,220000),
(N'Planta Placilla',N'Santa Cruz',24,120000,170000,220000),
(N'Planta Los Angeles',N'Mulchen ( Claudio Sepulveda - Arrayan )',26,120000,170000,220000),
(N'Planta Los Angeles',N'Los Angeles ( Advanta - Agrifor Doña Luisa - El Durazno )',29,120000,170000,220000),
(N'Planta Placilla',N'Los Lingues',30,120000,170000,220000),
(N'Planta Placilla',N'Tinguiririca',32,130000,185000,240000),
(N'Planta Placilla',N'Agua Buena',32,130000,185000,240000),
(N'Planta Placilla',N'Roma',32,130000,185000,240000),
(N'Planta Placilla',N'Puente Negro',32,130000,185000,240000),
(N'Planta Placilla',N'Chepica',39,130000,188000,246000),
(N'Planta Los Angeles',N'Mulchén ( Entre Bosques - Quitralman - Greenwich Pile )',42,130000,188000,246000),
(N'Planta Placilla',N'Rosario',44,130000,188000,246000),
(N'Planta Placilla',N'Chimbarongo',44,130000,188000,246000),
(N'Planta Placilla',N'Teno',48,136000,197000,257000),
(N'Planta Placilla',N'Los Lirios',61,160000,213000,266000),
(N'Planta Placilla',N'Quinta de Tilcoco',62,160000,226000,292000),
(N'Planta Los Angeles',N'Cabrero',67,165000,241000,316000),
(N'Planta Placilla',N'Olivar',67,165000,241000,316000),
(N'Planta Placilla',N'Rancagua',69,177000,249000,321000),
(N'Planta Placilla',N'Curico',69,177000,249000,321000),
(N'Planta Placilla',N'Romeral',71,183000,260000,342000),
(N'Planta Placilla',N'Las Cabras',73,183000,260000,342000),
(N'Planta Placilla',N'Machalí',80,195000,269000,342000),
(N'Planta Placilla',N'Graneros',82,227000,300000,372000),
(N'Planta Placilla',N'Rauco',84,200000,291000,381000),
(N'Planta Maipo',N'Rengo ( Terrafrut )',90,212000,251000,289000),
(N'Planta Placilla',N'Molina',91,212000,251000,289000),
(N'Planta Placilla',N'Sagrada Familia',95,224000,296000,368000),
(N'Planta Placilla',N'Los Niches',112,247000,308000,368000),
(N'Planta Placilla',N'Paine',114,254000,316000,377000),
(N'Planta Placilla',N'Cumpeo',123,271000,324000,377000),
(N'Planta Placilla',N'Planta Maipo',125,271000,328000,385000),
(N'Planta Placilla',N'Lo Herrera',132,283000,339000,395000),
(N'Planta Placilla',N'Talca',135,295000,348000,400000),
(N'Planta Placilla',N'Talagante',140,295000,360000,424000),
(N'Planta Placilla',N'Villa Prat',142,301000,369000,436000),
(N'Planta Placilla',N'Santiago',147,312000,377000,442000),
(N'Planta Placilla',N'Rio Claro',148,312000,377000,442000),
(N'Planta Placilla',N'San Clemente',150,318000,380000,442000),
(N'Planta Placilla',N'Melipilla',150,318000,380000,442000),
(N'Planta Placilla',N'San Javier',151,318000,389000,459000),
(N'Planta Placilla',N'Doñihue - Planta Maipo ( Copello )',151,318000,389000,459000),
(N'Planta Placilla',N'Yerbas Buenas',173,360000,435000,509000),
(N'Planta Placilla',N'San Javier (interior)',175,360000,439000,518000),
(N'Planta Placilla',N'Melozal',182,377000,454000,530000),
(N'Planta Placilla',N'Linares',185,389000,467000,545000),
(N'Planta Placilla',N'Retiro',200,407000,490000,572000),
(N'Planta Placilla',N'Colbun',206,424000,512000,600000),
(N'Planta Placilla',N'Longavi',215,442000,539000,636000),
(N'Planta Los Angeles',N'Cauquenes',245,483000,595000,706000),
(N'Planta Los Angeles',N'San Javier',249,483000,595000,706000),
(N'Planta Los Angeles',N'Talca',282,560000,692000,824000),
(N'Planta Placilla',N'Cauquenes',287,560000,692000,824000),
(N'Planta Los Angeles',N'Panguipulli',288,560000,692000,824000),
(N'Planta Placilla',N'Chillan',312,612000,748000,883000),
(N'Planta Los Angeles',N'Futrono',350,666000,819000,972000),
(N'Planta Placilla',N'Planta Los Angeles',407,772000,943000,1113000),
(N'Planta Los Angeles',N'Pencahue',424,NULL,952000,NULL),
(N'Planta Placilla',N'Mulchén',440,836000,1048000,1260000),
(N'Planta Placilla',N'Panguipulli',690,1241000,1539000,1836000);

/* Inserta tarifas TERMO CHICO / MEDIANO / GRANDE */
/* Inserta tarifas TERMO CHICO / MEDIANO / GRANDE (DEDUP antes del MERGE) */
;WITH tt_norm AS (
  SELECT
    LTRIM(RTRIM(origen))  AS origen,
    LTRIM(RTRIM(destino)) AS destino,
    CAST(distancia_km AS decimal(10,2)) AS distancia_km,
    CAST(monto_chico   AS decimal(18,2)) AS monto_chico,
    CAST(monto_mediano AS decimal(18,2)) AS monto_mediano,
    CAST(monto_grande  AS decimal(18,2)) AS monto_grande
  FROM @TarifasTermo
),
tt_dedup AS (
  /* 1 fila por (origen,destino); si hay duplicados toma el mayor monto/distancia */
  SELECT
    origen, destino,
    MAX(distancia_km)   AS distancia_km,
    MAX(monto_chico)    AS monto_chico,
    MAX(monto_mediano)  AS monto_mediano,
    MAX(monto_grande)   AS monto_grande
  FROM tt_norm
  GROUP BY origen, destino
),
r AS (
  SELECT
    rt.id_ruta,
    t.monto_chico,
    t.monto_mediano,
    t.monto_grande
  FROM tt_dedup t
  JOIN cfl.CFL_nodo_logistico o ON o.nombre = t.origen
  JOIN cfl.CFL_nodo_logistico d ON d.nombre = t.destino
  JOIN cfl.CFL_ruta rt ON rt.id_origen_nodo = o.id_nodo AND rt.id_destino_nodo = d.id_nodo
),
src_raw AS (
  SELECT
    @id_tc_termo_chico AS id_tipo_camion, @id_temporada AS id_temporada, id_ruta,
    CAST('2025-08-25' AS date) AS vigencia_desde, CAST(NULL AS date) AS vigencia_hasta,
    1 AS prioridad, 'BASE' AS regla, 'CLP' AS moneda, monto_chico AS monto_fijo, 1 AS activo
  FROM r WHERE monto_chico IS NOT NULL

  UNION ALL
  SELECT
    @id_tc_termo_mediano, @id_temporada, id_ruta,
    CAST('2025-08-25' AS date), NULL,
    1, 'BASE', 'CLP', monto_mediano, 1
  FROM r WHERE monto_mediano IS NOT NULL

  UNION ALL
  SELECT
    @id_tc_termo_grande, @id_temporada, id_ruta,
    CAST('2025-08-25' AS date), NULL,
    1, 'BASE', 'CLP', monto_grande, 1
  FROM r WHERE monto_grande IS NOT NULL
),
src AS (
  /* 1 fila por la clave del unique UX_tarifa_combo */
  SELECT
    id_tipo_camion, id_temporada, id_ruta, vigencia_desde, vigencia_hasta,
    prioridad, regla, moneda, monto_fijo, activo
  FROM (
    SELECT *,
      ROW_NUMBER() OVER (
        PARTITION BY id_tipo_camion, id_temporada, id_ruta, vigencia_desde, regla, prioridad
        ORDER BY monto_fijo DESC
      ) AS rn
    FROM src_raw
  ) x
  WHERE rn = 1
)
MERGE cfl.CFL_tarifa AS T
USING src AS S
ON  T.id_temporada   = S.id_temporada
AND T.id_tipo_camion = S.id_tipo_camion
AND T.id_ruta        = S.id_ruta
AND T.vigencia_desde = S.vigencia_desde
AND T.regla          = S.regla
AND T.prioridad      = S.prioridad
WHEN MATCHED THEN
  UPDATE SET
    T.monto_fijo  = S.monto_fijo,
    T.activo      = 1,
    T.updated_at  = @now
WHEN NOT MATCHED THEN
  INSERT (id_tipo_camion, id_temporada, id_ruta, vigencia_desde, vigencia_hasta, prioridad, regla, moneda, monto_fijo, activo, created_at, updated_at)
  VALUES (S.id_tipo_camion, S.id_temporada, S.id_ruta, S.vigencia_desde, S.vigencia_hasta, S.prioridad, S.regla, S.moneda, S.monto_fijo, S.activo, @now, @now);


COMMIT TRAN;

/* ============================================================
   FIN SEED
   ============================================================ */
