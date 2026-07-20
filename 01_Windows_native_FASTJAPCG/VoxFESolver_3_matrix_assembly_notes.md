# VoxFESolver 3.0 RC2 matrix assembly notes

Inspected binary:

`C:\Users\anton\Downloads\ParaView-VoxFE-3.0.0-RC2-Linux-64bit\voxfe\solver\VoxFESolver`

## Binary facts

- ELF 64-bit Linux executable.
- Size: 47,241,984 bytes.
- Timestamp in extracted folder: 2021-07-26 16:02:15.
- The solver folder also contains `mpich`, `lib`, `cartesiansortmodel`, and `sortdisplacements`.
- The binary includes PETSc 3.7.3, MPICH, ParMETIS and METIS strings.
- The binary still contains symbols and debug strings.

## Relevant functions found

- `pFESolver::LoadModel(char const*)`
- `pFESolver::AddElement(int, unsigned int, unsigned int, unsigned int, unsigned int, int const*, int)`
- `pFESolver::SimpleRenumberNodes()`
- `pFESolver::CountNodeNeighbours(...)`
- `pFESolver::GetAllNodeNeighbours(int*, int)`
- `pFESolver::AllocateLocalMatrix(_p_Mat**)`
- `pFESolver::ComputeGSM(_p_Mat**)`
- `pFESolver::ComputeRHS(_p_Vec**)`
- `pFESolver::FinaliseForceConstraints()`
- `pFESolver::Solve()`
- `pFESolver::ParPrintDisplacements(...)`
- `pFESolver::ParPrintDisplacementsMPIIO(...)`

## Important runtime strings

- `Creating Element and Node Sets, Model file=%s`
- `MATGETSIZE:GSM:rows=%d, cols=%d`
- `ERROR [GetAllNodeNeighbours] : total number of neighbours exceeded!`
- `GSM local : first row=%d, last row=%d`
- `finished creating ISCreateGeneral() for rows`
- `finished creating MatGetSubMatrix()`
- `GSM local info : mal = ..., non-zero_allocated = ..., non-zero_used = ...`
- `starting GSM formation`
- `finished GSM formation`
- `finished CONS_GSM formation`
- `Created KSP`
- `KSPConvergedReason`

## Interpretation

This 3.0 solver does not appear to use the old `PARA_BMU` MRBR path (`BuildGSMRV`, `BuildGM`, `MRBR_MatrixVectorMUL`, `BuildMinverse`). Instead it follows the PETSc global sparse matrix design already visible in the VOX-FE 2.0/2.0.1 sources, but with more MPI/distributed machinery:

- create local element and node sets;
- exchange missing/ghost nodes and elements across ranks;
- count node neighbours for matrix preallocation;
- allocate a PETSc matrix with local row ownership;
- assemble `GSM` row-wise;
- build a constrained matrix/submatrix with `ISCreateGeneral()` and `MatGetSubMatrix()`;
- solve through PETSc `KSP`.

The useful idea for the Python solver is therefore not a hidden matrix-free method from this binary, but a row-wise, neighbour-aware assembly path. This avoids first creating a very large duplicate COO list for every element contribution, then asking SciPy to collapse duplicates.

## Implemented Python follow-up

The Python solver now includes a row-wise sparse assembly path selected by methods containing `ROW` or `VOXFE`, for example:

- `ROWJAPCG`
- `ROWCG`
- `ROWAMG`

These methods keep the existing sparse SciPy solve logic, but build the global CSR matrix by visiting active nodes and incident elements in the same style as VOX-FE/PETSc.
