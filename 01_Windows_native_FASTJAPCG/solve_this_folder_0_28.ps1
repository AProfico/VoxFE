param(
    [string]$CaseDir = "",
    [string]$PythonRoot = "C:\FEA SIMONA\VoxFE_UV_0_25_runnable",
    [string]$ReleaseRoot = "",
    [int]$MaxIter = 60000,
    [string]$Method = "ROWJAPCG",
    [string]$Backend = "sparse_scipy",
    [string]$Threads = "auto",
    [string]$ProgressInterval = "50"
)

$ErrorActionPreference = "Stop"

function Resolve-Python {
    param([string]$Root)
    $venvPython = Join-Path $Root ".venv\Scripts\python.exe"
    if (Test-Path -LiteralPath $venvPython) {
        return $venvPython
    }
    $py = Get-Command py -ErrorAction SilentlyContinue
    if ($py) {
        return "py"
    }
    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) {
        return "python"
    }
    throw "Python was not found. Run INSTALL_OR_UPDATE_DEPENDENCIES.bat first."
}

function Select-CaseScript {
    param([string]$Folder)
    $scriptTxt = Join-Path $Folder "Script.txt"
    if (Test-Path -LiteralPath $scriptTxt) {
        return $scriptTxt
    }
    $edited = Get-ChildItem -LiteralPath $Folder -File |
        Where-Object { $_.Name -like "*_Script_edited.txt" } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($edited) {
        return $edited.FullName
    }
    $script = Get-ChildItem -LiteralPath $Folder -File |
        Where-Object { $_.Name -like "*_Script.txt" } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($script) {
        return $script.FullName
    }
    throw "No Script.txt or *_Script*.txt found in $Folder"
}

function Write-RunScript {
    param(
        [string]$SourceScript,
        [string]$TargetScript,
        [int]$MaxIter,
        [string]$Method
    )
    $lines = Get-Content -LiteralPath $SourceScript
    $hasMaxIter = $false
    $hasAlgorithm = $false
    $updated = foreach ($line in $lines) {
        if ($line -match '^\s*ALGORITHM_FEA\s+') {
            $hasAlgorithm = $true
            "ALGORITHM_FEA $Method"
        } elseif ($line -match '^\s*MAX_ITER\s+') {
            $hasMaxIter = $true
            "MAX_ITER $MaxIter"
        } else {
            $line
        }
    }
    if (-not $hasAlgorithm) {
        $inserted = New-Object System.Collections.Generic.List[string]
        $done = $false
        foreach ($line in $updated) {
            $inserted.Add($line)
            if (-not $done -and $line -match '^\s*VOXEL_SIZE\s+') {
                $inserted.Add("ALGORITHM_FEA $Method")
                $done = $true
            }
        }
        if (-not $done) {
            $inserted.Insert(0, "ALGORITHM_FEA $Method")
        }
        $updated = $inserted
    }
    if (-not $hasMaxIter) {
        $inserted = New-Object System.Collections.Generic.List[string]
        $done = $false
        foreach ($line in $updated) {
            $inserted.Add($line)
            if (-not $done -and $line -match '^\s*ALGORITHM_FEA\s+') {
                $inserted.Add("MAX_ITER $MaxIter")
                $done = $true
            }
        }
        if (-not $done) {
            $inserted.Insert(0, "MAX_ITER $MaxIter")
        }
        $updated = $inserted
    }
    Set-Content -LiteralPath $TargetScript -Value $updated -Encoding UTF8
}

function First-ExistingPath {
    param([string[]]$Candidates)
    foreach ($candidate in $Candidates) {
        if (-not [string]::IsNullOrWhiteSpace($candidate) -and (Test-Path -LiteralPath $candidate)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    return ""
}

if ([string]::IsNullOrWhiteSpace($CaseDir)) {
    $CaseDir = $PSScriptRoot
}
$CaseDir = (Resolve-Path -LiteralPath $CaseDir).Path

if ([string]::IsNullOrWhiteSpace($ReleaseRoot)) {
    $ReleaseRoot = First-ExistingPath @(
        (Join-Path $CaseDir "VoxFE_UV_0_26_runnable_complete"),
        (Join-Path $CaseDir "..\VoxFE_UV_0_26_runnable_complete"),
        (Join-Path $CaseDir "..\..\VoxFE_UV_0_26_runnable_complete"),
        "C:\Users\anton\Documents\Codex\2026-07-17\analizza-e-modifica-l-interfaccia-del\outputs\VoxFE_UV_0_26_runnable_complete"
    )
}
if ([string]::IsNullOrWhiteSpace($ReleaseRoot)) {
    throw "Release folder was not found. Put this BAT/PS1 beside the release folder or pass -ReleaseRoot."
}

$python = Resolve-Python -Root $PythonRoot
$solver = First-ExistingPath @(
    (Join-Path $CaseDir "SOLVER_0_2_fast.pyz"),
    (Join-Path $ReleaseRoot "SOLVER_0_2_fast.pyz"),
    (Join-Path $ReleaseRoot "SOLVER_0_1.pyz")
)
if ([string]::IsNullOrWhiteSpace($solver)) {
    throw "SOLVER_0_2_fast.pyz was not found."
}

$exporter = First-ExistingPath @(
    (Join-Path $CaseDir "export_loaded_unloaded_coordinates.py"),
    (Join-Path $ReleaseRoot "export_loaded_unloaded_coordinates.py"),
    "C:\Users\anton\Documents\Codex\2026-07-17\analizza-e-modifica-l-interfaccia-del\outputs\export_loaded_unloaded_coordinates.py"
)
if ([string]::IsNullOrWhiteSpace($exporter)) {
    throw "Coordinate exporter was not found."
}

$sourceScript = Select-CaseScript -Folder $CaseDir
$runScript = Join-Path $CaseDir "Script_autorun_single_60000.txt"
$summary = Join-Path $CaseDir "voxfe_solver_summary_single_60000.json"
$log = Join-Path $CaseDir "solver_single_60000_stdout.log"
$coordSummary = Join-Path $CaseDir "coordinate_export_summary_single.json"

Write-RunScript -SourceScript $sourceScript -TargetScript $runScript -MaxIter $MaxIter -Method $Method

$env:PYTHONUNBUFFERED = "1"
$env:PYTHONIOENCODING = "utf-8"

Write-Host "Solving only this folder:"
Write-Host "  $CaseDir"
Write-Host ""
Write-Host "Python:"
Write-Host "  $python"
Write-Host "Solver:"
Write-Host "  $solver"
Write-Host "Script:"
Write-Host "  $runScript"
Write-Host "Method: $Method"
Write-Host "Backend: $Backend"
Write-Host "Max iterations: $MaxIter"
Write-Host "Output: real-time console plus log"
Write-Host "Log:"
Write-Host "  $log"
Write-Host ""

Push-Location $CaseDir
try {
    $started = Get-Date
    $args = @($solver, (Split-Path -Leaf $runScript), "--backend", $Backend, "--algorithm", $Method, "--threads", $Threads, "--summary", $summary, "--progress-interval", $ProgressInterval)
    "Case folder: $CaseDir" | Set-Content -LiteralPath $log -Encoding UTF8
    "Command: $python -u $($args -join ' ')" | Add-Content -LiteralPath $log -Encoding UTF8
    & $python -u @args 2>&1 | Tee-Object -FilePath $log -Append
    $solverExit = $LASTEXITCODE
    if ($solverExit -ne 0) {
        throw "Solver failed with exit code $solverExit"
    }

    Write-Host ""
    Write-Host "Solver completed. Exporting loaded/unloaded coordinates..."
    & $python -u $exporter --case-dir $CaseDir --script $runScript --summary $coordSummary 2>&1 | Tee-Object -FilePath $log -Append
    $exportExit = $LASTEXITCODE
    if ($exportExit -ne 0) {
        throw "Coordinate export failed with exit code $exportExit"
    }

    $elapsed = New-TimeSpan -Start $started -End (Get-Date)
    Write-Host ""
    Write-Host ("Single-folder solve completed in {0:n1} s" -f $elapsed.TotalSeconds)
    Write-Host "Summary: $summary"
    Write-Host "Coordinate export summary: $coordSummary"
} finally {
    Pop-Location
}
