#!/usr/bin/env bash
set -euo pipefail

MARKER_FILE="/var/opt/mssql/.cfl_model_initialized"
SCRIPTS_DIR="/var/opt/mssql/seed/modelo-datos"
UP_SCRIPT="${SCRIPTS_DIR}/UP.sql"
SEED_SCRIPT="${SCRIPTS_DIR}/SEED.sql"

SQLCMD_BIN="/opt/mssql-tools18/bin/sqlcmd"
if [ ! -x "${SQLCMD_BIN}" ]; then
  SQLCMD_BIN="/opt/mssql-tools/bin/sqlcmd"
fi

if [ ! -x "${SQLCMD_BIN}" ]; then
  echo "ERROR: sqlcmd no encontrado en la imagen." >&2
  exit 1
fi

/opt/mssql/bin/sqlservr &
SQL_PID=$!

shutdown() {
  kill -TERM "${SQL_PID}" >/dev/null 2>&1 || true
  wait "${SQL_PID}" || true
}

trap shutdown SIGINT SIGTERM

if [ -f "${MARKER_FILE}" ]; then
  echo "Modelo de datos ya inicializado en este volumen. Omitiendo UP.sql y SEED.sql."
  wait "${SQL_PID}"
  exit $?
fi

for script in "${UP_SCRIPT}" "${SEED_SCRIPT}"; do
  if [ ! -f "${script}" ]; then
    echo "ERROR: no se encontro script requerido: ${script}" >&2
    exit 1
  fi
done

echo "Esperando SQL Server para inicializar modelo de datos..."
for _ in $(seq 1 60); do
  if "${SQLCMD_BIN}" -S localhost -U sa -P "${MSSQL_SA_PASSWORD}" -C -Q "SELECT 1" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

if ! "${SQLCMD_BIN}" -S localhost -U sa -P "${MSSQL_SA_PASSWORD}" -C -Q "SELECT 1" >/dev/null 2>&1; then
  echo "ERROR: SQL Server no estuvo disponible a tiempo." >&2
  exit 1
fi

echo "Ejecutando UP.sql..."
"${SQLCMD_BIN}" -S localhost -U sa -P "${MSSQL_SA_PASSWORD}" -C -i "${UP_SCRIPT}"

echo "Ejecutando SEED.sql..."
"${SQLCMD_BIN}" -S localhost -U sa -P "${MSSQL_SA_PASSWORD}" -C -i "${SEED_SCRIPT}"

touch "${MARKER_FILE}"
echo "Inicializacion completada."

wait "${SQL_PID}"
