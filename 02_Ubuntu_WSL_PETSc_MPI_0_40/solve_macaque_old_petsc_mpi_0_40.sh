#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CASE_DIR="$ROOT/models/Macaque_old_model"
PYTHON_EXE="${PYTHON_EXE:-}"
if [[ -z "$PYTHON_EXE" ]]; then
    if [[ -n "${CONDA_PREFIX:-}" && -x "$CONDA_PREFIX/bin/python" ]]; then
        PYTHON_EXE="$CONDA_PREFIX/bin/python"
    else
        PYTHON_EXE="python3"
    fi
fi

MPIEXEC="${MPIEXEC:-mpiexec}"
MPI_PROCS="${MPI_PROCS:-4}"
METHOD="${METHOD:-PETSCGAMG}"
BACKEND="petsc_optional"
MAX_ITER="${MAX_ITER:-60000}"
TOLERANCE="${TOLERANCE:-1e-06}"
MIN_ITER="${MIN_ITER:-0}"
SOLVER="$ROOT/SOLVER_0_40_petsc_mpi.pyz"
EXPORTER="$ROOT/export_loaded_unloaded_coordinates.py"
PREPARE="$ROOT/prepare_autorun_script.py"

RUN_SCRIPT="$CASE_DIR/Script_autorun_ubuntu_${METHOD}_0_40.txt"
SUMMARY="$CASE_DIR/voxfe_solver_summary_ubuntu_${METHOD}_0_40.json"
LOG="$CASE_DIR/solver_ubuntu_${METHOD}_0_40_stdout.log"
COORD_SUMMARY="$CASE_DIR/coordinate_export_summary_ubuntu_${METHOD}_0_40.json"

if [[ ! -f "$SOLVER" ]]; then
    echo "ERROR: solver not found: $SOLVER" >&2
    exit 1
fi
if [[ ! -f "$CASE_DIR/Script.txt" ]]; then
    echo "ERROR: Script.txt not found in $CASE_DIR" >&2
    exit 1
fi

"$PYTHON_EXE" -u "$PREPARE" --source "$CASE_DIR/Script.txt" --target "$RUN_SCRIPT" --method "$METHOD" --max-iter "$MAX_ITER" --min-iter "$MIN_ITER" --tolerance "$TOLERANCE"

echo "Solving Macaque old model with VoxFE 0.40 PETSc/MPI"
echo "Case:      $CASE_DIR"
echo "Python:    $PYTHON_EXE"
echo "MPI exec:  $MPIEXEC"
echo "MPI ranks: $MPI_PROCS"
echo "Solver:    $SOLVER"
echo "Method:    $METHOD"
echo "Backend:   $BACKEND"
echo "MaxIter:   $MAX_ITER"
echo "Tolerance: $TOLERANCE"
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
    --progress-interval 50 \
    --min-iter "$MIN_ITER" 2>&1 | tee "$LOG"

echo
echo "Exporting loaded/unloaded coordinates..."
"$PYTHON_EXE" -u "$EXPORTER" --case-dir "$CASE_DIR" --script "$RUN_SCRIPT" --summary "$COORD_SUMMARY" 2>&1 | tee -a "$LOG"

echo
echo "Done."
echo "Log:     $LOG"
echo "Summary: $SUMMARY"
