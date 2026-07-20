#!/usr/bin/env sh
set -eu

CASE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
RELEASE_ROOT="${RELEASE_ROOT:-$(CDPATH= cd -- "$CASE_DIR/../.." 2>/dev/null && pwd)}"
PYTHON_EXE="${PYTHON_EXE:-}"

if [ -z "$PYTHON_EXE" ]; then
    if [ -x "$RELEASE_ROOT/.venv/bin/python" ]; then
        PYTHON_EXE="$RELEASE_ROOT/.venv/bin/python"
    elif command -v python3 >/dev/null 2>&1; then
        PYTHON_EXE="python3"
    else
        echo "ERROR: python3 not found. See LINUX_PETSC_MPI_TUTORIAL.txt" >&2
        exit 1
    fi
fi

SOLVER="$RELEASE_ROOT/SOLVER_0_4_petsc_mpi.pyz"
EXPORTER="$RELEASE_ROOT/export_loaded_unloaded_coordinates.py"
SCRIPT="$CASE_DIR/Script.txt"
RUN_SCRIPT="$CASE_DIR/Script_autorun_petsc_mpi_60000.txt"
SUMMARY="$CASE_DIR/voxfe_solver_summary_petsc_mpi_60000.json"
LOG="$CASE_DIR/solver_petsc_mpi_60000_stdout.log"
COORD_SUMMARY="$CASE_DIR/coordinate_export_summary_petsc_mpi.json"
METHOD="${METHOD:-PETSCGAMG}"
BACKEND="petsc_optional"
MAX_ITER="${MAX_ITER:-60000}"
MPI_PROCS="${MPI_PROCS:-2}"
MPIEXEC="${MPIEXEC:-mpiexec}"

if [ ! -f "$SOLVER" ]; then
    echo "ERROR: solver not found: $SOLVER" >&2
    exit 1
fi
if [ ! -f "$SCRIPT" ]; then
    echo "ERROR: Script.txt not found in $CASE_DIR" >&2
    exit 1
fi
if ! command -v "$MPIEXEC" >/dev/null 2>&1; then
    echo "ERROR: $MPIEXEC not found. Install MPI/PETSc from conda-forge or set MPIEXEC=/path/to/mpiexec" >&2
    exit 1
fi

"$PYTHON_EXE" - "$SCRIPT" "$RUN_SCRIPT" "$METHOD" "$MAX_ITER" <<'PY'
from pathlib import Path
import re
import sys

source = Path(sys.argv[1])
target = Path(sys.argv[2])
method = sys.argv[3]
max_iter = sys.argv[4]
lines = source.read_text(encoding="utf-8", errors="replace").splitlines()
out = []
has_alg = False
has_iter = False
for line in lines:
    if re.match(r"^\s*ALGORITHM_FEA\s+", line, re.I):
        out.append(f"ALGORITHM_FEA {method}")
        has_alg = True
    elif re.match(r"^\s*MAX_ITER\s+", line, re.I):
        out.append(f"MAX_ITER {max_iter}")
        has_iter = True
    else:
        out.append(line)
if not has_alg:
    out.insert(0, f"ALGORITHM_FEA {method}")
if not has_iter:
    out.insert(1, f"MAX_ITER {max_iter}")
target.write_text("\n".join(out).rstrip() + "\n", encoding="utf-8")
PY

echo "Solving one folder with direct PETSc/MPI assembly"
echo "Case:      $CASE_DIR"
echo "Python:    $PYTHON_EXE"
echo "MPI exec:  $MPIEXEC"
echo "MPI ranks: $MPI_PROCS"
echo "Solver:    $SOLVER"
echo "Method:    $METHOD"
echo "Backend:   $BACKEND"
echo "Log:       $LOG"
echo

cd "$CASE_DIR"
export PYTHONUNBUFFERED=1
export PYTHONIOENCODING=utf-8
"$MPIEXEC" -n "$MPI_PROCS" "$PYTHON_EXE" -u "$SOLVER" "$(basename "$RUN_SCRIPT")" \
    --backend "$BACKEND" \
    --algorithm "$METHOD" \
    --threads 1 \
    --summary "$SUMMARY" \
    --progress-interval 50 2>&1 | tee "$LOG"

if [ -f "$EXPORTER" ]; then
    echo
    echo "Exporting loaded/unloaded coordinates..."
    "$PYTHON_EXE" -u "$EXPORTER" --case-dir "$CASE_DIR" --script "$RUN_SCRIPT" --summary "$COORD_SUMMARY" 2>&1 | tee -a "$LOG"
fi

echo
echo "Done."
echo "Summary: $SUMMARY"
