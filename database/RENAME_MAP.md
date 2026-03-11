# RENAME_MAP.md — Mapa de Renombrado CFL

> Documento de referencia para el refactoring de nomenclatura (normalización PascalCase + español).
> Generado: 2026-03-10.

---

## Convenciones aplicadas

| Elemento | Convención | Ejemplo |
|---|---|---|
| Prefijo de esquema | `cfl.` | `cfl.CabeceraFlete` |
| Nombre de tabla | `cfl.` + PascalCase singular | `cfl.EmpresaTransporte` |
| Nombre de columna | PascalCase singular | `IdEmpresaTransporte`, `FechaCreacion` |
| Restricciones PK | `PK_<NombreTabla>` | `PK_CabeceraFlete` |
| Restricciones FK | `FK_<Tabla>_<TablaReferenciada>` | `FK_CabeceraFlete_EmpresaTransporte` |
| Restricciones UNIQUE | `UQ_<Tabla>_<Columna>` | `UQ_Usuario_Email` |
| Índices | `IX_<Tabla>_<Columna>` | `IX_CabeceraFlete_Estado` |
| Vistas | `VW_<NombreVista>` | `VW_LikpActual` |
| Funciones | `Fn_<NombreFuncion>` | `Fn_LikpAPartirDe` |
| Idioma | Español | `FechaCreacion` no `CreatedAt` |

---

## Tablas

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `[cfl].[CFL_etl_run]` | `[cfl].[EtlEjecucion]` | Table |
| `[cfl].[CFL_sap_likp_raw]` | `[cfl].[SapLikpRaw]` | Table |
| `[cfl].[CFL_sap_lips_raw]` | `[cfl].[SapLipsRaw]` | Table |
| `[cfl].[CFL_sap_entrega]` | `[cfl].[SapEntrega]` | Table |
| `[cfl].[CFL_sap_entrega_hist]` | `[cfl].[SapEntregaHistorial]` | Table |
| `[cfl].[CFL_sap_entrega_posicion]` | `[cfl].[SapEntregaPosicion]` | Table |
| `[cfl].[CFL_sap_entrega_posicion_hist]` | `[cfl].[SapEntregaPosicionHistorial]` | Table |
| `[cfl].[CFL_sap_entrega_descarte]` | `[cfl].[SapEntregaDescarte]` | Table |
| `[cfl].[CFL_temporada]` | `[cfl].[Temporada]` | Table |
| `[cfl].[CFL_centro_costo]` | `[cfl].[CentroCosto]` | Table |
| `[cfl].[CFL_cuenta_mayor]` | `[cfl].[CuentaMayor]` | Table |
| `[cfl].[CFL_folio]` | `[cfl].[Folio]` | Table |
| `[cfl].[CFL_nodo_logistico]` | `[cfl].[NodoLogistico]` | Table |
| `[cfl].[CFL_ruta]` | `[cfl].[Ruta]` | Table |
| `[cfl].[CFL_tipo_camion]` | `[cfl].[TipoCamion]` | Table |
| `[cfl].[CFL_camion]` | `[cfl].[Camion]` | Table |
| `[cfl].[CFL_empresa_transporte]` | `[cfl].[EmpresaTransporte]` | Table |
| `[cfl].[CFL_chofer]` | `[cfl].[Chofer]` | Table |
| `[cfl].[CFL_movil]` | `[cfl].[Movil]` | Table |
| `[cfl].[CFL_detalle_viaje]` | `[cfl].[DetalleViaje]` | Table |
| `[cfl].[CFL_tipo_flete]` | `[cfl].[TipoFlete]` | Table |
| `[cfl].[CFL_tarifa]` | `[cfl].[Tarifa]` | Table |
| `[cfl].[CFL_especie]` | `[cfl].[Especie]` | Table |
| `[cfl].[CFL_cabecera_flete]` | `[cfl].[CabeceraFlete]` | Table |
| `[cfl].[CFL_detalle_flete]` | `[cfl].[DetalleFlete]` | Table |
| `[cfl].[CFL_flete_estado_historial]` | `[cfl].[FleteEstadoHistorial]` | Table |
| `[cfl].[CFL_cabecera_factura]` | `[cfl].[CabeceraFactura]` | Table |
| `[cfl].[CFL_detalle_factura]` | `[cfl].[DetalleFactura]` | Table |
| `[cfl].[CFL_conciliacion_factura_flete]` | `[cfl].[ConciliacionFacturaFlete]` | Table |
| `[cfl].[CFL_flete_sap_entrega]` | `[cfl].[FleteSapEntrega]` | Table |
| `[cfl].[CFL_usuario]` | `[cfl].[Usuario]` | Table |
| `[cfl].[CFL_rol]` | `[cfl].[Rol]` | Table |
| `[cfl].[CFL_permiso]` | `[cfl].[Permiso]` | Table |
| `[cfl].[CFL_usuario_rol]` | `[cfl].[UsuarioRol]` | Table |
| `[cfl].[CFL_rol_permiso]` | `[cfl].[RolPermiso]` | Table |
| `[cfl].[CFL_auditoria]` | `[cfl].[Auditoria]` | Table |

---

## Vistas y Funciones

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `[cfl].[vw_cfl_sap_likp_current]` | `[cfl].[VW_LikpActual]` | View |
| `[cfl].[vw_cfl_sap_lips_current]` | `[cfl].[VW_LipsActual]` | View |
| `[cfl].[fn_cfl_sap_likp_as_of]` | `[cfl].[Fn_LikpAPartirDe]` | Function |
| `[cfl].[fn_cfl_sap_lips_as_of]` | `[cfl].[Fn_LipsAPartirDe]` | Function |

---

## Columnas — EtlEjecucion (ex CFL_etl_run)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `run_id` | `IdEtlEjecucion` | Column (PK) |
| `execution_id` | `IdEjecucion` | Column |
| `source_system` | `SistemaFuente` | Column |
| `source_name` | `NombreFuente` | Column |
| `extracted_at` | `FechaExtraccion` | Column |
| `watermark_from` | `MarcaAguaDesde` | Column |
| `watermark_to` | `MarcaAguaHasta` | Column |
| `status` | `Estado` | Column |
| `rows_extracted` | `FilasExtraidas` | Column |
| `rows_inserted` | `FilasInsertadas` | Column |
| `rows_updated` | `FilasActualizadas` | Column |
| `rows_unchanged` | `FilasSinCambio` | Column |
| `error_message` | `MensajeError` | Column |
| `created_at` | `FechaCreacion` | Column |

---

## Columnas — SapLikpRaw (ex CFL_sap_likp_raw) [+ columna nueva]

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `raw_id` | `IdSapLikpRaw` | Column (PK) |
| `execution_id` | `IdEjecucion` | Column |
| `extracted_at` | `FechaExtraccion` | Column |
| `source_system` | `SistemaFuente` | Column |
| `row_hash` | `HashFila` | Column |
| `row_status` | `EstadoFila` | Column |
| `created_at` | `FechaCreacion` | Column |
| `sap_numero_entrega` | `SapNumeroEntrega` | Column |
| `sap_referencia` | `SapReferencia` | Column |
| `sap_puesto_expedicion` | `SapPuestoExpedicion` | Column |
| *(NUEVA)* | `SapDestinatario` | Column (additive) |
| `sap_organizacion_ventas` | `SapOrganizacionVentas` | Column |
| `sap_creado_por` | `SapCreadoPor` | Column |
| `sap_fecha_creacion` | `SapFechaCreacion` | Column |
| `sap_clase_entrega` | `SapClaseEntrega` | Column |
| `sap_tipo_entrega` | `SapTipoEntrega` | Column |
| `sap_fecha_carga` | `SapFechaCarga` | Column |
| `sap_hora_carga` | `SapHoraCarga` | Column |
| `sap_guia_remision` | `SapGuiaRemision` | Column |
| `sap_nombre_chofer` | `SapNombreChofer` | Column |
| `sap_id_fiscal_chofer` | `SapIdFiscalChofer` | Column |
| `sap_empresa_transporte` | `SapEmpresaTransporte` | Column |
| `sap_patente` | `SapPatente` | Column |
| `sap_carro` | `SapCarro` | Column |
| `sap_fecha_salida` | `SapFechaSalida` | Column |
| `sap_hora_salida` | `SapHoraSalida` | Column |
| `sap_codigo_tipo_flete` | `SapCodigoTipoFlete` | Column |
| `sap_centro_costo` | `SapCentroCosto` | Column |
| `sap_cuenta_mayor` | `SapCuentaMayor` | Column |
| `sap_peso_total` | `SapPesoTotal` | Column |
| `sap_peso_neto` | `SapPesoNeto` | Column |
| `sap_fecha_entrega_real` | `SapFechaEntregaReal` | Column |

---

## Columnas — SapLipsRaw (ex CFL_sap_lips_raw)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `raw_id` | `IdSapLipsRaw` | Column (PK) |
| `execution_id` | `IdEjecucion` | Column |
| `extracted_at` | `FechaExtraccion` | Column |
| `source_system` | `SistemaFuente` | Column |
| `row_hash` | `HashFila` | Column |
| `row_status` | `EstadoFila` | Column |
| `created_at` | `FechaCreacion` | Column |
| `sap_numero_entrega` | `SapNumeroEntrega` | Column |
| `sap_posicion` | `SapPosicion` | Column |
| `sap_material` | `SapMaterial` | Column |
| `sap_cantidad_entregada` | `SapCantidadEntregada` | Column |
| `sap_unidad_peso` | `SapUnidadPeso` | Column |
| `sap_denominacion_material` | `SapDenominacionMaterial` | Column |
| `sap_centro` | `SapCentro` | Column |
| `sap_almacen` | `SapAlmacen` | Column |
| `sap_posicion_superior` | `SapPosicionSuperior` | Column |
| `sap_lote` | `SapLote` | Column |

---

## Columnas — SapEntrega (ex CFL_sap_entrega)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_sap_entrega` | `IdSapEntrega` | Column (PK) |
| `sap_numero_entrega` | `SapNumeroEntrega` | Column |
| `source_system` | `SistemaFuente` | Column |
| `created_at` | `FechaCreacion` | Column |
| `updated_at` | `FechaActualizacion` | Column |
| `locked` | `Bloqueado` | Column |
| `locked_at` | `FechaBloqueado` | Column |
| `changed_in_last_run` | `CambiadoEnUltimaEjecucion` | Column |
| `last_change_at` | `FechaUltimoCambio` | Column |
| `last_change_type` | `TipoUltimoCambio` | Column |
| `last_seen_execution_id` | `IdEjecucionUltimaVista` | Column |
| `last_seen_at` | `FechaUltimaVista` | Column |
| `last_change_execution_id` | `IdEjecucionUltimoCambio` | Column |
| `last_change_extracted_at` | `FechaExtraccionUltimoCambio` | Column |
| `last_raw_likp_id` | `IdUltimoLikpRaw` | Column |
| `last_raw_likp_hash` | `HashUltimoLikpRaw` | Column |

---

## Columnas — SapEntregaHistorial (ex CFL_sap_entrega_hist)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_sap_entrega_hist` | `IdSapEntregaHistorial` | Column (PK) |
| `id_sap_entrega` | `IdSapEntrega` | Column (FK) |
| `raw_likp_id` | `IdLikpRaw` | Column (FK) |
| `execution_id` | `IdEjecucion` | Column |
| `extracted_at` | `FechaExtraccion` | Column |
| `created_at` | `FechaCreacion` | Column |

---

## Columnas — SapEntregaPosicion (ex CFL_sap_entrega_posicion)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_sap_entrega_posicion` | `IdSapEntregaPosicion` | Column (PK) |
| `id_sap_entrega` | `IdSapEntrega` | Column (FK) |
| `sap_posicion` | `SapPosicion` | Column |
| `created_at` | `FechaCreacion` | Column |
| `updated_at` | `FechaActualizacion` | Column |
| `status` | `Estado` | Column |
| `missing_since` | `AusenteDesde` | Column |
| `changed_in_last_run` | `CambiadoEnUltimaEjecucion` | Column |
| `last_change_at` | `FechaUltimoCambio` | Column |
| `last_change_type` | `TipoUltimoCambio` | Column |
| `last_seen_execution_id` | `IdEjecucionUltimaVista` | Column |
| `last_seen_at` | `FechaUltimaVista` | Column |
| `last_change_execution_id` | `IdEjecucionUltimoCambio` | Column |
| `last_change_extracted_at` | `FechaExtraccionUltimoCambio` | Column |
| `last_raw_lips_id` | `IdUltimoLipsRaw` | Column |
| `last_raw_lips_hash` | `HashUltimoLipsRaw` | Column |

---

## Columnas — SapEntregaPosicionHistorial (ex CFL_sap_entrega_posicion_hist)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_sap_entrega_posicion_hist` | `IdSapEntregaPosicionHistorial` | Column (PK) |
| `id_sap_entrega_posicion` | `IdSapEntregaPosicion` | Column (FK) |
| `raw_lips_id` | `IdLipsRaw` | Column (FK) |
| `execution_id` | `IdEjecucion` | Column |
| `extracted_at` | `FechaExtraccion` | Column |
| `created_at` | `FechaCreacion` | Column |

---

## Columnas — SapEntregaDescarte (ex CFL_sap_entrega_descarte)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_sap_entrega_descarte` | `IdSapEntregaDescarte` | Column (PK) |
| `id_sap_entrega` | `IdSapEntrega` | Column (FK) |
| `activo` | `Activo` | Column |
| `motivo` | `Motivo` | Column |
| `created_at` | `FechaCreacion` | Column |
| `updated_at` | `FechaActualizacion` | Column |
| `created_by` | `CreadoPor` | Column (FK) |
| `restored_at` | `FechaRestauracion` | Column |
| `restored_by` | `RestauradoPor` | Column (FK) |

---

## Columnas — Temporada (ex CFL_temporada)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_temporada` | `IdTemporada` | Column (PK) |
| `codigo` | `Codigo` | Column |
| `nombre` | `Nombre` | Column |
| `fecha_inicio` | `FechaInicio` | Column |
| `fecha_fin` | `FechaFin` | Column |
| `activa` | `Activa` | Column |
| `cerrada` | `Cerrada` | Column |
| `fecha_cierre` | `FechaCierre` | Column |
| `id_usuario_cierre` | `IdUsuarioCierre` | Column (FK) |
| `observacion_cierre` | `ObservacionCierre` | Column |
| `created_at` | `FechaCreacion` | Column |
| `updated_at` | `FechaActualizacion` | Column |

---

## Columnas — CentroCosto (ex CFL_centro_costo)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_centro_costo` | `IdCentroCosto` | Column (PK) |
| `sap_codigo` | `SapCodigo` | Column |
| `nombre` | `Nombre` | Column |
| `activo` | `Activo` | Column |

---

## Columnas — CuentaMayor (ex CFL_cuenta_mayor)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_cuenta_mayor` | `IdCuentaMayor` | Column (PK) |
| `codigo` | `Codigo` | Column |
| `glosa` | `Glosa` | Column |

---

## Columnas — Folio (ex CFL_folio)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_folio` | `IdFolio` | Column (PK) |
| `id_usuario_cierre` | `IdUsuarioCierre` | Column (FK) |
| `id_centro_costo` | `IdCentroCosto` | Column (FK) |
| `id_temporada` | `IdTemporada` | Column (FK) |
| `folio_numero` | `FolioNumero` | Column |
| `periodo_desde` | `PeriodoDesde` | Column |
| `periodo_hasta` | `PeriodoHasta` | Column |
| `estado` | `Estado` | Column |
| `bloqueado` | `Bloqueado` | Column |
| `fecha_cierre` | `FechaCierre` | Column |
| `resultado_cuadratura` | `ResultadoCuadratura` | Column |
| `resumen_cuadratura` | `ResumenCuadratura` | Column |
| `created_at` | `FechaCreacion` | Column |
| `updated_at` | `FechaActualizacion` | Column |

---

## Columnas — NodoLogistico (ex CFL_nodo_logistico)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_nodo` | `IdNodo` | Column (PK) |
| `nombre` | `Nombre` | Column |
| `region` | `Region` | Column |
| `comuna` | `Comuna` | Column |
| `ciudad` | `Ciudad` | Column |
| `calle` | `Calle` | Column |
| `activo` | `Activo` | Column |

---

## Columnas — Ruta (ex CFL_ruta)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_ruta` | `IdRuta` | Column (PK) |
| `id_origen_nodo` | `IdOrigenNodo` | Column (FK) |
| `id_destino_nodo` | `IdDestinoNodo` | Column (FK) |
| `nombre_ruta` | `NombreRuta` | Column |
| `distancia_km` | `DistanciaKm` | Column |
| `activo` | `Activo` | Column |
| `created_at` | `FechaCreacion` | Column |
| `updated_at` | `FechaActualizacion` | Column |

---

## Columnas — TipoCamion (ex CFL_tipo_camion)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_tipo_camion` | `IdTipoCamion` | Column (PK) |
| `nombre` | `Nombre` | Column |
| `categoria` | `Categoria` | Column |
| `capacidad_kg` | `CapacidadKg` | Column |
| `requiere_temperatura` | `RequiereTemperatura` | Column |
| `descripcion` | `Descripcion` | Column |
| `activo` | `Activo` | Column |

---

## Columnas — Camion (ex CFL_camion)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_camion` | `IdCamion` | Column (PK) |
| `id_tipo_camion` | `IdTipoCamion` | Column (FK) |
| `sap_patente` | `SapPatente` | Column |
| `sap_carro` | `SapCarro` | Column |
| `activo` | `Activo` | Column |
| `created_at` | `FechaCreacion` | Column |
| `updated_at` | `FechaActualizacion` | Column |

---

## Columnas — EmpresaTransporte (ex CFL_empresa_transporte)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_empresa` | `IdEmpresa` | Column (PK) |
| `sap_codigo` | `SapCodigo` | Column |
| `rut` | `Rut` | Column |
| `razon_social` | `RazonSocial` | Column |
| `nombre_rep` | `NombreRepresentante` | Column |
| `correo` | `Correo` | Column |
| `telefono` | `Telefono` | Column |
| `activo` | `Activo` | Column |
| `created_at` | `FechaCreacion` | Column |
| `updated_at` | `FechaActualizacion` | Column |

---

## Columnas — Chofer (ex CFL_chofer)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_chofer` | `IdChofer` | Column (PK) |
| `sap_id_fiscal` | `SapIdFiscal` | Column |
| `sap_nombre` | `SapNombre` | Column |
| `telefono` | `Telefono` | Column |
| `activo` | `Activo` | Column |

---

## Columnas — Movil (ex CFL_movil)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_movil` | `IdMovil` | Column (PK) |
| `id_chofer` | `IdChofer` | Column (FK) |
| `id_empresa_transporte` | `IdEmpresaTransporte` | Column (FK) |
| `id_camion` | `IdCamion` | Column (FK) |
| `activo` | `Activo` | Column |
| `created_at` | `FechaCreacion` | Column |
| `updated_at` | `FechaActualizacion` | Column |

---

## Columnas — DetalleViaje (ex CFL_detalle_viaje)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_detalle_viaje` | `IdDetalleViaje` | Column (PK) |
| `descripcion` | `Descripcion` | Column |
| `observacion` | `Observacion` | Column |
| `activo` | `Activo` | Column |

---

## Columnas — TipoFlete (ex CFL_tipo_flete)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_tipo_flete` | `IdTipoFlete` | Column (PK) |
| `sap_codigo` | `SapCodigo` | Column |
| `nombre` | `Nombre` | Column |
| `activo` | `Activo` | Column |
| `id_centro_costo` | `IdCentroCosto` | Column (FK) |

---

## Columnas — Tarifa (ex CFL_tarifa)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_tarifa` | `IdTarifa` | Column (PK) |
| `id_tipo_camion` | `IdTipoCamion` | Column (FK) |
| `id_temporada` | `IdTemporada` | Column (FK) |
| `id_ruta` | `IdRuta` | Column (FK) |
| `vigencia_desde` | `VigenciaDesde` | Column |
| `vigencia_hasta` | `VigenciaHasta` | Column |
| `prioridad` | `Prioridad` | Column |
| `regla` | `Regla` | Column |
| `moneda` | `Moneda` | Column |
| `monto_fijo` | `MontoFijo` | Column |
| `activo` | `Activo` | Column |
| `created_at` | `FechaCreacion` | Column |
| `updated_at` | `FechaActualizacion` | Column |

---

## Columnas — Especie (ex CFL_especie)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_especie` | `IdEspecie` | Column (PK) |
| `glosa` | `Glosa` | Column |

---

## Columnas — CabeceraFlete (ex CFL_cabecera_flete)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_cabecera_flete` | `IdCabeceraFlete` | Column (PK) |
| `sap_numero_entrega` | `SapNumeroEntrega` | Column |
| `sap_codigo_tipo_flete` | `SapCodigoTipoFlete` | Column |
| `sap_centro_costo` | `SapCentroCosto` | Column |
| `sap_cuenta_mayor` | `SapCuentaMayor` | Column |
| `sap_guia_remision` | `SapGuiaRemision` | Column |
| `numero_entrega` | `NumeroEntrega` | Column |
| `guia_remision` | `GuiaRemision` | Column |
| `tipo_movimiento` | `TipoMovimiento` | Column |
| `estado` | `Estado` | Column |
| `fecha_salida` | `FechaSalida` | Column |
| `hora_salida` | `HoraSalida` | Column |
| `monto_aplicado` | `MontoAplicado` | Column |
| `observaciones` | `Observaciones` | Column |
| `id_cuenta_mayor` | `IdCuentaMayor` | Column (FK) |
| `id_centro_costo` | `IdCentroCosto` | Column (FK) |
| `id_folio` | `IdFolio` | Column (FK) |
| `id_tipo_flete` | `IdTipoFlete` | Column (FK) |
| `id_detalle_viaje` | `IdDetalleViaje` | Column (FK) |
| `id_movil` | `IdMovil` | Column (FK) |
| `id_tarifa` | `IdTarifa` | Column (FK) |
| `id_usuario_creador` | `IdUsuarioCreador` | Column (FK) |
| `created_at` | `FechaCreacion` | Column |
| `updated_at` | `FechaActualizacion` | Column |
| `id_factura` | `IdFactura` | Column (FK, migración 20250309) |

---

## Columnas — DetalleFlete (ex CFL_detalle_flete)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_detalle_flete` | `IdDetalleFlete` | Column (PK) |
| `id_cabecera_flete` | `IdCabeceraFlete` | Column (FK) |
| `id_especie` | `IdEspecie` | Column (FK) |
| `material` | `Material` | Column |
| `descripcion` | `Descripcion` | Column |
| `cantidad` | `Cantidad` | Column |
| `unidad` | `Unidad` | Column |
| `peso` | `Peso` | Column |
| `created_at` | `FechaCreacion` | Column |

---

## Columnas — FleteEstadoHistorial (ex CFL_flete_estado_historial)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_flete_estado_historial` | `IdFleteEstadoHistorial` | Column (PK) |
| `id_cabecera_flete` | `IdCabeceraFlete` | Column (FK) |
| `estado` | `Estado` | Column |
| `fecha_hora` | `FechaHora` | Column |
| `id_usuario` | `IdUsuario` | Column (FK) |
| `motivo` | `Motivo` | Column |
| `evidencia_ref` | `EvidenciaRef` | Column |

---

## Columnas — CabeceraFactura (ex CFL_cabecera_factura)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_factura` | `IdFactura` | Column (PK) |
| `id_folio` | `IdFolio` | Column (FK) |
| `id_empresa` | `IdEmpresa` | Column (FK) |
| `numero_factura` | `NumeroFactura` | Column |
| `fecha_emision` | `FechaEmision` | Column |
| `moneda` | `Moneda` | Column |
| `monto_neto` | `MontoNeto` | Column |
| `monto_iva` | `MontoIva` | Column |
| `monto_total` | `MontoTotal` | Column |
| `estado` | `Estado` | Column |
| `criterio_agrupacion` | `CriterioAgrupacion` | Column (migración) |
| `observaciones` | `Observaciones` | Column (migración) |
| `ruta_xml` | `RutaXml` | Column |
| `ruta_pdf` | `RutaPdf` | Column |
| `created_at` | `FechaCreacion` | Column |
| `updated_at` | `FechaActualizacion` | Column |

---

## Columnas — DetalleFactura (ex CFL_detalle_factura)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_factura_detalle` | `IdFacturaDetalle` | Column (PK) |
| `id_factura` | `IdFactura` | Column (FK) |
| `monto_linea` | `MontoLinea` | Column |
| `detalle` | `Detalle` | Column |

---

## Columnas — ConciliacionFacturaFlete (ex CFL_conciliacion_factura_flete)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_conciliacion` | `IdConciliacion` | Column (PK) |
| `id_factura` | `IdFactura` | Column (FK) |
| `id_cabecera_flete` | `IdCabeceraFlete` | Column (FK) |
| `monto_asignado` | `MontoAsignado` | Column |
| `diferencia` | `Diferencia` | Column |
| `tolerancia_aplicada` | `ToleranciaAplicada` | Column |
| `estado` | `Estado` | Column |
| `observacion` | `Observacion` | Column |
| `created_at` | `FechaCreacion` | Column |
| `updated_at` | `FechaActualizacion` | Column |

---

## Columnas — FleteSapEntrega (ex CFL_flete_sap_entrega)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_flete_sap_entrega` | `IdFleteSapEntrega` | Column (PK) |
| `id_cabecera_flete` | `IdCabeceraFlete` | Column (FK) |
| `id_sap_entrega` | `IdSapEntrega` | Column (FK) |
| `origen_datos` | `OrigenDatos` | Column |
| `tipo_relacion` | `TipoRelacion` | Column |
| `created_at` | `FechaCreacion` | Column |
| `created_by` | `CreadoPor` | Column (FK) |

---

## Columnas — Usuario (ex CFL_usuario)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_usuario` | `IdUsuario` | Column (PK) |
| `username` | `Username` | Column |
| `email` | `Email` | Column |
| `password_hash` | `PasswordHash` | Column |
| `nombre` | `Nombre` | Column |
| `apellido` | `Apellido` | Column |
| `activo` | `Activo` | Column |
| `ultimo_login` | `UltimoLogin` | Column |
| `created_at` | `FechaCreacion` | Column |
| `updated_at` | `FechaActualizacion` | Column |

---

## Columnas — Rol (ex CFL_rol)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_rol` | `IdRol` | Column (PK) |
| `nombre` | `Nombre` | Column |
| `descripcion` | `Descripcion` | Column |
| `activo` | `Activo` | Column |

---

## Columnas — Permiso (ex CFL_permiso)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_permiso` | `IdPermiso` | Column (PK) |
| `recurso` | `Recurso` | Column |
| `accion` | `Accion` | Column |
| `clave` | `Clave` | Column |
| `descripcion` | `Descripcion` | Column |
| `activo` | `Activo` | Column |

---

## Columnas — UsuarioRol (ex CFL_usuario_rol)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_usuario_rol` | `IdUsuarioRol` | Column (PK) |
| `id_usuario` | `IdUsuario` | Column (FK) |
| `id_rol` | `IdRol` | Column (FK) |

---

## Columnas — RolPermiso (ex CFL_rol_permiso)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_rol_permiso` | `IdRolPermiso` | Column (PK) |
| `id_rol` | `IdRol` | Column (FK) |
| `id_permiso` | `IdPermiso` | Column (FK) |

---

## Columnas — Auditoria (ex CFL_auditoria)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| `id_auditoria` | `IdAuditoria` | Column (PK) |
| `id_usuario` | `IdUsuario` | Column (FK) |
| `fecha_hora` | `FechaHora` | Column |
| `accion` | `Accion` | Column |
| `entidad` | `Entidad` | Column |
| `id_entidad` | `IdEntidad` | Column |
| `resumen` | `Resumen` | Column |
| `ip_equipo` | `IpEquipo` | Column |

---

## Ambigüedades resueltas

| Ambigüedad | Resolución |
|---|---|
| `nombre_rep` en EmpresaTransporte | → `NombreRepresentante` (más descriptivo) |
| `raw_id` genérico en tablas raw | → `IdSapLikpRaw` / `IdSapLipsRaw` (específico por tabla) |
| `status` en SapEntregaPosicion | → `Estado` (consistente con resto del modelo) |
| `missing_since` | → `AusenteDesde` (traducción directa) |
| `created_by` / `restored_by` | → `CreadoPor` / `RestauradoPor` (español natural) |
| `locked` / `locked_at` | → `Bloqueado` / `FechaBloqueado` (español + consistente con Folio) |
| `rn` (alias interno en CTEs) | No renombrado — alias interno de SQL, no columna persistida |
| `sap_id_fiscal_chofer` | → `SapIdFiscalChofer` (prefijo Sap + PascalCase) |

---

## Objetos nuevos (aditivos)

| Nombre Antiguo | Nombre Nuevo | Tipo |
|---|---|---|
| *(nuevo)* | [cfl].[Productor] | Table |
| *(nuevo)* | IdProductor (en [cfl].[CabeceraFlete]) | Column |
| *(nuevo)* | SentidoFlete (en [cfl].[CabeceraFlete]) | Column |
