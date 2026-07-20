VoxFE-UV 0.31 Linux PETSc/MPI release
=====================================

Linux-only release with experimental direct PETSc/MPI matrix assembly.

Included scenario
-----------------

Only P1 is included:

  models/P1_linear_25
  models/P1_linear_50
  models/P1_full_100

Main solver
-----------

  SOLVER_0_4_petsc_mpi.pyz

Default Linux run script
------------------------

From inside a model folder:

  sh ../../solve_this_folder_petsc_mpi_0_31.sh

Defaults:

  backend: petsc_optional
  method:  PETSCGAMG
  ranks:   MPI_PROCS=2
  max iter: 60000

Examples:

  MPI_PROCS=4 sh ../../solve_this_folder_petsc_mpi_0_31.sh
  METHOD=PETSCJAPCG MPI_PROCS=4 sh ../../solve_this_folder_petsc_mpi_0_31.sh
  METHOD=PETSCLU MPI_PROCS=2 sh ../../solve_this_folder_petsc_mpi_0_31.sh

Tutorial
--------

Read:

  LINUX_PETSC_MPI_TUTORIAL_0_31.txt

Ubuntu app launcher
-------------------

From the release root:

  sh install_ubuntu_app_0_31.sh

This adds VoxFE-UV to the Ubuntu application menu and creates the terminal command:

  voxfe-uv

To remove only the menu/terminal launcher:

  sh uninstall_ubuntu_app_0_31.sh

Implementation note
-------------------

The PETSc backend now assembles a distributed AIJ matrix directly in PETSc/MPI.
The model parser is still replicated on each rank. Output files are written only
by rank 0 to avoid file-write collisions under mpiexec.
