/* ============================================================================
   ESQUEMA: cfl
   - Crea el esquema cfl (si no existe)
   - Crea tablas bajo [cfl].[*]
   - Crea índices (sin prefijo de esquema en el nombre del índice)
   - Crea FKs
   - Crea índices UNIQUE de deduplicación BK+hash (Línea A)
   - Crea vistas "current" (última versión por BK) apuntando a tablas reales
============================================================================ */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'cfl')
    EXEC('CREATE SCHEMA [cfl] AUTHORIZATION [dbo];');
GO

/* =========================
   TABLA: cfl.CFL_etl_run
========================= */
CREATE TABLE [cfl].[CFL_etl_run] (
    [run_id]        BIGINT IDENTITY UNIQUE,
    [execution_id]  UNIQUEIDENTIFIER NOT NULL UNIQUE,
    [source_system] VARCHAR(50) NOT NULL,
    [source_name]   VARCHAR(100) NOT NULL,
    [extracted_at]  DATETIME2(0) NOT NULL,
    [watermark_from] DATETIME2(0),
    [watermark_to]   DATETIME2(0),
    [status]        VARCHAR(20) NOT NULL,
    [rows_extracted] INT,
    [rows_inserted]  INT,
    [rows_updated]   INT,
    [rows_unchanged] INT,
    [error_message] NVARCHAR(4000),
    [created_at]    DATETIME2(0) NOT NULL,
    PRIMARY KEY ([run_id])
);
GO

/* =========================
   TABLA: cfl.CFL_sap_likp_raw
========================= */
CREATE TABLE [cfl].[CFL_sap_likp_raw] (
    [raw_id] BIGINT IDENTITY UNIQUE,
    [execution_id] UNIQUEIDENTIFIER NOT NULL,
    [extracted_at] DATETIME2(0) NOT NULL,
    [source_system] VARCHAR(50) NOT NULL,
    [row_hash] BINARY(32) NOT NULL,
    [row_status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(0) NOT NULL,

    [sap_numero_entrega] VARCHAR(20) NOT NULL,
    [sap_referencia] CHAR(25) NOT NULL,
    [sap_puesto_expedicion] CHAR(4) NOT NULL,
    [sap_organizacion_ventas] CHAR(4) NOT NULL,
    [sap_creado_por] CHAR(12) NOT NULL,
    [sap_fecha_creacion] DATE NOT NULL,
    [sap_clase_entrega] CHAR(4) NOT NULL,
    [sap_tipo_entrega] VARCHAR(20) NOT NULL,
    [sap_fecha_carga] DATE NOT NULL,
    [sap_hora_carga] TIME NOT NULL,
    [sap_guia_remision] CHAR(25) NOT NULL,
    [sap_nombre_chofer] VARCHAR(40) NOT NULL,
    [sap_id_fiscal_chofer] VARCHAR(20) NOT NULL,
    [sap_empresa_transporte] CHAR(3) NOT NULL,
    [sap_patente] VARCHAR(20) NOT NULL,
    [sap_carro] VARCHAR(20) NOT NULL,
    [sap_fecha_salida] DATE NOT NULL,
    [sap_hora_salida] TIME NOT NULL,
    [sap_codigo_tipo_flete] CHAR(4) NOT NULL,
    [sap_centro_costo] CHAR(10),
    [sap_cuenta_mayor] CHAR(10),
    [sap_peso_total] DECIMAL(15,3) NOT NULL,
    [sap_peso_neto] DECIMAL(15,3) NOT NULL,
    [sap_fecha_entrega_real] DATE NOT NULL,

    PRIMARY KEY ([raw_id])
);
GO

CREATE INDEX [IX_likp_execution]
ON [cfl].[CFL_sap_likp_raw] ([execution_id]);
GO

-- Índice soporte para vista "current" (BK + extracted_at)
CREATE INDEX [CFL_sap_likp_raw_index_1]
ON [cfl].[CFL_sap_likp_raw] ([source_system], [sap_numero_entrega], [extracted_at]);
GO

/* =========================
   TABLA: cfl.CFL_sap_lips_raw
========================= */
CREATE TABLE [cfl].[CFL_sap_lips_raw] (
    [raw_id] BIGINT IDENTITY UNIQUE,
    [execution_id] UNIQUEIDENTIFIER NOT NULL,
    [extracted_at] DATETIME2(0) NOT NULL,
    [source_system] VARCHAR(50) NOT NULL,
    [row_hash] BINARY(32) NOT NULL,
    [row_status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(0) NOT NULL,

    [sap_numero_entrega] VARCHAR(20) NOT NULL,
    [sap_posicion] CHAR(6) NOT NULL,
    [sap_material] VARCHAR(40) NOT NULL,
    [sap_cantidad_entregada] DECIMAL(13,3) NOT NULL,
    [sap_unidad_peso] CHAR(3) NOT NULL,
    [sap_denominacion_material] VARCHAR(40) NOT NULL,
    [sap_centro] CHAR(4) NOT NULL,
    [sap_almacen] CHAR(4) NOT NULL,
    [sap_posicion_superior] CHAR(6) NULL,   -- 09-02-2026: Se agrega para soportar detalles extendidos -> UEPOS
    [sap_lote] VARCHAR(20) NULL,            -- CHARG (10 en SAP; 20 por seguridad)

    PRIMARY KEY ([raw_id])
);
GO

CREATE INDEX [IX_lips_execution]
ON [cfl].[CFL_sap_lips_raw] ([execution_id]);
GO

-- Índice soporte para vista "current" (BK + extracted_at)
CREATE INDEX [CFL_sap_lips_raw_index_1]
ON [cfl].[CFL_sap_lips_raw] ([source_system], [sap_numero_entrega], [sap_posicion], [extracted_at]);
GO

CREATE INDEX [IX_lips_vbeln_uepos]
ON [cfl].[CFL_sap_lips_raw] ([source_system], [sap_numero_entrega], [sap_posicion_superior]);
GO

/* =========================
   TABLA: cfl.CFL_sap_partner_raw
========================= */
CREATE TABLE [cfl].[CFL_sap_partner_raw] (
    [raw_id] BIGINT IDENTITY UNIQUE,
    [execution_id] UNIQUEIDENTIFIER NOT NULL,
    [extracted_at] DATETIME2(0) NOT NULL,
    [source_system] VARCHAR(50) NOT NULL,
    [row_hash] BINARY(32) NOT NULL,
    [row_status] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(0) NOT NULL,

    [sap_numero_entrega] VARCHAR(20) NOT NULL,
    [sap_funcion_interlocutor] CHAR(4) NOT NULL,
    [sap_partner_ext] VARCHAR(60) NOT NULL,
    [sap_partner_nombre] VARCHAR(40) NOT NULL,
    [sap_partner_calle] VARCHAR(60) NOT NULL,
    [sap_partner_ciudad] VARCHAR(40) NOT NULL,

    PRIMARY KEY ([raw_id])
);
GO

CREATE INDEX [IX_partner_execution]
ON [cfl].[CFL_sap_partner_raw] ([execution_id]);
GO

-- Índice soporte para vista "current" (BK + extracted_at)
CREATE INDEX [CFL_sap_partner_raw_index_1]
ON [cfl].[CFL_sap_partner_raw] ([source_system], [sap_numero_entrega], [sap_funcion_interlocutor], [extracted_at]);
GO

/* =========================
   TABLA: cfl.CFL_sap_entrega
========================= */
CREATE TABLE [cfl].[CFL_sap_entrega] (
    [id_sap_entrega] BIGINT NOT NULL IDENTITY UNIQUE,
    [sap_numero_entrega] VARCHAR(20) NOT NULL,
    [source_system] VARCHAR(50) NOT NULL,
    [created_at] DATETIME2(0) NOT NULL,
    [updated_at] DATETIME2(0) NOT NULL,

    [locked] BIT NOT NULL CONSTRAINT [DF_CFL_sap_entrega_locked] DEFAULT(0),
    [locked_at] DATETIME2(0) NULL,

    [changed_in_last_run] BIT NOT NULL CONSTRAINT [DF_CFL_sap_entrega_changed_in_last_run] DEFAULT(0),
    [last_change_at] DATETIME2(0) NULL,
    [last_change_type] VARCHAR(20) NULL,

    [last_seen_execution_id] UNIQUEIDENTIFIER NULL,
    [last_seen_at] DATETIME2(0) NULL,

    [last_change_execution_id] UNIQUEIDENTIFIER NULL,
    [last_change_extracted_at] DATETIME2(0) NULL,

    [last_raw_likp_id] BIGINT NULL,
    [last_raw_likp_hash] BINARY(32) NULL,
    PRIMARY KEY ([id_sap_entrega])
);
GO

CREATE UNIQUE INDEX [UX_sap_entrega_bk]
ON [cfl].[CFL_sap_entrega] ([sap_numero_entrega], [source_system]);
GO

CREATE INDEX [IX_sap_entrega_vbeln]
ON [cfl].[CFL_sap_entrega] ([sap_numero_entrega]);
GO

/* =========================
   TABLA: cfl.CFL_sap_entrega_hist
========================= */
CREATE TABLE [cfl].[CFL_sap_entrega_hist] (
    [id_sap_entrega_hist] BIGINT NOT NULL IDENTITY UNIQUE,
    [id_sap_entrega] BIGINT NOT NULL,
    [raw_likp_id] BIGINT NOT NULL,
    [execution_id] UNIQUEIDENTIFIER NOT NULL,
    [extracted_at] DATETIME2(0) NOT NULL,
    [created_at] DATETIME2(0) NOT NULL,
    PRIMARY KEY ([id_sap_entrega_hist])
);
GO

CREATE INDEX [IX_sap_entrega_hist_entrega]
ON [cfl].[CFL_sap_entrega_hist] ([id_sap_entrega]);
GO

CREATE UNIQUE INDEX [UX_sap_entrega_hist_raw_likp]
ON [cfl].[CFL_sap_entrega_hist] ([raw_likp_id]);
GO

/* =========================
   TABLA: cfl.CFL_sap_entrega_posicion
========================= */
CREATE TABLE [cfl].[CFL_sap_entrega_posicion] (
    [id_sap_entrega_posicion] BIGINT NOT NULL IDENTITY UNIQUE,
    [id_sap_entrega] BIGINT NOT NULL,
    [sap_posicion] CHAR(6) NOT NULL,
    [created_at] DATETIME2(0) NOT NULL,
    [updated_at] DATETIME2(0) NOT NULL,
    [status] VARCHAR(20) NOT NULL CONSTRAINT [DF_CFL_sap_entrega_pos_status] DEFAULT('ACTIVE'),
    [missing_since] DATETIME2(0) NULL,

    [changed_in_last_run] BIT NOT NULL CONSTRAINT [DF_CFL_sap_entrega_pos_changed_in_last_run] DEFAULT(0),
    [last_change_at] DATETIME2(0) NULL,
    [last_change_type] VARCHAR(20) NULL,

    [last_seen_execution_id] UNIQUEIDENTIFIER NULL,
    [last_seen_at] DATETIME2(0) NULL,

    [last_change_execution_id] UNIQUEIDENTIFIER NULL,
    [last_change_extracted_at] DATETIME2(0) NULL,

    [last_raw_lips_id] BIGINT NULL,
    [last_raw_lips_hash] BINARY(32) NULL,
    PRIMARY KEY ([id_sap_entrega_posicion])
);
GO

CREATE UNIQUE INDEX [UX_sap_entrega_pos_bk]
ON [cfl].[CFL_sap_entrega_posicion] ([id_sap_entrega], [sap_posicion]);
GO

/* =========================
   TABLA: cfl.CFL_sap_entrega_posicion_hist
========================= */
CREATE TABLE [cfl].[CFL_sap_entrega_posicion_hist] (
    [id_sap_entrega_posicion_hist] BIGINT NOT NULL IDENTITY UNIQUE,
    [id_sap_entrega_posicion] BIGINT NOT NULL,
    [raw_lips_id] BIGINT NOT NULL,
    [execution_id] UNIQUEIDENTIFIER NOT NULL,
    [extracted_at] DATETIME2(0) NOT NULL,
    [created_at] DATETIME2(0) NOT NULL,
    PRIMARY KEY ([id_sap_entrega_posicion_hist])
);
GO

CREATE UNIQUE INDEX [UX_sap_entrega_pos_hist_raw_lips]
ON [cfl].[CFL_sap_entrega_posicion_hist] ([raw_lips_id]);
GO

CREATE INDEX [CFL_sap_entrega_posicion_hist_index_1]
ON [cfl].[CFL_sap_entrega_posicion_hist] ([id_sap_entrega_posicion]);
GO

/* =========================
   TABLA: cfl.CFL_sap_entrega_interlocutor
========================= */
CREATE TABLE [cfl].[CFL_sap_entrega_interlocutor] (
    [id_sap_entrega_interlocutor] BIGINT NOT NULL IDENTITY UNIQUE,
    [id_sap_entrega] BIGINT NOT NULL,
    [sap_funcion_interlocutor] CHAR(4) NOT NULL,
    [created_at] DATETIME2(0) NOT NULL,
    [updated_at] DATETIME2(0) NOT NULL,
    PRIMARY KEY ([id_sap_entrega_interlocutor])
);
GO

CREATE UNIQUE INDEX [UX_sap_entrega_int_bk]
ON [cfl].[CFL_sap_entrega_interlocutor] ([id_sap_entrega], [sap_funcion_interlocutor]);
GO

/* =========================
   TABLA: cfl.CFL_sap_entrega_interlocutor_hist
========================= */
CREATE TABLE [cfl].[CFL_sap_entrega_interlocutor_hist] (
    [id_sap_entrega_interlocutor_hist] BIGINT NOT NULL IDENTITY UNIQUE,
    [id_sap_entrega_interlocutor] BIGINT NOT NULL,
    [raw_partner_id] BIGINT NOT NULL,
    [execution_id] UNIQUEIDENTIFIER NOT NULL,
    [extracted_at] DATETIME2(0) NOT NULL,
    [created_at] DATETIME2(0) NOT NULL,
    PRIMARY KEY ([id_sap_entrega_interlocutor_hist])
);
GO

CREATE UNIQUE INDEX [UX_sap_entrega_int_hist_raw_partner]
ON [cfl].[CFL_sap_entrega_interlocutor_hist] ([raw_partner_id]);
GO

/* =========================
   TABLAS: catálogo y operación
========================= */
CREATE TABLE [cfl].[CFL_temporada] (
    [id_temporada] BIGINT NOT NULL IDENTITY UNIQUE,
    [codigo] VARCHAR(20) NOT NULL,
    [nombre] VARCHAR(100) NOT NULL,
    [fecha_inicio] DATETIME2(0) NOT NULL,
    [fecha_fin] DATETIME2(0) NOT NULL,
    [activa] BIT NOT NULL,
    [cerrada] BIT NOT NULL,
    [fecha_cierre] DATETIME2(0),
    [id_usuario_cierre] BIGINT,
    [observacion_cierre] VARCHAR(200),
    [created_at] DATETIME2(0) NOT NULL,
    [updated_at] DATETIME2(0) NOT NULL,
    PRIMARY KEY ([id_temporada])
);
GO

CREATE UNIQUE INDEX [UX_temporada_codigo]
ON [cfl].[CFL_temporada] ([codigo]);
GO

CREATE TABLE [cfl].[CFL_centro_costo] (
    [id_centro_costo] BIGINT NOT NULL IDENTITY UNIQUE,
    [sap_codigo] VARCHAR(20) NOT NULL,
    [nombre] VARCHAR(100) NOT NULL,
    [activo] BIT NOT NULL,
    PRIMARY KEY ([id_centro_costo])
);
GO

CREATE UNIQUE INDEX [UX_cc_sap_codigo]
ON [cfl].[CFL_centro_costo] ([sap_codigo]);
GO

CREATE TABLE [cfl].[CFL_folio] (
    [id_folio] BIGINT NOT NULL IDENTITY UNIQUE,
    [id_usuario_cierre] BIGINT,
    [id_centro_costo] BIGINT NOT NULL,
    [id_temporada] BIGINT NOT NULL,
    [folio_numero] VARCHAR(30) NOT NULL,
    [periodo_desde] DATETIME2(0),
    [periodo_hasta] DATETIME2(0),
    [estado] VARCHAR(20) NOT NULL,
    [bloqueado] BIT NOT NULL,
    [fecha_cierre] DATETIME2(0),
    [resultado_cuadratura] VARCHAR(20),
    [resumen_cuadratura] VARCHAR(500),
    [created_at] DATETIME2(0) NOT NULL,
    [updated_at] DATETIME2(0) NOT NULL,
    PRIMARY KEY ([id_folio])
);
GO

CREATE UNIQUE INDEX [UX_folio_temporada_cc]
ON [cfl].[CFL_folio] ([id_temporada], [id_centro_costo], [folio_numero]);
GO

CREATE TABLE [cfl].[CFL_nodo_logistico] (
    [id_nodo] BIGINT NOT NULL IDENTITY UNIQUE,
    [nombre] VARCHAR(100) NOT NULL,
    [region] VARCHAR(50) NOT NULL,
    [comuna] VARCHAR(100) NOT NULL,
    [ciudad] VARCHAR(100) NOT NULL,
    [calle] VARCHAR(100) NOT NULL,
    [activo] BIT NOT NULL,
    PRIMARY KEY ([id_nodo])
);
GO

CREATE TABLE [cfl].[CFL_ruta] (
    [id_ruta] BIGINT NOT NULL IDENTITY UNIQUE,
    [id_origen_nodo] BIGINT NOT NULL,
    [id_destino_nodo] BIGINT NOT NULL,
    [nombre_ruta] VARCHAR(100) NOT NULL,
    [distancia_km] DECIMAL(10,2),
    [activo] BIT NOT NULL,
    [created_at] DATETIME2(0) NOT NULL,
    [updated_at] DATETIME2(0) NOT NULL,
    PRIMARY KEY ([id_ruta])
);
GO

CREATE UNIQUE INDEX [UX_ruta_origen_destino]
ON [cfl].[CFL_ruta] ([id_origen_nodo], [id_destino_nodo]);
GO

CREATE TABLE [cfl].[CFL_tipo_camion] (
    [id_tipo_camion] BIGINT NOT NULL IDENTITY UNIQUE,
    [nombre] VARCHAR(100) NOT NULL,
    [categoria] VARCHAR(20) NOT NULL,
    [capacidad_kg] DECIMAL(15,3) NOT NULL,
    [requiere_temperatura] BIT NOT NULL,
    [descripcion] VARCHAR(100),
    [activo] BIT NOT NULL,
    PRIMARY KEY ([id_tipo_camion])
);
GO

CREATE TABLE [cfl].[CFL_camion] (
    [id_camion] BIGINT NOT NULL IDENTITY UNIQUE,
    [id_tipo_camion] BIGINT NOT NULL,
    [sap_patente] VARCHAR(20) NOT NULL,
    [sap_carro] VARCHAR(20) NOT NULL,
    [activo] BIT NOT NULL,
    [created_at] DATETIME2(0) NOT NULL,
    [updated_at] DATETIME2(0) NOT NULL,
    PRIMARY KEY ([id_camion])
);
GO

CREATE UNIQUE INDEX [UX_camion_patente_carro]
ON [cfl].[CFL_camion] ([sap_patente], [sap_carro]);
GO

CREATE TABLE [cfl].[CFL_empresa_transporte] (
    [id_empresa] BIGINT NOT NULL IDENTITY UNIQUE,
    [sap_codigo] CHAR(3),
    [rut] VARCHAR(20) NOT NULL,
    [razon_social] VARCHAR(100),
    [nombre_rep] VARCHAR(100),
    [correo] VARCHAR(100),
    [telefono] VARCHAR(20),
    [activo] BIT NOT NULL,
    [created_at] DATETIME2(0) NOT NULL,
    [updated_at] DATETIME2(0) NOT NULL,
    PRIMARY KEY ([id_empresa])
);
GO

CREATE UNIQUE INDEX [UX_empresa_rut]
ON [cfl].[CFL_empresa_transporte] ([rut]);
GO

CREATE TABLE [cfl].[CFL_chofer] (
    [id_chofer] BIGINT NOT NULL IDENTITY UNIQUE,
    [sap_id_fiscal] VARCHAR(20) NOT NULL,
    [sap_nombre] VARCHAR(80) NOT NULL,
    [telefono] VARCHAR(20),
    [activo] BIT NOT NULL,
    PRIMARY KEY ([id_chofer])
);
GO

CREATE UNIQUE INDEX [UX_chofer_id_fiscal]
ON [cfl].[CFL_chofer] ([sap_id_fiscal]);
GO

CREATE TABLE [cfl].[CFL_movil] (
    [id_movil] BIGINT NOT NULL IDENTITY UNIQUE,
    [id_chofer] BIGINT NOT NULL,
    [id_empresa_transporte] BIGINT NOT NULL,
    [id_camion] BIGINT NOT NULL,
    [activo] BIT NOT NULL,
    [created_at] DATETIME2(0) NOT NULL,
    [updated_at] DATETIME2(0) NOT NULL,
    PRIMARY KEY ([id_movil])
);
GO

CREATE UNIQUE INDEX [UX_movil_combo]
ON [cfl].[CFL_movil] ([id_empresa_transporte], [id_chofer], [id_camion]);
GO

CREATE TABLE [cfl].[CFL_detalle_viaje] (
    [id_detalle_viaje] BIGINT NOT NULL IDENTITY UNIQUE,
    [descripcion] VARCHAR(200) NOT NULL,
    [observacion] VARCHAR(100),
    [activo] BIT NOT NULL,
    PRIMARY KEY ([id_detalle_viaje])
);
GO

CREATE TABLE [cfl].[CFL_tipo_flete] (
    [id_tipo_flete] BIGINT NOT NULL IDENTITY UNIQUE,
    [sap_codigo] VARCHAR(20) NOT NULL,
    [nombre] VARCHAR(100) NOT NULL,
    [activo] BIT NOT NULL,
    [id_centro_costo] BIGINT NOT NULL,
    PRIMARY KEY ([id_tipo_flete])
);
GO

CREATE UNIQUE INDEX [UX_tipo_flete_sap]
ON [cfl].[CFL_tipo_flete] ([sap_codigo]);
GO

CREATE TABLE [cfl].[CFL_tarifa] (
    [id_tarifa] BIGINT NOT NULL IDENTITY UNIQUE,
    [id_tipo_camion] BIGINT NOT NULL,
    [id_temporada] BIGINT NOT NULL,
    [id_ruta] BIGINT NOT NULL,
    [vigencia_desde] DATE NOT NULL,
    [vigencia_hasta] DATE,
    [prioridad] INT NOT NULL,
    [regla] VARCHAR(50) NOT NULL,
    [moneda] CHAR(3) NOT NULL,
    [monto_fijo] DECIMAL(18,2) NOT NULL,
    [activo] BIT NOT NULL,
    [created_at] DATETIME2(0) NOT NULL,
    [updated_at] DATETIME2(0) NOT NULL,
    PRIMARY KEY ([id_tarifa])
);
GO

CREATE UNIQUE INDEX [UX_tarifa_combo]
ON [cfl].[CFL_tarifa] ([id_temporada], [id_tipo_camion], [id_ruta], [vigencia_desde], [regla], [prioridad]);
GO

CREATE TABLE [cfl].[CFL_especie] (
    [id_especie] BIGINT NOT NULL IDENTITY UNIQUE,
    [glosa] VARCHAR(50) NOT NULL,
    PRIMARY KEY ([id_especie])
);
GO

CREATE UNIQUE INDEX [UX_especie_glosa]
ON [cfl].[CFL_especie] ([glosa]);
GO

CREATE TABLE [cfl].[CFL_cabecera_flete] (
    [id_cabecera_flete] BIGINT NOT NULL IDENTITY UNIQUE,
    [id_detalle_viaje] BIGINT,
    [id_folio] BIGINT,
    [sap_numero_entrega_sugerido] VARCHAR(20),
    [sap_codigo_tipo_flete_sugerido] CHAR(4),
    [sap_centro_costo_sugerido] CHAR(10),
    [sap_cuenta_mayor_sugerida] CHAR(10),
    [cuenta_mayor_final] CHAR(10),
    [tipo_movimiento] VARCHAR(4) NOT NULL,
    [estado] VARCHAR(20) NOT NULL,
    [fecha_salida] DATE NOT NULL,
    [hora_salida] TIME NOT NULL,
    [monto_aplicado] DECIMAL(18,2) NOT NULL,
    [id_movil] BIGINT,
    [id_tarifa] BIGINT,
    [observaciones] VARCHAR(200),
    [id_usuario_creador] BIGINT,
    [id_tipo_flete] BIGINT NOT NULL,
    [created_at] DATETIME2(0) NOT NULL,
    [updated_at] DATETIME2(0) NOT NULL,
    [id_centro_costo_final] BIGINT NOT NULL,
    PRIMARY KEY ([id_cabecera_flete]),
    CONSTRAINT [CK_CFL_cabecera_flete_tipo_movimiento] CHECK ([tipo_movimiento] IN ('PUSH','PULL'))
);
GO

CREATE INDEX [IX_flete_folio_estado]
ON [cfl].[CFL_cabecera_flete] ([id_folio], [estado]);
GO

CREATE TABLE [cfl].[CFL_detalle_flete] (
    [id_detalle_flete] BIGINT NOT NULL IDENTITY UNIQUE,
    [id_cabecera_flete] BIGINT NOT NULL,
    [id_especie] BIGINT,
    [material] VARCHAR(50),
    [descripcion] VARCHAR(100),
    [cantidad] DECIMAL(12,2),
    [unidad] CHAR(3),
    [peso] DECIMAL(15,3),
    [created_at] DATETIME2(0) NOT NULL,
    PRIMARY KEY ([id_detalle_flete])
);
GO

CREATE TABLE [cfl].[CFL_flete_estado_historial] (
    [id_flete_estado_historial] BIGINT NOT NULL IDENTITY UNIQUE,
    [id_cabecera_flete] BIGINT NOT NULL,
    [estado] VARCHAR(20) NOT NULL,
    [fecha_hora] DATETIME2(0) NOT NULL,
    [id_usuario] BIGINT NOT NULL,
    [motivo] VARCHAR(200),
    [evidencia_ref] VARCHAR(100),
    PRIMARY KEY ([id_flete_estado_historial])
);
GO

CREATE TABLE [cfl].[CFL_cabecera_factura] (
    [id_factura] BIGINT NOT NULL IDENTITY UNIQUE,
    [id_folio] BIGINT NOT NULL,
    [id_empresa] BIGINT NOT NULL,
    [numero_factura] VARCHAR(40) NOT NULL,
    [fecha_emision] DATETIME2(0) NOT NULL,
    [moneda] CHAR(3) NOT NULL,
    [monto_neto] DECIMAL(18,2) NOT NULL,
    [monto_iva] DECIMAL(18,2) NOT NULL,
    [monto_total] DECIMAL(18,2) NOT NULL,
    [estado] VARCHAR(20) NOT NULL,
    [ruta_xml] VARCHAR(255),
    [ruta_pdf] VARCHAR(255),
    [created_at] DATETIME2(0) NOT NULL,
    [updated_at] DATETIME2(0) NOT NULL,
    PRIMARY KEY ([id_factura])
);
GO

CREATE UNIQUE INDEX [UX_factura_empresa_numero]
ON [cfl].[CFL_cabecera_factura] ([id_empresa], [numero_factura]);
GO

CREATE TABLE [cfl].[CFL_detalle_factura] (
    [id_factura_detalle] BIGINT NOT NULL IDENTITY UNIQUE,
    [id_factura] BIGINT NOT NULL,
    [monto_linea] DECIMAL(18,2),
    [detalle] VARCHAR(200),
    PRIMARY KEY ([id_factura_detalle])
);
GO

CREATE TABLE [cfl].[CFL_conciliacion_factura_flete] (
    [id_conciliacion] BIGINT NOT NULL IDENTITY UNIQUE,
    [id_factura] BIGINT NOT NULL,
    [id_cabecera_flete] BIGINT NOT NULL,
    [monto_asignado] DECIMAL(18,2) NOT NULL,
    [diferencia] DECIMAL(18,2) NOT NULL,
    [tolerancia_aplicada] DECIMAL(18,2) NOT NULL,
    [estado] VARCHAR(20) NOT NULL,
    [observacion] VARCHAR(300),
    [created_at] DATETIME2(0) NOT NULL,
    [updated_at] DATETIME2(0) NOT NULL,
    PRIMARY KEY ([id_conciliacion])
);
GO

CREATE UNIQUE INDEX [UX_conciliacion_factura_flete]
ON [cfl].[CFL_conciliacion_factura_flete] ([id_factura], [id_cabecera_flete]);
GO

CREATE TABLE [cfl].[CFL_flete_sap_entrega] (
    [id_flete_sap_entrega] BIGINT NOT NULL IDENTITY UNIQUE,
    [id_cabecera_flete] BIGINT NOT NULL,
    [id_sap_entrega] BIGINT NOT NULL,
    [origen_datos] VARCHAR(10) NOT NULL,
    [tipo_relacion] VARCHAR(20) NOT NULL,
    [created_at] DATETIME2(0) NOT NULL,
    [created_by] BIGINT,
    PRIMARY KEY ([id_flete_sap_entrega])
);
GO

CREATE UNIQUE INDEX [UX_flete_entrega_bridge]
ON [cfl].[CFL_flete_sap_entrega] ([id_cabecera_flete], [id_sap_entrega]);
GO

CREATE TABLE [cfl].[CFL_usuario] (
    [id_usuario] BIGINT IDENTITY UNIQUE,
    [username] VARCHAR(60) NOT NULL,
    [email] VARCHAR(200) NOT NULL,
    [password_hash] VARCHAR(255) NOT NULL,
    [nombre] VARCHAR(100),
    [apellido] VARCHAR(100),
    [activo] BIT NOT NULL,
    [ultimo_login] DATETIME2(0),
    [created_at] DATETIME2(0) NOT NULL,
    [updated_at] DATETIME2(0) NOT NULL,
    PRIMARY KEY ([id_usuario])
);
GO

CREATE UNIQUE INDEX [UX_usuario_username]
ON [cfl].[CFL_usuario] ([username]);
GO

CREATE UNIQUE INDEX [UX_usuario_email]
ON [cfl].[CFL_usuario] ([email]);
GO

CREATE TABLE [cfl].[CFL_rol] (
    [id_rol] BIGINT NOT NULL IDENTITY UNIQUE,
    [nombre] VARCHAR(50) NOT NULL,
    [descripcion] VARCHAR(100),
    [activo] BIT NOT NULL,
    PRIMARY KEY ([id_rol])
);
GO

CREATE UNIQUE INDEX [UX_rol_nombre]
ON [cfl].[CFL_rol] ([nombre]);
GO

CREATE TABLE [cfl].[CFL_permiso] (
    [id_permiso] BIGINT NOT NULL IDENTITY UNIQUE,
    [recurso] VARCHAR(100) NOT NULL,
    [accion] VARCHAR(20) NOT NULL,
    [clave] VARCHAR(50) NOT NULL,
    [descripcion] VARCHAR(100),
    [activo] BIT NOT NULL,
    PRIMARY KEY ([id_permiso])
);
GO

CREATE UNIQUE INDEX [UX_permiso_clave]
ON [cfl].[CFL_permiso] ([clave]);
GO

CREATE TABLE [cfl].[CFL_usuario_rol] (
    [id_usuario_rol] BIGINT NOT NULL IDENTITY UNIQUE,
    [id_usuario] BIGINT NOT NULL,
    [id_rol] BIGINT NOT NULL,
    PRIMARY KEY ([id_usuario_rol])
);
GO

CREATE UNIQUE INDEX [UX_usuario_rol]
ON [cfl].[CFL_usuario_rol] ([id_usuario], [id_rol]);
GO

CREATE TABLE [cfl].[CFL_rol_permiso] (
    [id_rol_permiso] BIGINT NOT NULL IDENTITY UNIQUE,
    [id_rol] BIGINT NOT NULL,
    [id_permiso] BIGINT NOT NULL,
    PRIMARY KEY ([id_rol_permiso])
);
GO

CREATE UNIQUE INDEX [UX_rol_permiso]
ON [cfl].[CFL_rol_permiso] ([id_rol], [id_permiso]);
GO

CREATE TABLE [cfl].[CFL_auditoria] (
    [id_auditoria] BIGINT NOT NULL IDENTITY UNIQUE,
    [id_usuario] BIGINT NOT NULL,
    [fecha_hora] DATETIME2(0) NOT NULL,
    [accion] VARCHAR(50) NOT NULL,
    [entidad] VARCHAR(100) NOT NULL,
    [id_entidad] VARCHAR(50),
    [resumen] VARCHAR(300),
    [ip_equipo] VARCHAR(50),
    PRIMARY KEY ([id_auditoria])
);
GO

/* =========================
   FOREIGN KEYS (con nombres)
========================= */
ALTER TABLE [cfl].[CFL_sap_likp_raw]
ADD CONSTRAINT [FK_CFL_sap_likp_raw_execution_id_CFL_etl_run]
FOREIGN KEY ([execution_id]) REFERENCES [cfl].[CFL_etl_run] ([execution_id])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_sap_lips_raw]
ADD CONSTRAINT [FK_CFL_sap_lips_raw_execution_id_CFL_etl_run]
FOREIGN KEY ([execution_id]) REFERENCES [cfl].[CFL_etl_run] ([execution_id])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_sap_partner_raw]
ADD CONSTRAINT [FK_CFL_sap_partner_raw_execution_id_CFL_etl_run]
FOREIGN KEY ([execution_id]) REFERENCES [cfl].[CFL_etl_run] ([execution_id])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_sap_entrega_hist]
ADD CONSTRAINT [FK_CFL_sap_entrega_hist_id_sap_entrega_CFL_sap_entrega]
FOREIGN KEY ([id_sap_entrega]) REFERENCES [cfl].[CFL_sap_entrega] ([id_sap_entrega])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_sap_entrega_hist]
ADD CONSTRAINT [FK_CFL_sap_entrega_hist_raw_likp_id_CFL_sap_likp_raw]
FOREIGN KEY ([raw_likp_id]) REFERENCES [cfl].[CFL_sap_likp_raw] ([raw_id])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_sap_entrega_posicion]
ADD CONSTRAINT [FK_CFL_sap_entrega_posicion_id_sap_entrega_CFL_sap_entrega]
FOREIGN KEY ([id_sap_entrega]) REFERENCES [cfl].[CFL_sap_entrega] ([id_sap_entrega])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_sap_entrega_posicion_hist]
ADD CONSTRAINT [FK_CFL_sap_entrega_posicion_hist_id_sap_entrega_posicion_CFL_sap_entrega_posicion]
FOREIGN KEY ([id_sap_entrega_posicion]) REFERENCES [cfl].[CFL_sap_entrega_posicion] ([id_sap_entrega_posicion])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_sap_entrega_posicion_hist]
ADD CONSTRAINT [FK_CFL_sap_entrega_posicion_hist_raw_lips_id_CFL_sap_lips_raw]
FOREIGN KEY ([raw_lips_id]) REFERENCES [cfl].[CFL_sap_lips_raw] ([raw_id])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_sap_entrega_interlocutor]
ADD CONSTRAINT [FK_CFL_sap_entrega_interlocutor_id_sap_entrega_CFL_sap_entrega]
FOREIGN KEY ([id_sap_entrega]) REFERENCES [cfl].[CFL_sap_entrega] ([id_sap_entrega])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_sap_entrega_interlocutor_hist]
ADD CONSTRAINT [FK_CFL_sap_entrega_interlocutor_hist_id_sap_entrega_interlocutor_CFL_sap_entrega_interlocutor]
FOREIGN KEY ([id_sap_entrega_interlocutor]) REFERENCES [cfl].[CFL_sap_entrega_interlocutor] ([id_sap_entrega_interlocutor])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_sap_entrega_interlocutor_hist]
ADD CONSTRAINT [FK_CFL_sap_entrega_interlocutor_hist_raw_partner_id_CFL_sap_partner_raw]
FOREIGN KEY ([raw_partner_id]) REFERENCES [cfl].[CFL_sap_partner_raw] ([raw_id])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_folio]
ADD CONSTRAINT [FK_CFL_folio_id_centro_costo_CFL_centro_costo]
FOREIGN KEY ([id_centro_costo]) REFERENCES [cfl].[CFL_centro_costo] ([id_centro_costo])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_folio]
ADD CONSTRAINT [FK_CFL_folio_id_temporada_CFL_temporada]
FOREIGN KEY ([id_temporada]) REFERENCES [cfl].[CFL_temporada] ([id_temporada])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_ruta]
ADD CONSTRAINT [FK_CFL_ruta_id_origen_nodo_CFL_nodo_logistico]
FOREIGN KEY ([id_origen_nodo]) REFERENCES [cfl].[CFL_nodo_logistico] ([id_nodo])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_ruta]
ADD CONSTRAINT [FK_CFL_ruta_id_destino_nodo_CFL_nodo_logistico]
FOREIGN KEY ([id_destino_nodo]) REFERENCES [cfl].[CFL_nodo_logistico] ([id_nodo])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_camion]
ADD CONSTRAINT [FK_CFL_camion_id_tipo_camion_CFL_tipo_camion]
FOREIGN KEY ([id_tipo_camion]) REFERENCES [cfl].[CFL_tipo_camion] ([id_tipo_camion])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_movil]
ADD CONSTRAINT [FK_CFL_movil_id_camion_CFL_camion]
FOREIGN KEY ([id_camion]) REFERENCES [cfl].[CFL_camion] ([id_camion])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_movil]
ADD CONSTRAINT [FK_CFL_movil_id_chofer_CFL_chofer]
FOREIGN KEY ([id_chofer]) REFERENCES [cfl].[CFL_chofer] ([id_chofer])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_movil]
ADD CONSTRAINT [FK_CFL_movil_id_empresa_transporte_CFL_empresa_transporte]
FOREIGN KEY ([id_empresa_transporte]) REFERENCES [cfl].[CFL_empresa_transporte] ([id_empresa])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_tipo_flete]
ADD CONSTRAINT [FK_CFL_tipo_flete_id_centro_costo_CFL_centro_costo]
FOREIGN KEY ([id_centro_costo]) REFERENCES [cfl].[CFL_centro_costo] ([id_centro_costo])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_tarifa]
ADD CONSTRAINT [FK_CFL_tarifa_id_temporada_CFL_temporada]
FOREIGN KEY ([id_temporada]) REFERENCES [cfl].[CFL_temporada] ([id_temporada])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_tarifa]
ADD CONSTRAINT [FK_CFL_tarifa_id_ruta_CFL_ruta]
FOREIGN KEY ([id_ruta]) REFERENCES [cfl].[CFL_ruta] ([id_ruta])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_tarifa]
ADD CONSTRAINT [FK_CFL_tarifa_id_tipo_camion_CFL_tipo_camion]
FOREIGN KEY ([id_tipo_camion]) REFERENCES [cfl].[CFL_tipo_camion] ([id_tipo_camion])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_cabecera_flete]
ADD CONSTRAINT [FK_CFL_cabecera_flete_id_folio_CFL_folio]
FOREIGN KEY ([id_folio]) REFERENCES [cfl].[CFL_folio] ([id_folio])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_cabecera_flete]
ADD CONSTRAINT [FK_CFL_cabecera_flete_id_tipo_flete_CFL_tipo_flete]
FOREIGN KEY ([id_tipo_flete]) REFERENCES [cfl].[CFL_tipo_flete] ([id_tipo_flete])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_cabecera_flete]
ADD CONSTRAINT [FK_CFL_cabecera_flete_id_detalle_viaje_CFL_detalle_viaje]
FOREIGN KEY ([id_detalle_viaje]) REFERENCES [cfl].[CFL_detalle_viaje] ([id_detalle_viaje])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_cabecera_flete]
ADD CONSTRAINT [FK_CFL_cabecera_flete_id_movil_CFL_movil]
FOREIGN KEY ([id_movil]) REFERENCES [cfl].[CFL_movil] ([id_movil])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_cabecera_flete]
ADD CONSTRAINT [FK_CFL_cabecera_flete_id_tarifa_CFL_tarifa]
FOREIGN KEY ([id_tarifa]) REFERENCES [cfl].[CFL_tarifa] ([id_tarifa])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_detalle_flete]
ADD CONSTRAINT [FK_CFL_detalle_flete_id_cabecera_flete_CFL_cabecera_flete]
FOREIGN KEY ([id_cabecera_flete]) REFERENCES [cfl].[CFL_cabecera_flete] ([id_cabecera_flete])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_detalle_flete]
ADD CONSTRAINT [FK_CFL_detalle_flete_id_especie_CFL_especie]
FOREIGN KEY ([id_especie]) REFERENCES [cfl].[CFL_especie] ([id_especie])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_flete_estado_historial]
ADD CONSTRAINT [FK_CFL_flete_estado_historial_id_cabecera_flete_CFL_cabecera_flete]
FOREIGN KEY ([id_cabecera_flete]) REFERENCES [cfl].[CFL_cabecera_flete] ([id_cabecera_flete])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_flete_estado_historial]
ADD CONSTRAINT [FK_CFL_flete_estado_historial_id_usuario_CFL_usuario]
FOREIGN KEY ([id_usuario]) REFERENCES [cfl].[CFL_usuario] ([id_usuario])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_cabecera_factura]
ADD CONSTRAINT [FK_CFL_cabecera_factura_id_folio_CFL_folio]
FOREIGN KEY ([id_folio]) REFERENCES [cfl].[CFL_folio] ([id_folio])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_cabecera_factura]
ADD CONSTRAINT [FK_CFL_cabecera_factura_id_empresa_CFL_empresa_transporte]
FOREIGN KEY ([id_empresa]) REFERENCES [cfl].[CFL_empresa_transporte] ([id_empresa])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_detalle_factura]
ADD CONSTRAINT [FK_CFL_detalle_factura_id_factura_CFL_cabecera_factura]
FOREIGN KEY ([id_factura]) REFERENCES [cfl].[CFL_cabecera_factura] ([id_factura])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_conciliacion_factura_flete]
ADD CONSTRAINT [FK_CFL_conciliacion_factura_flete_id_factura_CFL_cabecera_factura]
FOREIGN KEY ([id_factura]) REFERENCES [cfl].[CFL_cabecera_factura] ([id_factura])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_conciliacion_factura_flete]
ADD CONSTRAINT [FK_CFL_conciliacion_factura_flete_id_cabecera_flete_CFL_cabecera_flete]
FOREIGN KEY ([id_cabecera_flete]) REFERENCES [cfl].[CFL_cabecera_flete] ([id_cabecera_flete])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_flete_sap_entrega]
ADD CONSTRAINT [FK_CFL_flete_sap_entrega_id_cabecera_flete_CFL_cabecera_flete]
FOREIGN KEY ([id_cabecera_flete]) REFERENCES [cfl].[CFL_cabecera_flete] ([id_cabecera_flete])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_flete_sap_entrega]
ADD CONSTRAINT [FK_CFL_flete_sap_entrega_id_sap_entrega_CFL_sap_entrega]
FOREIGN KEY ([id_sap_entrega]) REFERENCES [cfl].[CFL_sap_entrega] ([id_sap_entrega])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_usuario_rol]
ADD CONSTRAINT [FK_CFL_usuario_rol_id_usuario_CFL_usuario]
FOREIGN KEY ([id_usuario]) REFERENCES [cfl].[CFL_usuario] ([id_usuario])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_usuario_rol]
ADD CONSTRAINT [FK_CFL_usuario_rol_id_rol_CFL_rol]
FOREIGN KEY ([id_rol]) REFERENCES [cfl].[CFL_rol] ([id_rol])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_rol_permiso]
ADD CONSTRAINT [FK_CFL_rol_permiso_id_rol_CFL_rol]
FOREIGN KEY ([id_rol]) REFERENCES [cfl].[CFL_rol] ([id_rol])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_rol_permiso]
ADD CONSTRAINT [FK_CFL_rol_permiso_id_permiso_CFL_permiso]
FOREIGN KEY ([id_permiso]) REFERENCES [cfl].[CFL_permiso] ([id_permiso])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_auditoria]
ADD CONSTRAINT [FK_CFL_auditoria_id_usuario_CFL_usuario]
FOREIGN KEY ([id_usuario]) REFERENCES [cfl].[CFL_usuario] ([id_usuario])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_temporada]
ADD CONSTRAINT [FK_CFL_temporada_id_usuario_cierre_CFL_usuario]
FOREIGN KEY ([id_usuario_cierre]) REFERENCES [cfl].[CFL_usuario] ([id_usuario])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_folio]
ADD CONSTRAINT [FK_CFL_folio_id_usuario_cierre_CFL_usuario]
FOREIGN KEY ([id_usuario_cierre]) REFERENCES [cfl].[CFL_usuario] ([id_usuario])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_cabecera_flete]
ADD CONSTRAINT [FK_CFL_cabecera_flete_id_usuario_creador_CFL_usuario]
FOREIGN KEY ([id_usuario_creador]) REFERENCES [cfl].[CFL_usuario] ([id_usuario])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_cabecera_flete]
ADD CONSTRAINT [FK_CFL_cabecera_flete_id_centro_costo_final_CFL_centro_costo]
FOREIGN KEY ([id_centro_costo_final]) REFERENCES [cfl].[CFL_centro_costo] ([id_centro_costo])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

ALTER TABLE [cfl].[CFL_flete_sap_entrega]
ADD CONSTRAINT [FK_CFL_flete_sap_entrega_created_by_CFL_usuario]
FOREIGN KEY ([created_by]) REFERENCES [cfl].[CFL_usuario] ([id_usuario])
ON UPDATE NO ACTION ON DELETE NO ACTION;
GO

/* =========================
   LÍNEA A: DEDUPE RAW (BK + hash) - UNIQUE
   UNIQUE (source_system, BK..., row_hash)
========================= */
CREATE UNIQUE INDEX [UX_likp_bk_hash]
ON [cfl].[CFL_sap_likp_raw] ([source_system], [sap_numero_entrega], [row_hash]);
GO

CREATE UNIQUE INDEX [UX_lips_bk_hash]
ON [cfl].[CFL_sap_lips_raw] ([source_system], [sap_numero_entrega], [sap_posicion], [row_hash]);
GO

CREATE UNIQUE INDEX [UX_partner_bk_hash]
ON [cfl].[CFL_sap_partner_raw] ([source_system], [sap_numero_entrega], [sap_funcion_interlocutor], [row_hash]);
GO

/* =========================
   VISTAS CURRENT (última versión por BK)
========================= */

/* =============================================================================
   CFL - Vistas CURRENT + AS_OF (LIKP + LIPS)
   - CURRENT: última versión por BK usando row_status='ACTIVE'
   - AS_OF: reconstrucción histórica por extracted_at <= @as_of_utc (NO usa row_status)
============================================================================= */

-- =========================================================
-- LIKP CURRENT
-- BK: (source_system, sap_numero_entrega)
-- =========================================================

CREATE OR ALTER VIEW [cfl].[vw_cfl_sap_likp_current]
AS
WITH ranked AS
(
    SELECT
        r.*,
        rn = ROW_NUMBER() OVER
        (
            PARTITION BY r.[source_system], r.[sap_numero_entrega]
            ORDER BY r.[extracted_at] DESC, r.[raw_id] DESC
        )
    FROM [cfl].[CFL_sap_likp_raw] r
    WHERE r.[row_status] = 'ACTIVE'
)
SELECT
    sap_numero_entrega,
    raw_id,
    extracted_at,
    row_hash,
    row_status,
    execution_id,
    source_system,
    created_at,

    sap_referencia,
    sap_puesto_expedicion,
    sap_organizacion_ventas,
    sap_creado_por,
    sap_fecha_creacion,
    sap_clase_entrega,
    sap_tipo_entrega,

    sap_fecha_carga,
    sap_hora_carga,
    sap_guia_remision,
    sap_nombre_chofer,
    sap_id_fiscal_chofer,
    sap_empresa_transporte,
    sap_patente,
    sap_carro,
    sap_fecha_salida,
    sap_hora_salida,
    sap_codigo_tipo_flete,

    sap_centro_costo,
    sap_cuenta_mayor,

    sap_peso_total,
    sap_peso_neto,
    sap_fecha_entrega_real
FROM ranked
WHERE rn = 1;
GO

-- =========================================================
-- LIPS CURRENT
-- BK: (source_system, sap_numero_entrega, sap_posicion)
-- =========================================================
CREATE OR ALTER VIEW [cfl].[vw_cfl_sap_lips_current]
AS
WITH ranked AS
(
    SELECT
        r.*,
        rn = ROW_NUMBER() OVER
        (
            PARTITION BY r.[source_system], r.[sap_numero_entrega], r.[sap_posicion]
            ORDER BY r.[extracted_at] DESC, r.[raw_id] DESC
        )
    FROM [cfl].[CFL_sap_lips_raw] r
    WHERE r.[row_status] = 'ACTIVE'
)
SELECT
    sap_numero_entrega,
    sap_posicion,
    sap_posicion_superior,
    sap_lote,

    raw_id,
    extracted_at,
    row_hash,
    row_status,
    execution_id,
    source_system,
    created_at,

    sap_material,
    sap_cantidad_entregada,
    sap_unidad_peso,
    sap_denominacion_material,
    sap_centro,
    sap_almacen
FROM ranked
WHERE rn = 1;
GO

-- =========================================================
-- LIKP AS_OF (parametrizado)
-- Reconstruye "vigente a fecha" por extracted_at <= @as_of_utc
-- =========================================================
CREATE OR ALTER FUNCTION [cfl].[fn_cfl_sap_likp_as_of]
(
    @as_of_utc DATETIME2(0)
)
RETURNS TABLE
AS
RETURN
WITH ranked AS
(
    SELECT
        r.*,
        rn = ROW_NUMBER() OVER
        (
            PARTITION BY r.[source_system], r.[sap_numero_entrega]
            ORDER BY r.[extracted_at] DESC, r.[raw_id] DESC
        )
    FROM [cfl].[CFL_sap_likp_raw] r
    WHERE r.[extracted_at] <= @as_of_utc
)
SELECT
    sap_numero_entrega,
    raw_id,
    extracted_at,
    row_hash,
    row_status,
    execution_id,
    source_system,
    created_at,

    sap_referencia,
    sap_puesto_expedicion,
    sap_organizacion_ventas,
    sap_creado_por,
    sap_fecha_creacion,
    sap_clase_entrega,
    sap_tipo_entrega,

    sap_fecha_carga,
    sap_hora_carga,
    sap_guia_remision,
    sap_nombre_chofer,
    sap_id_fiscal_chofer,
    sap_empresa_transporte,
    sap_patente,
    sap_carro,
    sap_fecha_salida,
    sap_hora_salida,
    sap_codigo_tipo_flete,

    sap_centro_costo,
    sap_cuenta_mayor,

    sap_peso_total,
    sap_peso_neto,
    sap_fecha_entrega_real
FROM ranked
WHERE rn = 1;
GO

-- =========================================================
-- LIPS AS_OF (parametrizado)
-- Reconstruye "vigente a fecha" por extracted_at <= @as_of_utc
-- =========================================================
CREATE OR ALTER FUNCTION [cfl].[fn_cfl_sap_lips_as_of]
(
    @as_of_utc DATETIME2(0)
)
RETURNS TABLE
AS
RETURN
WITH ranked AS
(
    SELECT
        r.*,
        rn = ROW_NUMBER() OVER
        (
            PARTITION BY r.[source_system], r.[sap_numero_entrega], r.[sap_posicion]
            ORDER BY r.[extracted_at] DESC, r.[raw_id] DESC
        )
    FROM [cfl].[CFL_sap_lips_raw] r
    WHERE r.[extracted_at] <= @as_of_utc
)
SELECT
    sap_numero_entrega,
    sap_posicion,
    sap_posicion_superior,
    sap_lote,

    raw_id,
    extracted_at,
    row_hash,
    row_status,
    execution_id,
    source_system,
    created_at,

    sap_material,
    sap_cantidad_entregada,
    sap_unidad_peso,
    sap_denominacion_material,
    sap_centro,
    sap_almacen
FROM ranked
WHERE rn = 1;
GO
