/* ============================================================================
   SEED 04 - SEGURIDAD
   Rol: poblar roles, usuarios, permisos y sus relaciones.
   Idempotente: SI (MERGE)
============================================================================ */
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;
DECLARE @now DATETIME2(0) = SYSDATETIME();

;WITH src(nombre, descripcion, activo) AS (
  SELECT *
  FROM (VALUES
  (N'Administrador', N'Acceso total al sistema', 1),
  (N'Autorizador', N'Aprueba/cierra folios y autoriza cambios', 1),
  (N'Ingresador', N'Registra/edita fletes y conciliaciones', 1)
  ) v(nombre, descripcion, activo)
)
MERGE cfl.Rol AS t
USING src AS s
ON t.nombre = s.nombre
WHEN MATCHED THEN
  UPDATE SET
    t.descripcion = s.descripcion,
    t.activo = CAST(s.activo AS BIT)
WHEN NOT MATCHED THEN
  INSERT (nombre, descripcion, activo)
  VALUES (s.nombre, s.descripcion, CAST(s.activo AS BIT));

;WITH src(Username, Email, PasswordHash, nombre, apellido, activo, UltimoLogin) AS (
  SELECT *
  FROM (VALUES
  (N'admin', N'admin@local.test', N'$2a$10$GZLnPdZa2IXUQCKjP.3.aeCbzLVuv6CPCu44jgrcF7lAAd6EGJ542', N'Usuario', N'Administrador', 1, NULL),
  (N'autorizador', N'autorizador@local.test', N'$2a$10$GZLnPdZa2IXUQCKjP.3.aeCbzLVuv6CPCu44jgrcF7lAAd6EGJ542', N'Usuario', N'Autorizador', 1, NULL),
  (N'ingresador', N'ingresador@local.test', N'$2a$10$GZLnPdZa2IXUQCKjP.3.aeCbzLVuv6CPCu44jgrcF7lAAd6EGJ542', N'Usuario', N'Ingresador', 1, NULL)
  ) v(Username, Email, PasswordHash, nombre, apellido, activo, UltimoLogin)
)
MERGE cfl.Usuario AS t
USING src AS s
ON t.Username = s.Username
WHEN MATCHED THEN
  UPDATE SET
    t.Email = s.Email,
    t.PasswordHash = s.PasswordHash,
    t.nombre = s.nombre,
    t.apellido = s.apellido,
    t.activo = CAST(s.activo AS BIT),
    t.UltimoLogin = CASE WHEN s.UltimoLogin IS NULL THEN NULL ELSE CAST(s.UltimoLogin AS DATETIME2(0)) END,
    t.FechaActualizacion = @now
WHEN NOT MATCHED THEN
  INSERT (Username, Email, PasswordHash, nombre, apellido, activo, UltimoLogin, FechaCreacion, FechaActualizacion)
  VALUES (s.Username, s.Email, s.PasswordHash, s.nombre, s.apellido, CAST(s.activo AS BIT), CASE WHEN s.UltimoLogin IS NULL THEN NULL ELSE CAST(s.UltimoLogin AS DATETIME2(0)) END, @now, @now);

;WITH src(recurso, accion, clave, descripcion, activo) AS (
  SELECT *
  FROM (VALUES
  (N'excepciones', N'authorize', N'excepciones.autorizar', N'Autorizar excepciones', 1),
  (N'excepciones', N'manage', N'excepciones.gestionar', N'Gestionar excepciones', 1),
  (N'facturas', N'reconcile', N'facturas.conciliar', N'Conciliar factura con flete', 1),
  (N'facturas', N'edit', N'facturas.editar', N'Registrar/editar factura', 1),
  (N'fletes', N'cancel', N'fletes.anular', N'Anular flete', 1),
  (N'fletes', N'view', N'fletes.candidatos.view', N'Ver candidatos a flete', 1),
  (N'fletes', N'create', N'fletes.crear', N'Crear flete desde candidato', 1),
  (N'fletes', N'edit', N'fletes.editar', N'Editar flete', 1),
  (N'fletes', N'change_state', N'fletes.estado.cambiar', N'Cambiar estado operativo de flete', 1),
  (N'fletes', N'discard_sap', N'fletes.sap.descartar', N'Descartar entrega SAP de candidatos', 1),
  (N'folios', N'assign', N'folios.asignar', N'Asignar/reasignar folio', 1),
  (N'folios', N'close', N'folios.cerrar', N'Cerrar folio', 1),
  (N'mantenedores', N'admin', N'mantenedores.admin', N'Administracion completa de mantenedores', 1),
  (N'mantenedores', N'edit', N'mantenedores.edit.camiones', N'Editar mantenedor camiones', 1),
  (N'mantenedores', N'edit', N'mantenedores.edit.centros-costo', N'Editar mantenedor centros de costo', 1),
  (N'mantenedores', N'edit', N'mantenedores.edit.choferes', N'Editar mantenedor choferes', 1),
  (N'mantenedores', N'edit', N'mantenedores.edit.cuentas-mayor', N'Editar mantenedor cuentas mayores', 1),
  (N'mantenedores', N'edit', N'mantenedores.edit.detalles-viaje', N'Editar mantenedor detalles de viaje', 1),
  (N'mantenedores', N'edit', N'mantenedores.edit.empresas-transporte', N'Editar mantenedor empresas de transporte', 1),
  (N'mantenedores', N'edit', N'mantenedores.edit.especies', N'Editar mantenedor especies', 1),
  (N'mantenedores', N'edit', N'mantenedores.edit.folios', N'Editar mantenedor folios', 1),
  (N'mantenedores', N'edit', N'mantenedores.edit.nodos', N'Editar mantenedor nodos', 1),
  (N'mantenedores', N'edit', N'mantenedores.edit.rutas', N'Editar mantenedor rutas', 1),
  (N'mantenedores', N'edit', N'mantenedores.edit.tarifas', N'Editar mantenedor tarifas', 1),
  (N'mantenedores', N'edit', N'mantenedores.edit.temporadas', N'Editar mantenedor temporadas', 1),
  (N'mantenedores', N'edit', N'mantenedores.edit.tipos-camion', N'Editar mantenedor tipos de camion', 1),
  (N'mantenedores', N'edit', N'mantenedores.edit.tipos-flete', N'Editar mantenedor tipos de flete', 1),
  (N'mantenedores', N'edit', N'mantenedores.edit.usuarios', N'Editar mantenedor usuarios', 1),
  (N'mantenedores', N'view', N'mantenedores.view', N'Consultar mantenedores', 1),
  (N'planillas', N'generate', N'planillas.generar', N'Generar/reemitir planilla SAP', 1),
  (N'reportes', N'view', N'reportes.view', N'Visualizar dashboard y reportes', 1),
  (N'usuarios', N'admin', N'usuarios.permisos.admin', N'Administrar usuarios/roles/permisos', 1)
  ) v(recurso, accion, clave, descripcion, activo)
)
MERGE cfl.Permiso AS t
USING src AS s
ON t.clave = s.clave
WHEN MATCHED THEN
  UPDATE SET
    t.recurso = s.recurso,
    t.accion = s.accion,
    t.descripcion = s.descripcion,
    t.activo = CAST(s.activo AS BIT)
WHEN NOT MATCHED THEN
  INSERT (recurso, accion, clave, descripcion, activo)
  VALUES (s.recurso, s.accion, s.clave, s.descripcion, CAST(s.activo AS BIT));

;WITH src(Username, rol_nombre) AS (
  SELECT *
  FROM (VALUES
  (N'admin', N'Administrador'),
  (N'autorizador', N'Autorizador'),
  (N'ingresador', N'Ingresador')
  ) v(Username, rol_nombre)
), resolved AS (
  SELECT u.IdUsuario, r.IdRol
  FROM src s
  INNER JOIN cfl.Usuario u ON u.Username = s.Username
  INNER JOIN cfl.Rol r ON r.nombre = s.rol_nombre
)
MERGE cfl.UsuarioRol AS t
USING resolved AS s
ON t.IdUsuario = s.IdUsuario
AND t.IdRol = s.IdRol
WHEN NOT MATCHED THEN
  INSERT (IdUsuario, IdRol)
  VALUES (s.IdUsuario, s.IdRol);

;WITH src(rol_nombre, permiso_clave) AS (
  SELECT *
  FROM (VALUES
  (N'Administrador', N'excepciones.autorizar'),
  (N'Administrador', N'excepciones.gestionar'),
  (N'Administrador', N'facturas.conciliar'),
  (N'Administrador', N'facturas.editar'),
  (N'Administrador', N'fletes.anular'),
  (N'Administrador', N'fletes.candidatos.view'),
  (N'Administrador', N'fletes.crear'),
  (N'Administrador', N'fletes.editar'),
  (N'Administrador', N'fletes.estado.cambiar'),
  (N'Administrador', N'fletes.sap.descartar'),
  (N'Administrador', N'folios.asignar'),
  (N'Administrador', N'folios.cerrar'),
  (N'Administrador', N'mantenedores.admin'),
  (N'Administrador', N'mantenedores.edit.camiones'),
  (N'Administrador', N'mantenedores.edit.centros-costo'),
  (N'Administrador', N'mantenedores.edit.choferes'),
  (N'Administrador', N'mantenedores.edit.cuentas-mayor'),
  (N'Administrador', N'mantenedores.edit.detalles-viaje'),
  (N'Administrador', N'mantenedores.edit.empresas-transporte'),
  (N'Administrador', N'mantenedores.edit.especies'),
  (N'Administrador', N'mantenedores.edit.folios'),
  (N'Administrador', N'mantenedores.edit.nodos'),
  (N'Administrador', N'mantenedores.edit.rutas'),
  (N'Administrador', N'mantenedores.edit.tarifas'),
  (N'Administrador', N'mantenedores.edit.temporadas'),
  (N'Administrador', N'mantenedores.edit.tipos-camion'),
  (N'Administrador', N'mantenedores.edit.tipos-flete'),
  (N'Administrador', N'mantenedores.edit.usuarios'),
  (N'Administrador', N'mantenedores.view'),
  (N'Administrador', N'planillas.generar'),
  (N'Administrador', N'reportes.view'),
  (N'Administrador', N'usuarios.permisos.admin'),
  (N'Autorizador', N'excepciones.autorizar'),
  (N'Autorizador', N'excepciones.gestionar'),
  (N'Autorizador', N'facturas.conciliar'),
  (N'Autorizador', N'facturas.editar'),
  (N'Autorizador', N'fletes.anular'),
  (N'Autorizador', N'fletes.candidatos.view'),
  (N'Autorizador', N'fletes.crear'),
  (N'Autorizador', N'fletes.editar'),
  (N'Autorizador', N'fletes.estado.cambiar'),
  (N'Autorizador', N'fletes.sap.descartar'),
  (N'Autorizador', N'folios.asignar'),
  (N'Autorizador', N'folios.cerrar'),
  (N'Autorizador', N'mantenedores.edit.camiones'),
  (N'Autorizador', N'mantenedores.edit.centros-costo'),
  (N'Autorizador', N'mantenedores.edit.choferes'),
  (N'Autorizador', N'mantenedores.edit.detalles-viaje'),
  (N'Autorizador', N'mantenedores.edit.empresas-transporte'),
  (N'Autorizador', N'mantenedores.edit.especies'),
  (N'Autorizador', N'mantenedores.edit.nodos'),
  (N'Autorizador', N'mantenedores.edit.rutas'),
  (N'Autorizador', N'mantenedores.edit.tarifas'),
  (N'Autorizador', N'mantenedores.edit.tipos-camion'),
  (N'Autorizador', N'mantenedores.view'),
  (N'Autorizador', N'planillas.generar'),
  (N'Autorizador', N'reportes.view'),
  (N'Ingresador', N'excepciones.gestionar'),
  (N'Ingresador', N'facturas.editar'),
  (N'Ingresador', N'fletes.candidatos.view'),
  (N'Ingresador', N'fletes.crear'),
  (N'Ingresador', N'fletes.editar'),
  (N'Ingresador', N'fletes.estado.cambiar'),
  (N'Ingresador', N'mantenedores.view'),
  (N'Ingresador', N'reportes.view')
  ) v(rol_nombre, permiso_clave)
), resolved AS (
  SELECT r.IdRol, p.IdPermiso
  FROM src s
  INNER JOIN cfl.Rol r ON r.nombre = s.rol_nombre
  INNER JOIN cfl.Permiso p ON p.clave = s.permiso_clave
)
MERGE cfl.RolPermiso AS t
USING resolved AS s
ON t.IdRol = s.IdRol
AND t.IdPermiso = s.IdPermiso
WHEN NOT MATCHED THEN
  INSERT (IdRol, IdPermiso)
  VALUES (s.IdRol, s.IdPermiso);

COMMIT TRANSACTION;
