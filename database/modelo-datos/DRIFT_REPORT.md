# Drift BD DBCFL vs UP.sql — 2026-04-14

**Base de datos:** DBCFL @ 192.168.8.24 · schema `[cfl]`
**Fuente UP.sql:** `cfl-infra/database/modelo-datos/UP.sql`

> Reporte read-only generado por comparación de INFORMATION_SCHEMA + sys.* vs parseo de UP.sql.

## Resumen ejecutivo

| Métrica | BD | UP.sql |
|---|---:|---:|
| Tablas | 52 | 52 |
| Vistas | 4 | 0 |
| FKs | 59 | 59 |
| Índices (no-PK) | 119 | 71 |

- **Tablas solo en UP.sql (faltan en BD):** 0
- **Tablas solo en BD (drift no-versionado):** 0
- **Tablas con diffs de columnas/tipos:** 2
- **Índices faltantes en BD:** 1 · **extra en BD:** 1
- **FKs faltantes en BD:** 1 · **extra en BD:** 1
- **Vistas faltantes:** 0 · **extra:** 4

## 1. Diff de schema

### 1.1 Tablas

OK — coincidencia total.

### 1.2 Vistas

**Vistas extra en BD:** `VW_LikpActual`, `VW_LipsActual`, `VW_RomanaCabeceraActual`, `VW_RomanaDetalleActual`

### 1.3 Columnas (diffs por tabla)

#### `SapLipsRaw`

- Extra en BD (no en UP): `SapLote`

#### `TokenBlocklist`

- Extra en BD (no en UP): `CreatedAt`, `ExpiresAt`, `IdUsuario`, `Jti`, `Motivo`

### 1.4 Índices

**Faltan en BD (declarados en UP):**

- `CabeceraFlete.IX_CabeceraFlete_IdEspecie`

**Extra en BD (no en UP):**

- `TokenBlocklist.IX_TokenBlocklist_ExpiresAt`

### 1.5 Foreign Keys

**Faltan en BD:**

- `CabeceraFlete.FK_CabeceraFlete_Especie`

**Extra en BD:**

- `CabeceraFlete.FK_CabeceraFlete_Especie_Cab`

## 2. Diff de seeds (tablas maestras)

> Se omiten tablas transaccionales (Sap/Romana raw, Cabecera/DetalleFlete, PlanillaSap, Auditoria, etc.). Comparación por clave de negocio (código o nombre).

### CentroCosto  —  `SapCodigo`  (OK)
- BD: 19 registros · Seed: 19

### CuentaMayor  —  `Codigo`  (OK)
- BD: 5 registros · Seed: 5

### DetalleViaje  —  `Descripcion`  (OK)
- BD: 92 registros · Seed: 92

### Especie  —  `Glosa`  (DIFF)
- BD: 25 registros · Seed: 24
- En BD, no en seed (todos): `CIRUELA EUROPEA`

### ImputacionFlete  —  `IdImputacionFlete`  (DIFF)
- BD: 22 registros · Seed: 0
- En BD, no en seed (todos): `1`, `10`, `11`, `12`, `13`, `14`, `15`, `16`, `17`, `18`, `19`, `2`, `20`, `21`, `22`, `3`, `4`, `5`, `6`, `7`, `8`, `9`

### NodoLogistico  —  `Nombre`  (DIFF)
- BD: 288 registros · Seed: 280
- En seed, ausentes en BD: `ADVANTA - AGRIFOR DOÑA LUISA - EL DURAZNO`, `AG II`, `AGR. MIARARIOS`, `AGRICOLA DOÑA CONSTANZA`, `AGROBUREO - MAYI MARTINEZ - SANTA BLANCA`, `AGRÍCOLA LA QUINTA - TERRASUR`, `AQUAGRO`, `CALVARÍ - LA PARRA`, `CANTARRANA`, `CASAS DEL ROMERAL`, `CASSACIA`, `CENTRO DE ARMADO`, `CERASUS`, `CLAUDIO SEPÚLVEDA - ARRAYÁN`, `COPELLO`, `DEL MONTE`, `DON VICENTE`, `EL BOLSICO`, `EL BOSQUE`, `EL COMINO`, `ENTRE BOSQUES - QUITRALMAN - GREENWICH PILE`, `F. HUECHUN`, `FCO ALEMAN`, `FLOR ORIENTE`, `FOR. EL PEUMO`, `FRUSAL`, `GREENEX`, `INTERIOR`, `LOS BRONCES`, `LOS NOSTROS`
- En BD, no en seed (muestra 30): `BUIN (EL COMINO)`, `CHILLÁN (AGROBUREO - MAYI MARTINEZ - SANTA BLANCA)`, `CHIMBARONGO (CASAS DEL ROMERAL)`, `CHIMBARONGO (CENFRUTAL)`, `CODEGUA (GREENEX)`, `COLTAUCO (CALVARÍ - LA PARRA)`, `COLTAUCO (LOS BRONCES)`, `CURICÓ (SUR)`, `CURICÓ (UAC)`, `DOÑIHUE - PLANTA MAIPO (COPELLO)`, `LA PALOMA (CERASUS)`, `LINARES (DON VICENTE)`, `LINARES (EL BOSQUE)`, `LINARES (FOR. EL PEUMO)`, `LINARES (INTERIOR)`, `LONGAVÍ (AGRÍCOLA LA QUINTA - TERRASUR)`, `LOS ANDES (AG II)`, `LOS LINGUES (FCO ALEMAN)`, `LOS ÁNGELES (ADVANTA - AGRIFOR DOÑA LUISA - EL DURAZNO))`, `LOS ÁNGELES (CANTARRANA)`, `LOS ÁNGELES (INTEGRITY)`, `MALLOA (FRUSAL)`, `MALLOA - PLANTA MAIPO (SANTA INÉS DE MALLOA)`, `MELIPILLA (MARIA PINTO)`, `MULCHÉN (CLAUDIO SEPÚLVEDA - ARRAYÁN)`, `MULCHÉN (ENTRE BOSQUES - QUITRALMAN - GREENWICH PILE)`, `NANCAGUA (LA CABRERIA)`, `PAINE (MULTIFRUTA)`, `PARRAL (AGR. MIARARIOS)`, `PARRAL (F. HUECHUN)`

### Permiso  —  `Clave`  (OK)
- BD: 33 registros · Seed: 33

### Rol  —  `Nombre`  (OK)
- BD: 3 registros · Seed: 3

### Temporada  —  `Nombre`  (OK)
- BD: 1 registros · Seed: 1

### TipoFlete  —  `SapCodigo`  (OK)
- BD: 6 registros · Seed: 6

## Anexo — Conteo por tabla maestra

| Tabla | Registros |
|---|---:|
| Rol | 3 |
| Permiso | 33 |
| RolPermiso | 71 |
| Temporada | 1 |
| CentroCosto | 19 |
| CuentaMayor | 5 |
| TipoFlete | 6 |
| TipoCamion | 10 |
| Especie | 25 |
| DetalleViaje | 92 |
| ImputacionFlete | 22 |
| NodoLogistico | 288 |
| Ruta | 190 |
| Tarifa | 544 |
| EmpresaTransporte | 82 |
| Chofer | 753 |
| Camion | 1014 |
| Movil | 19 |

## 3. Notas

- La detección de tipos usa equivalencias directas (int↔int, nvarchar↔nvarchar). No se comparan longitudes (`MAXLEN`) ni precisión para reducir ruido. Si necesitas ese nivel, consultar `INFORMATION_SCHEMA.COLUMNS` directamente.
- FKs e índices se comparan por nombre de constraint. Renombres manuales aparecerán como falso positivo en ambas listas.
- Los diffs de seed ignoran orden de inserción y columnas más allá de la clave de negocio (Código/Nombre).