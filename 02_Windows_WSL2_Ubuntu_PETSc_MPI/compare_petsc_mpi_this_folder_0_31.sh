#!/usr/bin/env sh
set -eu

CASE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
RELEASE_ROOT="${RELEASE_ROOT:-$(CDPATH= cd -- "$CASE_DIR/../.." 2>/dev/null && pwd)}"
METHODS="${METHODS:-PETSCGAMG,PETSCJAPCG,PETSCLU}"
MPI_PROCS="${MPI_PROCS:-2}"

echo "PETSc/MPI comparison in: $CASE_DIR"
echo "Methods: $METHODS"
echo "MPI ranks: $MPI_PROCS"
echo

OLD_IFS=$IFS
IFS=,
for method in $METHODS; do
    IFS=$OLD_IFS
    METHOD=$(printf "%s" "$method" | tr -d "[:space:]")
    if [ -z "$METHOD" ]; then
        continue
    fi
    RUN_DIR="$CASE_DIR/petsc_mpi_comparison_runs/$METHOD"
    rm -rf "$RUN_DIR"
    mkdir -p "$RUN_DIR"
    cp "$CASE_DIR/Script.txt" "$RUN_DIR/Script.txt"
    find "$CASE_DIR" -maxdepth 1 -type f \( -name "*model*.txt" -o -name "Macaque_model.txt" -o -name "human_mandible_model.txt" \) -exec cp {} "$RUN_DIR/" \;
    cp "$RELEASE_ROOT/solve_this_folder_petsc_mpi_0_31.sh" "$RUN_DIR/solve_this_folder_petsc_mpi_0_31.sh"
    echo "Running $METHOD in $RUN_DIR"
    (cd "$RUN_DIR" && RELEASE_ROOT="$RELEASE_ROOT" METHOD="$METHOD" MPI_PROCS="$MPI_PROCS" sh ./solve_this_folder_petsc_mpi_0_31.sh)
    IFS=,
done
IFS=$OLD_IFS

echo
echo "Comparison runs written to: $CASE_DIR/petsc_mpi_comparison_runs"
