VoxFE 0.40 - Ubuntu / WSL2 solver release

This folder is intended to be copied into Ubuntu or WSL2.
The graphical application is Windows-first, while the fastest large-model solver is available here through PETSc/MPI.

Recommended solver:
- PETSCGAMG for large voxel models.
- MPI_PROCS=4 is a safe starting point on a 32 GB RAM laptop.
- Increase MPI_PROCS only if memory remains comfortable.

First-time Ubuntu/WSL setup:
1. Install Miniforge in Ubuntu if it is not installed yet:
   wget -O Miniforge3.sh https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
   bash Miniforge3.sh
   source ~/miniforge3/etc/profile.d/conda.sh

2. Create the PETSc/MPI environment:
   conda create -n voxfe-petsc-mpi -c conda-forge python=3.11 numpy scipy mpi4py petsc petsc4py openmpi -y

3. Activate it:
   source ~/miniforge3/etc/profile.d/conda.sh
   conda activate voxfe-petsc-mpi

Run the old Macaque validation model:
   cd ~/VoxFE_0.40/02_Ubuntu_WSL_PETSc_MPI_0_40
   MPI_PROCS=4 METHOD=PETSCGAMG bash ./solve_macaque_old_petsc_mpi_0_40.sh

Run the 2.5M Macaque model:
   cd ~/VoxFE_0.40/02_Ubuntu_WSL_PETSc_MPI_0_40
   MPI_PROCS=4 METHOD=PETSCGAMG bash ./solve_macaque_2_5m_petsc_mpi_0_40.sh

Outputs are written inside each model folder:
- displacement.txt
- force.txt
- sed.csv
- residual_history.csv
- voxfe_solver_summary_*.json
- voxel_coordinates_loaded.tsv
- voxel_coordinates_unloaded.tsv

Note for Windows users:
If the folder is on Windows, copy it into Ubuntu home before solving:
   cp -r "/mnt/c/path/to/VoxFE_0.40/02_Ubuntu_WSL_PETSc_MPI_0_40" ~/VoxFE_0.40

Running from the Ubuntu filesystem is usually faster and avoids Windows/WSL file I/O overhead.
