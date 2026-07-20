# VoxFE first-time install tutorial

Release: 2026-07-20

This repository contains two practical distributions as folders:

- `01_Windows_native_FASTJAPCG`
- `02_Windows_WSL2_Ubuntu_PETSc_MPI`

The large P1 models are not included in the repository payload. Both distributions include a lightweight test model:

```text
models/Macaque_light
```

Pure Ubuntu/Linux packaging will be added later.

## Where to put the WSL2 package

For Windows WSL2, use the Linux filesystem, not `/mnt/c/...`, for best performance:

Good WSL2 target paths:

```text
~/voxfe/02_Windows_WSL2_Ubuntu_PETSc_MPI
/root/voxfe/02_Windows_WSL2_Ubuntu_PETSc_MPI
```

Avoid running large solves directly from:

```text
/mnt/c/...
```

because Windows-mounted filesystems are much slower for heavy PETSc/MPI runs.

## WSL2 first install

Tested target: Ubuntu 24.04.

Install system dependencies:

```bash
sudo apt update
sudo apt install -y python3 python3-venv python3-pip python3-numpy python3-scipy \
  python3-petsc4py-real python3-mpi4py openmpi-bin libopenmpi-dev
```

Create a Python environment that can see the Ubuntu PETSc packages:

```bash
cd ~/voxfe/02_Windows_WSL2_Ubuntu_PETSc_MPI
python3 -m venv --system-site-packages .venv_petsc
.venv_petsc/bin/python -m pip install --upgrade pip
.venv_petsc/bin/python -m pip install numba
```

Check PETSc/MPI:

```bash
.venv_petsc/bin/python - <<'PY'
import numpy, scipy, petsc4py, mpi4py
from petsc4py import PETSc
print("NumPy", numpy.__version__)
print("SciPy", scipy.__version__)
print("PETSc", PETSc.Sys.getVersion())
print("petsc4py/mpi4py OK")
PY
```

If running as root in WSL2, OpenMPI needs:

```bash
export OMPI_ALLOW_RUN_AS_ROOT=1
export OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
```

## Run a small test

From the WSL2 distribution folder:

```bash
cd ~/voxfe/02_Windows_WSL2_Ubuntu_PETSc_MPI/models/Macaque_light
PYTHON_EXE=../../.venv_petsc/bin/python \
RELEASE_ROOT=../.. \
MPIEXEC=mpiexec \
MPI_PROCS=2 \
METHOD=PETSCGAMG \
OMPI_ALLOW_RUN_AS_ROOT=1 \
OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 \
sh ./solve_this_folder_petsc_mpi_0_31.sh
```

A successful run writes files such as:

```text
voxfe_solver_summary_petsc_mpi_60000.json
solver_petsc_mpi_60000_stdout.log
```

## Run the macaque model with PETSCGAMG

Start with 2 MPI ranks for the lightweight model.

Example:

```bash
cd ~/voxfe/02_Windows_WSL2_Ubuntu_PETSc_MPI/models/Macaque_light
METHODS=PETSCGAMG \
MPI_PROCS=2 \
PYTHON_EXE=../../.venv_petsc/bin/python \
RELEASE_ROOT=../.. \
MPIEXEC=mpiexec \
OMPI_ALLOW_RUN_AS_ROOT=1 \
OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1 \
timeout 28800 sh ./compare_petsc_mpi_this_folder_0_31.sh
```

The comparison output is written under:

```text
models/Macaque_light/petsc_mpi_comparison_runs/PETSCGAMG
```

## Windows native first install

Recommended location:

```text
C:\VoxFE\01_Windows_native_FASTJAPCG
```

Open the folder and run the included installer/update script if present:

```bat
INSTALL_OR_UPDATE_DEPENDENCIES.bat
```

Use the lightweight model in `models\Macaque_light` for first tests.

## Windows WSL2 first install

1. Install Ubuntu 24.04 from Microsoft Store or with WSL.
2. Configure enough RAM in:

```text
C:\Users\<YOUR_USER>\.wslconfig
```

Example for a high-RAM workstation:

```ini
[wsl2]
memory=180GB
processors=24
swap=64GB
localhostForwarding=true
guiApplications=true
```

3. Restart WSL:

```powershell
wsl --shutdown
```

4. Copy the WSL2 folder into the Linux filesystem:

```bash
mkdir -p ~/voxfe
cd ~/voxfe
cp -a /mnt/c/path/to/VoxFE/02_Windows_WSL2_Ubuntu_PETSc_MPI .
cd 02_Windows_WSL2_Ubuntu_PETSc_MPI
```

5. Follow the Linux install commands above.

## Notes on MPI ranks

`MPI_PROCS` controls how many MPI processes are used.

Recommended benchmark order:

```text
MPI_PROCS=2
MPI_PROCS=4
MPI_PROCS=8
MPI_PROCS=16
```

More ranks can be faster, but not always. Communication overhead and PETSc/GAMG setup can make very high rank counts slower.

## PETSc/GAMG tuning notes

The WSL2 PETSc solver keeps `selected_node_diagnostics.csv` enabled. In the 2026-07-20 optimized build, repeated `SELECT_NODE_3D` diagnostics are cached so validation on the full100 repaired model completes in about 8 seconds on the tested WSL2 setup.

For large elasticity models, PETSc/GAMG is sensitive to the vector nature of the problem. The solver now sets PETSc matrix block size to 3 for 3D displacement DOFs.

Optional experimental variables:

```bash
export VOXFE_PETSC_GAMG_THRESHOLD=0.05
export VOXFE_PETSC_GAMG_COORDINATES=1
export VOXFE_PETSC_NEAR_NULLSPACE=1
```

Recommended order for benchmarking on a high-RAM machine:

```text
baseline: no optional variables
threshold: VOXFE_PETSC_GAMG_THRESHOLD=0.02, then 0.05, then 0.08
coordinates: add VOXFE_PETSC_GAMG_COORDINATES=1
near-nullspace: test only after the previous cases, because it can change GAMG stability
```

Always check `production_valid`, `solution_valid`, and `residual_norm_relative` in the JSON summary. PETSc can report KSP convergence with an internal norm while the final physical residual check remains stricter.

## Troubleshooting

If PETSc import fails inside the virtual environment, recreate it with:

```bash
python3 -m venv --system-site-packages .venv_petsc
```

Do not use a venv that installs incompatible NumPy/SciPy versions over the Ubuntu PETSc packages.

If OpenMPI refuses to run as root, set:

```bash
export OMPI_ALLOW_RUN_AS_ROOT=1
export OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1
```
