/*
  Patch idempotente para cargar permisos y matriz rol/permiso.
  Ejecutar en la base objetivo (ej: DBPRD) despues de UP/SEED.
*/

SET NOCOUNT ON;

BEGIN TRANSACTION;

;WITH src AS (
  SELECT recurso, accion, clave, descripcion, activo
  FROM (VALUES
    ('mantenedores', 'view', 'mantenedores.view', 'Consultar mantenedores', 1),
    ('mantenedores', 'admin', 'mantenedores.admin', 'Administracion completa de mantenedores', 1),
    ('mantenedores', 'edit', 'mantenedores.edit.temporadas', 'Editar mantenedor temporadas', 1),
    ('mantenedores', 'edit', 'mantenedores.edit.centros-costo', 'Editar mantenedor centros de costo', 1),
    ('mantenedores', 'edit', 'mantenedores.edit.tipos-flete', 'Editar mantenedor tipos de flete', 1),
    ('mantenedores', 'edit', 'mantenedores.edit.detalles-viaje', 'Editar mantenedor detalles de viaje', 1),
    ('mantenedores', 'edit', 'mantenedores.edit.especies', 'Editar mantenedor especies', 1),
    ('mantenedores', 'edit', 'mantenedores.edit.nodos', 'Editar mantenedor nodos', 1),
    ('mantenedores', 'edit', 'mantenedores.edit.rutas', 'Editar mantenedor rutas', 1),
    ('mantenedores', 'edit', 'mantenedores.edit.tipos-camion', 'Editar mantenedor tipos de camion', 1),
    ('mantenedores', 'edit', 'mantenedores.edit.camiones', 'Editar mantenedor camiones', 1),
    ('mantenedores', 'edit', 'mantenedores.edit.empresas-transporte', 'Editar mantenedor empresas de transporte', 1),
    ('mantenedores', 'edit', 'mantenedores.edit.choferes', 'Editar mantenedor choferes', 1),
    ('mantenedores', 'edit', 'mantenedores.edit.tarifas', 'Editar mantenedor tarifas', 1),
    ('mantenedores', 'edit', 'mantenedores.edit.cuentas-mayor', 'Editar mantenedor cuentas mayores', 1),
    ('mantenedores', 'edit', 'mantenedores.edit.folios', 'Editar mantenedor folios', 1),
    ('mantenedores', 'edit', 'mantenedores.edit.usuarios', 'Editar mantenedor usuarios', 1),
    ('fletes', 'view', 'fletes.candidatos.view', 'Ver candidatos a flete', 1),
    ('fletes', 'create', 'fletes.crear', 'Crear flete desde candidato', 1),
    ('fletes', 'edit', 'fletes.editar', 'Editar flete', 1),
    ('fletes', 'change_state', 'fletes.estado.cambiar', 'Cambiar estado operativo de flete', 1),
    ('excepciones', 'manage', 'excepciones.gestionar', 'Gestionar excepciones', 1),
    ('excepciones', 'authorize', 'excepciones.autorizar', 'Autorizar excepciones', 1),
    ('folios', 'assign', 'folios.asignar', 'Asignar/reasignar folio', 1),
    ('folios', 'close', 'folios.cerrar', 'Cerrar folio', 1),
    ('facturas', 'edit', 'facturas.editar', 'Registrar/editar factura', 1),
    ('facturas', 'reconcile', 'facturas.conciliar', 'Conciliar factura con flete', 1),
    ('planillas', 'generate', 'planillas.generar', 'Generar/reemitir planilla SAP', 1),
    ('reportes', 'view', 'reportes.view', 'Visualizar dashboard y reportes', 1),
    ('usuarios', 'admin', 'usuarios.permisos.admin', 'Administrar usuarios/roles/permisos', 1)
  ) v(recurso, accion, clave, descripcion, activo)
)
MERGE cfl.CFL_permiso AS t
USING src AS s
ON t.clave = s.clave
WHEN MATCHED THEN
  UPDATE SET
    t.recurso = s.recurso,
    t.accion = s.accion,
    t.descripcion = s.descripcion,
    t.activo = s.activo
WHEN NOT MATCHED THEN
  INSERT (recurso, accion, clave, descripcion, activo)
  VALUES (s.recurso, s.accion, s.clave, s.descripcion, s.activo);

;WITH role_permiso AS (
  SELECT r.id_rol, p.id_permiso
  FROM cfl.CFL_rol r
  INNER JOIN cfl.CFL_permiso p ON p.activo = 1
  WHERE r.nombre = 'Administrador'

  UNION ALL

  SELECT r.id_rol, p.id_permiso
  FROM cfl.CFL_rol r
  INNER JOIN cfl.CFL_permiso p ON p.activo = 1
  WHERE r.nombre = 'Ingresador'
    AND p.clave IN (
      'mantenedores.view',
      'fletes.candidatos.view',
      'fletes.crear',
      'fletes.editar',
      'fletes.estado.cambiar',
      'excepciones.gestionar',
      'facturas.editar',
      'reportes.view'
    )

  UNION ALL

  SELECT r.id_rol, p.id_permiso
  FROM cfl.CFL_rol r
  INNER JOIN cfl.CFL_permiso p ON p.activo = 1
  WHERE r.nombre = 'Autorizador'
    AND p.clave IN (
      'mantenedores.view',
      'mantenedores.edit.centros-costo',
      'mantenedores.edit.detalles-viaje',
      'mantenedores.edit.especies',
      'mantenedores.edit.nodos',
      'mantenedores.edit.rutas',
      'mantenedores.edit.tipos-camion',
      'mantenedores.edit.camiones',
      'mantenedores.edit.empresas-transporte',
      'mantenedores.edit.choferes',
      'mantenedores.edit.tarifas',
      'fletes.candidatos.view',
      'fletes.crear',
      'fletes.editar',
      'fletes.estado.cambiar',
      'excepciones.gestionar',
      'excepciones.autorizar',
      'folios.asignar',
      'folios.cerrar',
      'facturas.editar',
      'facturas.conciliar',
      'planillas.generar',
      'reportes.view'
    )
)
MERGE cfl.CFL_rol_permiso AS t
USING role_permiso AS s
ON t.id_rol = s.id_rol AND t.id_permiso = s.id_permiso
WHEN NOT MATCHED THEN
  INSERT (id_rol, id_permiso) VALUES (s.id_rol, s.id_permiso);

COMMIT TRANSACTION;

SELECT
  roles = (SELECT COUNT_BIG(1) FROM cfl.CFL_rol),
  permisos = (SELECT COUNT_BIG(1) FROM cfl.CFL_permiso),
  asignaciones = (SELECT COUNT_BIG(1) FROM cfl.CFL_rol_permiso);
