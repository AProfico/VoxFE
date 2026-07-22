VoxFE-UV 0.40 - Windows clean release

This is the main folder for a Windows user.
Use it to open the graphical application, import/export scripts, inspect results and run the validated Windows solver.

Included files:
- VoxFE_UV_0_40.pyz: graphical viewer/editor.
- SOLVER_0_40_mrbrjapcg.pyz: Windows solver using VOX-FE-style Modified Row-By-Row assembly + JAPCG.
- .venv: ready Python environment.
- models: clean example cases, without old result files.

Quick start:
1. Double-click LAUNCH_VoxFE_UV_0_40_WINDOWS.bat.
2. Open a model or import a project/script from the graphical interface.
3. Use the app to check materials, voxel size, force groups and constraints before solving.

Run the included validation model:
1. Double-click RUN_MACAQUE_OLD_WINDOWS_MRBRJAPCG_0_40.bat.
2. Wait for the solver to finish.
3. Outputs are written inside models\Macaque_old_model.

Run the 2.5M model on Windows:
1. Double-click RUN_MACAQUE_2_5M_WINDOWS_MRBRJAPCG_0_40.bat.
2. This model is large. On 32 GB RAM it may be slow or memory-limited.
3. For this model, Ubuntu/WSL2 with PETSc/MPI is usually the better route.

If the app does not start:
1. Install Python 3.11 or Python 3.12 for Windows.
2. Run INSTALL_OR_UPDATE_DEPENDENCIES.bat.
3. Launch LAUNCH_VoxFE_UV_0_40_WINDOWS.bat again.

Solver choice:
- MRBRJAPCG is the only Windows solver included in this clean release.
- It was selected because it is the current validated path against the old VoxFEA result.
- FASTJAPCG, ROWJAPCG, MFJAPCG and SPSOLVE are intentionally excluded to avoid confusion.

Material handling:
- Materials are named neutrally as MATERIAL_1, MATERIAL_2, etc.
- Legacy script names like BONE and METAL are still accepted on import.
- The actual material stiffness comes from the material ID and its Young modulus, not from the label.
