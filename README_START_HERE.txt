VoxFE-UV latest Windows + Windows WSL2 package
Generated: 2026-07-20

Folders:

01_Windows_native_FASTJAPCG
  Native Windows release. Use this for GUI and compatibility runs.
  Main launcher: LAUNCH_VoxFE_UV_0_30_WINDOWS.bat
  Installer: INSTALL_WINDOWS_APP_0_31.bat
  Solver focus: sparse_scipy + FASTJAPCG/ROWJAPCG/CG/SPSOLVE.

02_Windows_WSL2_Ubuntu_PETSc_MPI
  Ubuntu/WSL2 PETSc-MPI release. Use this for fast full-model solves.
  Main solver: SOLVER_0_4_petsc_mpi.pyz
  Setup/tutorial: LINUX_PETSC_MPI_TUTORIAL_0_31.txt
  Main run script inside case folders: solve_this_folder_petsc_mpi_0_31.sh
  Solver focus: PETSc/MPI direct distributed assembly with PETSCGAMG or PETSCJAPCG.

Extra scripts copied at package root:
  RUN_WINDOWS_FULL100_BENCHMARK.bat / .ps1
    Runs the full P1 model on native Windows with FASTJAPCG and writes logs to Documents\Codex\windows_full100_benchmark.

  run_full_100_wsl_tuned.sh
  RUN_FULL_100_WSL_TUNED_COMMAND.txt
    Tuned WSL2 full-model runner prepared for PETSc/MPI testing.

Recommendation:
  Use Windows native mainly for the GUI and smaller/compatibility tests.
  Use WSL2 Ubuntu PETSc/MPI for serious full-resolution solving, because assembly and parallel sparse solve are much faster there.
