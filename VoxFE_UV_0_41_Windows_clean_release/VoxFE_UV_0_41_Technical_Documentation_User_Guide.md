# VoxFE-UV 0.41 Technical Documentation and User Guide

## Purpose

VoxFE-UV is a voxel-based finite element analysis workflow for segmented 3D models. The Windows application is used to inspect, edit and export models, while the solver can be run either on Windows or on Ubuntu/WSL2.

Version 0.41 focuses on a cleaner release structure, faster validated solvers and stronger run validation logs.

## Voxel-Based FEA in Brief

A voxel model represents a solid as a regular grid of cubic or cuboid elements. Each occupied voxel becomes one finite element. The mechanical problem is assembled as:

```text
K u = f
```

where:

- `K` is the global stiffness operator;
- `u` is the unknown displacement vector;
- `f` is the applied force vector.

For a 3D linear elastic model, each active node has three translational degrees of freedom:

```text
u_node = [ux, uy, uz]
```

The displacement field describes how each node moves under load. Strain is derived from spatial gradients of displacement. Stress is derived from strain and the elastic material law:

```text
epsilon = B u_e
sigma = D epsilon
```

Here `B` is the strain-displacement matrix and `D` is the elastic constitutive matrix defined by Young modulus and Poisson ratio.

## Units

VoxFE does not magically infer a physical unit system. The user must keep units consistent:

- voxel size;
- Young modulus;
- force magnitude;
- displacement interpretation.

If Young modulus is in Pa and force is in N, voxel size should be in metres. If voxel size is accidentally exported as `1 1 1` instead of the real spacing, displacement magnitude will be physically wrong.

## Materials

Materials are identified numerically:

```text
MATERIAL 1 MATERIAL_1 1.7e10 0.3
MATERIAL 2 MATERIAL_2 1.2e10 0.3
```

The material name is descriptive. The behaviour comes from:

- material ID;
- Young modulus;
- Poisson ratio.

Legacy names such as `BONE` and `METAL` are accepted for compatibility, but material 2 is not automatically interpreted as metal.

## Script Example

Minimal beam-like example:

```text
LOAD_MCTSCAN 20 4 4 model.txt
VOXEL_SIZE 0.001 0.001 0.001
MATERIAL 1 MATERIAL_1 1.7e10 0.3
ALGORITHM_FEA MRBRJAPCG
MAX_ITER 60000
MIN_ITER 100
TOLERANCE 1e-06
COMPUTE_SED false
SELECTION_OF_NODES
SELECT_NODE_3D 0 0 0 0 0 0 1 1 1
SELECT_NODE_3D 20 4 4 0 -10 0 0 0 0
PRINT_X displacement.txt
REACTION force.txt
```

Line meaning:

- `LOAD_MCTSCAN`: grid dimensions and model file.
- `VOXEL_SIZE`: physical voxel spacing.
- `MATERIAL`: material ID, name, Young modulus and Poisson ratio.
- `ALGORITHM_FEA`: solver method.
- `MAX_ITER`: maximum iterations.
- `MIN_ITER`: minimum iterations before accepting convergence.
- `TOLERANCE`: convergence tolerance.
- `COMPUTE_SED`: whether to compute strain energy density.
- `SELECT_NODE_3D`: node coordinate, force vector and lock flags.
- `PRINT_X`: displacement output.
- `REACTION`: force/reaction output.

## Model File Example

```text
0.001 0.001 0.001
4
0 1 0 0 0
1 1 1 0 0
2 1 2 0 0
3 1 3 0 0
```

Line meaning:

- first line: voxel size, if present;
- second line: voxel count;
- remaining lines: `element_id material_id x y z`.

Legacy files without a voxel-size row are still supported. In that case the script or GUI fallback voxel size is used.

## Displacement File

The standard displacement file contains one row per renumbered node:

```text
Node : X Y Z
0 : 1.2e-08 -3.1e-07 0.0
1 : 1.4e-08 -3.0e-07 0.0
```

The solver also writes:

- `displacement_standard.txt`;
- `displacement_standard_with_coords.txt`;
- `voxel_coordinates_loaded.tsv`;
- `voxel_coordinates_unloaded.tsv`.

The `with_coords` file is the most useful for checking spatial plausibility because it contains node coordinates and displacement components.

## Solvers

### Windows: MRBRJAPCG

MRBRJAPCG uses a VOX-FE-style modified row-by-row sparse assembly and Jacobi-preconditioned conjugate gradient. It is the current clean Windows solver because it matches the old VoxFEA workflow more closely than generic sparse assembly.

### Ubuntu/WSL2: PETSCGAMG

PETSCGAMG uses PETSc/MPI with a GAMG multigrid preconditioner. It is the preferred path for larger models. Version 0.41 passes elastic-problem hints such as block size 3 and coordinate information where available.

### Excluded Solvers

Older experimental choices such as `SPSOLVE`, `FASTJAPCG`, `ROWJAPCG` and generic `CG` are intentionally not exposed in the clean release to reduce confusion.

## Convergence

The old VoxFE/JAPCG criterion is preserved:

```text
SigmaEnd = number_of_equations * tolerance^2
```

`SigmaNew` is a Jacobi-preconditioned scalar criterion, not the same as the true relative residual. This matters because `SigmaNew` can start close to `1e-6` when the system is strongly scaled or when the force vector is small.

The 0.41 validation log therefore reports both the legacy fields and true residual fields when the backend can provide them:

- `old_voxfe_sigma_new_initial`;
- `old_voxfe_sigma_new_final`;
- `old_voxfe_sigma_end`;
- `residual_norm_absolute`;
- `residual_norm_relative`;
- `production_valid`.

## Validation Log

Every solver run writes:

```text
voxfe_run_validation_log.json
```

It includes:

- force/reaction equilibrium;
- displacement minimum, maximum, mean, median, standard deviation and percentiles;
- spatial bounds and voxel size;
- disconnected voxel islands using 6-neighbour face connectivity;
- material IDs, names, Young modulus and Poisson ratio;
- convergence data;
- optional old-vs-new displacement comparison.

For equilibrium, the key check is:

```text
total_applied_force + total_reaction approximately equals 0
```

For old-vs-new comparison, set:

```text
VOXFE_REFERENCE_DISPLACEMENT=/path/to/old/displacement.txt
```

before launching the solver.

## Saving Displacement Before Full Validation

Important: the BAT regenerates `Script_autorun...txt` from `Script.txt`, so the cleanest way is either edit the original `Script.txt`, or set `MIN_ITER` before launching the BAT.

By default:

```text
SKIP_NONCONVERGED_OUTPUTS=0
```

This means displacement and reaction files are written even if the stricter `production_valid` flag is false. To suppress large output files unless the run is production-valid:

```text
SKIP_NONCONVERGED_OUTPUTS=1
```

## Remove Disconnected Islands

In the Windows GUI:

```text
File > Remove Disconnected Islands
Tools > Remove Disconnected Islands
```

The tool keeps the largest face-connected voxel component and removes isolated components. It can export a cleaned model to a new folder or overwrite the current model after creating a timestamped backup.

The cleaned export also filters `Script.txt` and `project.json` so force/constraint references to removed voxels do not remain silently in the case.

## Recommended Workflow

1. Open the model in Windows.
2. Check voxel size and material properties.
3. Import or edit force and constraint groups.
4. Remove disconnected islands if the model contains isolated fragments.
5. Export the project/script.
6. Solve with Windows MRBRJAPCG for medium models or Ubuntu PETSCGAMG for large models.
7. Inspect `voxfe_run_validation_log.json`.
8. Load displacement in the GUI and check shape, scale and plausibility.

