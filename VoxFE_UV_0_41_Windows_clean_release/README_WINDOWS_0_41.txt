VoxFE-UV 0.41 - Windows clean release

This folder is the main Windows user interface release.

Included files:
- VoxFE_UV_0_41.pyz: graphical viewer/editor.
- SOLVER_0_41_mrbrjapcg.pyz: Windows MRBRJAPCG solver.
- INSTALL_OR_UPDATE_DEPENDENCIES.bat: creates/updates the local Python environment.
- models: clean example cases.

Windows solver menu:
- The clean 0.41 GUI exposes MRBRJAPCG only.
- Older experimental methods and direct SPSOLVE were removed from the dropdown to avoid launching the wrong solver package.
- Ubuntu/WSL PETSCGAMG is available in the separate 02_Ubuntu_WSL_PETSc_MPI_0_41 folder.

Quick start:
1. Double-click LAUNCH_VoxFE_UV_0_41_WINDOWS.bat.
2. Open a model, project or script in the GUI.
3. Check voxel size, materials, force groups and constraints before solving.
4. If needed, use File or Tools > Remove Disconnected Islands.

Run the included 304k Macaque validation model:
1. Double-click RUN_MACAQUE_OLD_WINDOWS_MRBRJAPCG_0_41.bat.
2. Outputs are written inside models\Macaque_old_model.

Run any model folder:
1. Copy SOLVE_THIS_FOLDER_WINDOWS_MRBRJAPCG_0_41.bat into the folder containing Script.txt.
2. Double-click it.
3. If the model folder is outside this release, set VOXFE_RELEASE_DIR first:
   set VOXFE_RELEASE_DIR=C:\path\to\01_Windows_VoxFE_UV_0_41
4. Outputs and logs are written in the same model folder.

Run the 2.5M Macaque model:
1. Double-click RUN_MACAQUE_2_5M_WINDOWS_MRBRJAPCG_0_41.bat.
2. The BAT detects installed RAM and warns if the machine is likely memory-limited.
3. For very large models, Ubuntu/WSL2 PETSc/MPI is usually preferred.

Outputs:
- displacement.txt
- displacement_standard.txt
- displacement_standard_with_coords.txt
- force.txt
- residual_history.csv
- voxfe_solver_summary_*.json
- voxfe_run_validation_log.json

Validation log:
Every solver run writes voxfe_run_validation_log.json. It reports force/reaction balance, displacement statistics, spatial distribution, disconnected islands, material definitions, unit reminders and convergence metrics.

Old-vs-new displacement comparison:
Before launching a BAT, set:
  set VOXFE_REFERENCE_DISPLACEMENT=C:\path\to\old\displacement.txt

The validation log will then include mean, max and RMS vector differences.

Standalone R comparison:
From the repository root, after installing R:
  Rscript tools\compare_voxfe_displacements.R old_displacement.txt new_displacement.txt comparison_output old_validation.json new_validation.json

The R script compares displacement correlation, RMSE, bias, max error and vector direction. If validation JSON files are provided, it also extracts residual/equilibrium metrics. The old VoxFEA result is not treated as ground truth.

MIN_ITER:
The BAT regenerates Script_autorun...txt from Script.txt. To force a minimum number of solver iterations, either add this to Script.txt:
  MIN_ITER 1580

or set it before launching:
  set MIN_ITER=3000

Save displacement even if not production-valid:
By default:
  SKIP_NONCONVERGED_OUTPUTS=0

This writes displacement/reaction outputs even if the stricter production_valid flag is false. To skip huge outputs when validation fails:
  set SKIP_NONCONVERGED_OUTPUTS=1

Convergence:
The solver preserves the old VoxFE/JAPCG SigmaNew criterion for compatibility:
  SigmaEnd = number_of_equations * tolerance^2

SigmaNew is a Jacobi-preconditioned scalar criterion, not the same as the true relative residual. Always inspect voxfe_run_validation_log.json for force/reaction balance and displacement statistics.
