# VoxFE-UV 0.41

VoxFE-UV 0.41 is a clean release intended primarily for Windows users. The graphical viewer/editor runs on Windows, while the fastest large-model solver is available for Ubuntu or WSL2 through PETSc/MPI.

## Release Layout

```text
VoxFE/
  01_Windows_VoxFE_UV_0_41/
  02_Ubuntu_WSL_PETSc_MPI_0_41/
  tools/
  VoxFE_UV_0_41_Technical_Documentation_User_Guide.md
  VoxFE_UV_0_41_Technical_Documentation_User_Guide.docx
```

## Recommended Use

| Task | Environment | Launcher |
|---|---|---|
| View, edit, clean and export models | Windows | `01_Windows_VoxFE_UV_0_41/LAUNCH_VoxFE_UV_0_41_WINDOWS.bat` |
| Solve the 304k Macaque validation model | Windows | `RUN_MACAQUE_OLD_WINDOWS_MRBRJAPCG_0_41.bat` |
| Solve any Windows model folder | Windows | copy `SOLVE_THIS_FOLDER_WINDOWS_MRBRJAPCG_0_41.bat` into the folder containing `Script.txt` |
| Solve very large models | Ubuntu/WSL2 | `solve_macaque_2_5m_petsc_mpi_0_41.sh` |

## What Changed in 0.41

- Added `Remove Disconnected Islands` in the Windows GUI.
- Added clean Windows and Ubuntu/WSL release folders.
- Added mandatory solver validation logging.
- Added RAM detection in the Windows 2.5M BAT warning.
- Added `MIN_ITER` support in autorun scripts and PETSc/MPI command line.
- Added default output saving even when the run is not marked `production_valid`.
- Added clearer documentation for the old VoxFE/JAPCG convergence criterion.
- Cleaned the Windows solver dropdown: the GUI now exposes `MRBRJAPCG` only.
- Improved voxel painting/editing responsiveness by throttling drag-time overlay rebuilds and debug-state writes.
- Added `tools/compare_voxfe_displacements.R` for old-vs-new displacement comparison.

## Solver Validation Log

Every solver run now writes the normal console log and a structured validation file:

```text
voxfe_run_validation_log.json
```

The validation log includes:

- force/reaction equilibrium;
- displacement min, max, mean, median, standard deviation and percentiles;
- spatial bounds and voxel size;
- disconnected voxel island report using 6-neighbour face connectivity;
- materials, Young modulus, Poisson ratio and unit reminder;
- convergence summary, including old VoxFE `SigmaNew` and true residual fields when available;
- optional old-vs-new displacement comparison.

To compare a new run against a previous displacement file:

Windows Command Prompt:

```bat
set VOXFE_REFERENCE_DISPLACEMENT=C:\path\to\old\displacement.txt
RUN_MACAQUE_OLD_WINDOWS_MRBRJAPCG_0_41.bat
```

Ubuntu/WSL:

```bash
export VOXFE_REFERENCE_DISPLACEMENT=/home/anton/path/to/old/displacement.txt
MPI_PROCS=4 METHOD=PETSCGAMG bash ./solve_macaque_old_petsc_mpi_0_41.sh
```

For a standalone R comparison after both runs have finished:

```bash
Rscript tools/compare_voxfe_displacements.R old_displacement.txt new_displacement.txt comparison_output old_validation.json new_validation.json
```

The R script reports correlation, RMSE, bias, max error and vector-angle agreement. If validation JSON files are supplied, it also extracts residual/equilibrium-related metrics. The old VoxFEA result is not assumed to be the ground truth.

## Important Notes

The BAT regenerates `Script_autorun...txt` from `Script.txt`, so the cleanest way to set run parameters is either to edit the original `Script.txt`, or set environment variables such as `MIN_ITER` before launching the BAT.

By default, `SKIP_NONCONVERGED_OUTPUTS=0`, meaning the solver writes displacement/reaction outputs even if the stricter `production_valid` flag is false. To avoid writing huge outputs for non-production runs:

```bat
set SKIP_NONCONVERGED_OUTPUTS=1
```

The old VoxFE/JAPCG convergence scalar `SigmaNew` is preserved for compatibility. It is not identical to the true relative residual. For robust validation, inspect `voxfe_run_validation_log.json`, force/reaction balance and the displacement distribution.
