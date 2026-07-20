#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"

echo "VoxFE-UV Linux PETSc setup"
echo
echo "Recommended: use conda/mamba with conda-forge for PETSc."
echo
echo "If conda is available, run:"
echo "  conda create -n voxfe-petsc -c conda-forge python=3.12 numpy scipy petsc petsc4py mpi4py numba pyamg pyvista vtk pillow imageio"
echo "  conda activate voxfe-petsc"
echo
echo "This script creates a local .venv and tries pip install. On some Linux systems petsc4py may need system PETSc packages."
echo

PYTHON_CMD="${PYTHON:-python3}"
"$PYTHON_CMD" -m venv .venv
PYTHON_EXE=".venv/bin/python"
"$PYTHON_EXE" -m pip install --upgrade pip
"$PYTHON_EXE" -m pip install --prefer-binary -r requirements_linux_petsc.txt

"$PYTHON_EXE" -c "import numpy, scipy; from petsc4py import PETSc; print('PETSc', PETSc.Sys.getVersion()); print('Linux PETSc dependencies OK')"
echo
echo "Setup complete."
