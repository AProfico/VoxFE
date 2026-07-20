from __future__ import annotations

import argparse
import csv
import json
import math
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path
from typing import Iterable


METHODS = (
    "SPSOLVE",
    "FASTJAPCG",
    "CG",
    "JAPCG",
    "AMGCG",
    "FASTMG",
    "ROWCG",
    "ROWJAPCG",
    "ROWAMG",
    "MATRIXFREE",
)

SKIP_COPY_NAMES = {
    "solver_comparison_runs",
    "solver_comparison.csv",
    "solver_comparison.json",
}


def find_first_existing(paths: Iterable[Path]) -> Path | None:
    for path in paths:
        if path.exists():
            return path.resolve()
    return None


def choose_script(case_dir: Path) -> Path:
    preferred = case_dir / "Script.txt"
    if preferred.exists():
        return preferred
    candidates = sorted(case_dir.glob("*_Script_edited.txt"), key=lambda p: p.stat().st_mtime, reverse=True)
    if candidates:
        return candidates[0]
    candidates = sorted(case_dir.glob("*_Script.txt"), key=lambda p: p.stat().st_mtime, reverse=True)
    if candidates:
        return candidates[0]
    raise FileNotFoundError(f"No Script.txt or *_Script*.txt found in {case_dir}")


def write_run_script(source: Path, target: Path, method: str, max_iter: int) -> None:
    lines = source.read_text(encoding="utf-8", errors="replace").splitlines()
    updated: list[str] = []
    has_algorithm = False
    has_max_iter = False
    for line in lines:
        if re.match(r"^\s*ALGORITHM_FEA\s+", line, flags=re.IGNORECASE):
            updated.append(f"ALGORITHM_FEA {method}")
            has_algorithm = True
        elif re.match(r"^\s*MAX_ITER\s+", line, flags=re.IGNORECASE):
            updated.append(f"MAX_ITER {max_iter}")
            has_max_iter = True
        else:
            updated.append(line)
    if not has_algorithm:
        updated.insert(0, f"ALGORITHM_FEA {method}")
    if not has_max_iter:
        updated.insert(1, f"MAX_ITER {max_iter}")
    target.write_text("\n".join(updated).rstrip() + "\n", encoding="utf-8")


def copy_case(source: Path, target: Path) -> None:
    if target.exists():
        shutil.rmtree(target)
    target.mkdir(parents=True, exist_ok=True)
    for item in source.iterdir():
        if item.name in SKIP_COPY_NAMES:
            continue
        if item.name.startswith("solver_") or item.name.startswith("voxfe_solver_summary"):
            continue
        if item.name.startswith("coordinate_export_summary"):
            continue
        if item.name.startswith("Script_autorun"):
            continue
        if item.is_dir():
            shutil.copytree(item, target / item.name)
        else:
            shutil.copy2(item, target / item.name)


def method_backend(method: str) -> str:
    if method.upper().startswith("PETSC"):
        return "petsc_optional"
    if method.upper() in {"MATRIXFREE", "FASTCG", "MFPCG"}:
        return "matrix_free_debug"
    return "sparse_scipy"


def run_stream(command: list[str], cwd: Path, log_path: Path, env: dict[str, str]) -> int:
    with log_path.open("a", encoding="utf-8", errors="replace") as log:
        log.write("Command: " + " ".join(command) + "\n")
        log.flush()
        process = subprocess.Popen(
            command,
            cwd=str(cwd),
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
            bufsize=1,
            env=env,
        )
        assert process.stdout is not None
        for line in process.stdout:
            print(line, end="", flush=True)
            log.write(line)
            log.flush()
        return process.wait()


def parse_displacement(path: Path) -> dict[str, object]:
    values: list[tuple[float, float, float]] = []
    if not path.exists():
        return {"count": 0, "max_abs": None, "l2": None, "mean_mag": None, "values": values}
    line_re = re.compile(
        r"^\s*\d+\s*:\s*([-+0-9.eE]+)\s+([-+0-9.eE]+)\s+([-+0-9.eE]+)"
    )
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        match = line_re.match(line)
        if not match:
            continue
        xyz = tuple(float(match.group(i)) for i in range(1, 4))
        values.append(xyz)  # type: ignore[arg-type]
    if not values:
        return {"count": 0, "max_abs": None, "l2": None, "mean_mag": None, "values": values}
    max_abs = max(abs(component) for row in values for component in row)
    mags = [math.sqrt(x * x + y * y + z * z) for x, y, z in values]
    l2 = math.sqrt(sum(m * m for m in mags))
    mean_mag = sum(mags) / len(mags)
    return {"count": len(values), "max_abs": max_abs, "l2": l2, "mean_mag": mean_mag, "values": values}


def displacement_diff(current: list[tuple[float, float, float]], baseline: list[tuple[float, float, float]]) -> dict[str, float | None]:
    if not current or not baseline or len(current) != len(baseline):
        return {"disp_diff_l2": None, "disp_diff_max_abs": None, "disp_relative_l2": None}
    sq = 0.0
    max_abs = 0.0
    base_sq = 0.0
    for a, b in zip(current, baseline):
        for ac, bc in zip(a, b):
            delta = ac - bc
            sq += delta * delta
            base_sq += bc * bc
            max_abs = max(max_abs, abs(delta))
    diff_l2 = math.sqrt(sq)
    base_l2 = math.sqrt(base_sq)
    return {
        "disp_diff_l2": diff_l2,
        "disp_diff_max_abs": max_abs,
        "disp_relative_l2": diff_l2 / base_l2 if base_l2 > 0.0 else None,
    }


def load_json(path: Path) -> dict[str, object]:
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8", errors="replace"))
    except Exception:
        return {}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--case-dir", default=".")
    parser.add_argument("--python-root", default=r"C:\FEA SIMONA\VoxFE_UV_0_25_runnable")
    parser.add_argument("--release-root", default="")
    parser.add_argument("--max-iter", type=int, default=60000)
    parser.add_argument("--methods", default=",".join(METHODS))
    parser.add_argument("--progress-interval", default="50")
    args = parser.parse_args()

    case_dir = Path(args.case_dir).resolve()
    python_root = Path(args.python_root)
    python_exe = python_root / ".venv" / "Scripts" / "python.exe"
    if not python_exe.exists():
        python_exe = Path(sys.executable)

    release_candidates = []
    if args.release_root:
        release_candidates.append(Path(args.release_root))
    release_candidates.extend(
        [
            case_dir / "VoxFE_UV_0_26_runnable_complete",
            case_dir.parent / "VoxFE_UV_0_26_runnable_complete",
            case_dir.parent.parent / "VoxFE_UV_0_26_runnable_complete",
            Path(r"C:\Users\anton\Documents\Codex\2026-07-17\analizza-e-modifica-l-interfaccia-del\outputs\VoxFE_UV_0_26_runnable_complete"),
        ]
    )
    release_root = find_first_existing(release_candidates)
    if release_root is None:
        raise FileNotFoundError("Release folder not found.")
    solver = find_first_existing([release_root / "SOLVER_0_2_fast.pyz", release_root / "SOLVER_0_1.pyz"])
    if solver is None:
        raise FileNotFoundError("Solver artifact not found.")
    exporter = find_first_existing(
        [
            release_root / "export_loaded_unloaded_coordinates.py",
            Path(r"C:\Users\anton\Documents\Codex\2026-07-17\analizza-e-modifica-l-interfaccia-del\outputs\export_loaded_unloaded_coordinates.py"),
        ]
    )

    methods = [method.strip().upper() for method in args.methods.split(",") if method.strip()]
    out_root = case_dir / "solver_comparison_runs"
    out_root.mkdir(parents=True, exist_ok=True)

    print(f"Comparison case: {case_dir}")
    print(f"Python: {python_exe}")
    print(f"Solver: {solver}")
    print(f"Methods: {', '.join(methods)}")
    print("")

    env = os.environ.copy()
    env["PYTHONUNBUFFERED"] = "1"
    env["PYTHONIOENCODING"] = "utf-8"

    results: list[dict[str, object]] = []
    displacement_by_method: dict[str, list[tuple[float, float, float]]] = {}
    for method in methods:
        method_dir = out_root / method
        copy_case(case_dir, method_dir)
        source_script = choose_script(method_dir)
        run_script = method_dir / "Script_autorun_compare.txt"
        write_run_script(source_script, run_script, method, args.max_iter)

        summary_path = method_dir / "voxfe_solver_summary_compare.json"
        log_path = method_dir / "solver_compare_stdout.log"
        backend = method_backend(method)
        command = [
            str(python_exe),
            "-u",
            str(solver),
            run_script.name,
            "--backend",
            backend,
            "--algorithm",
            method,
            "--threads",
            "auto",
            "--summary",
            str(summary_path),
            "--progress-interval",
            str(args.progress_interval),
        ]
        print(f"=== {method} ({backend}) ===", flush=True)
        started = time.perf_counter()
        exit_code = run_stream(command, method_dir, log_path, env)
        elapsed = time.perf_counter() - started

        export_exit = None
        coord_summary_path = method_dir / "coordinate_export_summary_compare.json"
        if exit_code == 0 and exporter is not None:
            export_command = [
                str(python_exe),
                "-u",
                str(exporter),
                "--case-dir",
                str(method_dir),
                "--script",
                str(run_script),
                "--summary",
                str(coord_summary_path),
            ]
            print(f"=== {method}: coordinate export ===", flush=True)
            export_exit = run_stream(export_command, method_dir, log_path, env)

        summary = load_json(summary_path)
        disp = parse_displacement(method_dir / "displacement.txt")
        displacement_by_method[method] = disp["values"]  # type: ignore[assignment]
        results.append(
            {
                "method_requested": method,
                "backend_requested": backend,
                "exit_code": exit_code,
                "export_exit_code": export_exit,
                "wall_time_seconds": round(elapsed, 6),
                "summary_total_time_seconds": summary.get("total_time_seconds"),
                "assembly_time_seconds": summary.get("assembly_time_seconds"),
                "solve_time_seconds": summary.get("solve_time_seconds"),
                "backend_used": summary.get("backend_used") or summary.get("backend"),
                "method_used": summary.get("method"),
                "n_elements": summary.get("n_elements"),
                "n_nodes": summary.get("n_nodes"),
                "n_dofs": summary.get("n_dofs"),
                "sparse_nnz": summary.get("sparse_nnz"),
                "converged": summary.get("converged"),
                "iterations": summary.get("iterations"),
                "residual_norm": summary.get("residual_norm"),
                "relative_residual": summary.get("relative_residual"),
                "max_abs_displacement_summary": summary.get("max_abs_displacement"),
                "displacement_count": disp["count"],
                "displacement_max_abs": disp["max_abs"],
                "displacement_l2": disp["l2"],
                "displacement_mean_magnitude": disp["mean_mag"],
                "run_dir": str(method_dir),
                "log": str(log_path),
                "summary": str(summary_path),
            }
        )
        print("")

    baseline_method = "SPSOLVE" if displacement_by_method.get("SPSOLVE") else "ROWJAPCG"
    baseline = displacement_by_method.get(baseline_method, [])
    for row in results:
        diff = displacement_diff(displacement_by_method.get(str(row["method_requested"]), []), baseline)
        row["displacement_baseline"] = baseline_method
        row.update(diff)

    csv_path = case_dir / "solver_comparison.csv"
    json_path = case_dir / "solver_comparison.json"
    fields = list(results[0].keys()) if results else []
    with csv_path.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=fields)
        writer.writeheader()
        writer.writerows(results)
    json_path.write_text(json.dumps(results, indent=2), encoding="utf-8")
    print(f"Comparison CSV: {csv_path}")
    print(f"Comparison JSON: {json_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
