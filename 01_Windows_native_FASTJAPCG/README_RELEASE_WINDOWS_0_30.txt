VoxFE-UV 0.30 Windows FASTJAPCG release
=======================================

This package contains only one scenario:

  P1

at three model resolutions:

  models\P1_linear_25
  models\P1_linear_50
  models\P1_full_100

Recommended setup:

  INSTALL_OR_UPDATE_DEPENDENCIES.bat

Recommended solver:

  FASTJAPCG

FASTJAPCG uses:

  sparse_scipy backend
  Numba-accelerated element COO assembly
  Jacobi-preconditioned CG solve

Run a model without the viewer:

  open one models\P1_* folder
  run RUN_SOLVE_THIS_FOLDER_FASTJAPCG_60000.bat

Run the viewer:

  LAUNCH_VoxFE_UV_0_30_WINDOWS.bat

Install as a Windows app:

  INSTALL_WINDOWS_APP_0_31.bat

This creates a Start Menu shortcut, a Desktop shortcut and the user command:

  voxfe-uv

The release folder remains the real application folder. If you move it, run
INSTALL_WINDOWS_APP_0_31.bat again from the new location.

To remove only shortcuts and the terminal command:

  UNINSTALL_WINDOWS_APP_0_31.bat

The solver method dropdown includes FASTJAPCG, PETSCJAPCG, PETSCGAMG, PETSCLU, ROWJAPCG, FASTMG, MATRIXFREE, JAPCG, AMGCG, CG, SPSOLVE.

PETSc methods are intended for the Linux release.
