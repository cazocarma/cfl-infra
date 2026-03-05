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
  WHERE r.nombre IN ('Administrador', 'Autorizador')
    AND p.clave IN ('fletes.anular', 'fletes.sap.descartar')
)
MERGE cfl.CFL_rol_permiso AS t
USING role_permiso AS s
ON t.id_rol = s.id_rol AND t.id_permiso = s.id_permiso
WHEN NOT MATCHED THEN
  INSERT (id_rol, id_permiso) VALUES (s.id_rol, s.id_permiso);

DELETE rp
FROM cfl.CFL_rol_permiso rp
INNER JOIN cfl.CFL_rol r
  ON r.id_rol = rp.id_rol
INNER JOIN cfl.CFL_permiso p
  ON p.id_permiso = rp.id_permiso
WHERE r.nombre = 'Ingresador'
  AND p.clave IN ('fletes.anular', 'fletes.sap.descartar');
