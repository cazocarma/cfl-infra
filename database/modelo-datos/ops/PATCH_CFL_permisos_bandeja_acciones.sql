/*
  PATCH: permisos de acciones de bandeja (anular / descartar SAP)
  Objetivo:
  - Crear permisos especificos para anular y descartar.
  - Asignarlos a Autorizador + Administrador.
  - Removerlos de Ingresador si existian.
*/

SET NOCOUNT ON;

;WITH src AS (
  SELECT recurso, accion, clave, descripcion, activo
  FROM (VALUES
    ('fletes', 'cancel', 'fletes.anular', 'Anular flete', 1),
    ('fletes', 'discard_sap', 'fletes.sap.descartar', 'Descartar entrega SAP de candidatos', 1)
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
    t.activo = s.activo
WHEN NOT MATCHED THEN
  INSERT (recurso, accion, clave, descripcion, activo)
  VALUES (s.recurso, s.accion, s.clave, s.descripcion, s.activo);

;WITH role_permiso AS (
  SELECT r.IdRol, p.IdPermiso
  FROM cfl.Rol r
  INNER JOIN cfl.Permiso p ON p.activo = 1
  WHERE r.nombre IN ('Administrador', 'Autorizador')
    AND p.clave IN ('fletes.anular', 'fletes.sap.descartar')
)
MERGE cfl.RolPermiso AS t
USING role_permiso AS s
ON t.IdRol = s.IdRol AND t.IdPermiso = s.IdPermiso
WHEN NOT MATCHED THEN
  INSERT (IdRol, IdPermiso) VALUES (s.IdRol, s.IdPermiso);

DELETE rp
FROM cfl.RolPermiso rp
INNER JOIN cfl.Rol r
  ON r.IdRol = rp.IdRol
INNER JOIN cfl.Permiso p
  ON p.IdPermiso = rp.IdPermiso
WHERE r.nombre = 'Ingresador'
  AND p.clave IN ('fletes.anular', 'fletes.sap.descartar');
