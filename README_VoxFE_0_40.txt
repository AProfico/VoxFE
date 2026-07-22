VoxFE 0.40 clean release

This release is designed primarily for Windows users.
The graphical program runs on Windows, while the fastest solver for large models can be launched from Ubuntu through WSL2.

Folder layout:

01_Windows_VoxFE_UV_0_40
- Windows graphical viewer/editor.
- Windows solver: MRBRJAPCG.
- Local .venv included, so the app can be launched without rebuilding the Python environment.
- Example models only. Old logs, old displacement files, cache files and experimental solver builds are intentionally excluded.

02_Ubuntu_WSL_PETSc_MPI_0_40
- Solver folder for Ubuntu, WSL2 or native Linux.
- Linux solver: PETSCGAMG through PETSc/MPI.
- MRBRJAPCG package included only as a compatibility/reference solver.
- Example models only.

What to use:
- For opening/editing/checking models: use Windows and launch LAUNCH_VoxFE_UV_0_40_WINDOWS.bat.
- For solving medium models on Windows: use RUN_MACAQUE_OLD_WINDOWS_MRBRJAPCG_0_40.bat.
- For large models: copy the Ubuntu folder into WSL2 and use PETSCGAMG.

Windows requirements:
- Windows 10 or Windows 11.
- The included .venv should already contain the needed Python libraries for the viewer.
- If the environment is missing or damaged, install Python 3.11 or 3.12 from python.org and run INSTALL_OR_UPDATE_DEPENDENCIES.bat inside 01_Windows_VoxFE_UV_0_40.
- Required Windows Python libraries are listed in requirements.txt.

Ubuntu / WSL2 requirements:
- WSL2 with Ubuntu installed.
- Miniforge or Miniconda.
- A conda environment with python, numpy, scipy, mpi4py, petsc, petsc4py and openmpi.

Recommended Ubuntu setup:
1. Open Ubuntu.
2. Install Miniforge if needed:
   wget -O Miniforge3.sh https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
   bash Miniforge3.sh
   source ~/miniforge3/etc/profile.d/conda.sh

3. Create the solver environment:
   conda create -n voxfe-petsc-mpi -c conda-forge python=3.11 numpy scipy mpi4py petsc petsc4py openmpi -y

4. Activate it:
   source ~/miniforge3/etc/profile.d/conda.sh
   conda activate voxfe-petsc-mpi

5. Copy the Ubuntu solver folder into Ubuntu home:
   cp -r "/mnt/c/path/to/VoxFE_0.40/02_Ubuntu_WSL_PETSc_MPI_0_40" ~/VoxFE_0.40

6. Run a model:
   cd ~/VoxFE_0.40
   MPI_PROCS=4 METHOD=PETSCGAMG bash ./solve_macaque_old_petsc_mpi_0_40.sh

Important solver notes:
- Windows MRBRJAPCG was validated against the old VoxFEA solver on the Macaque test case when the same material constants are used.
- Ubuntu PETSCGAMG is expected to be better for very large models, but memory usage depends strongly on model size, constraint layout and preconditioner construction.
- On a 32 GB RAM machine, start with MPI_PROCS=4. Do not jump immediately to 12 or more ranks.

Important material fix in 0.40:
- Legacy YOUNG_MODULUS and POISSON_RATIO script entries are preserved correctly.
- Default material names are neutral: MATERIAL_1, MATERIAL_2, MATERIAL_3, etc.
- Legacy names like BONE and METAL are still accepted for old scripts, but material 2 is not automatically treated as metal.
