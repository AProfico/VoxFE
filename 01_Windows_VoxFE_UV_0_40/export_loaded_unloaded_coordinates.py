from __future__ import annotations

import argparse
import csv
import json
import math
import re
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence, Tuple


Coord = Tuple[int, int, int]
Vec3 = Tuple[float, float, float]


def parse_voxel_size(script_path: Path) -> Vec3:
    voxel_re = re.compile(
        r"^\s*VOXEL_SIZE\s+([-+0-9.eE]+)\s+([-+0-9.eE]+)\s+([-+0-9.eE]+)"
    )
    try:
        for line in script_path.read_text(encoding="utf-8", errors="replace").splitlines():
            match = voxel_re.match(line)
            if match:
                values = tuple(float(match.group(i)) for i in range(1, 4))
                if all(math.isfinite(value) and value > 0.0 for value in values):
                    return values  # type: ignore[return-value]
    except OSError:
        pass
    return (1.0, 1.0, 1.0)


def parse_model_path(script_path: Path) -> Path:
    for line in script_path.read_text(encoding="utf-8", errors="replace").splitlines():
        parts = line.strip().split()
        if len(parts) >= 5 and parts[0].upper() == "LOAD_MCTSCAN":
            return (script_path.parent / " ".join(parts[4:])).resolve()
    raise ValueError(f"LOAD_MCTSCAN row not found in {script_path}")


def parse_model(model_path: Path) -> List[Tuple[int, int, Coord]]:
    rows = model_path.read_text(encoding="utf-8", errors="replace").splitlines()
    data: List[Tuple[int, int, Coord]] = []
    expected: Optional[int] = None
    for raw in rows:
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        if expected is None and len(parts) == 1:
            try:
                expected = int(float(parts[0]))
                continue
            except ValueError:
                pass
        nums: List[int] = []
        for part in parts:
            try:
                nums.append(int(float(part)))
            except ValueError:
                nums = []
                break
        if len(nums) >= 5:
            element_id, material, x, y, z = nums[:5]
            data.append((element_id, material, (x, y, z)))
        elif len(nums) >= 4:
            element_id = len(data)
            material, x, y, z = nums[:4]
            data.append((element_id, material, (x, y, z)))
    if expected is not None and expected != len(data):
        raise ValueError(f"{model_path}: expected {expected} elements but parsed {len(data)}")
    return data


def parse_node_displacements(path: Path) -> Dict[Coord, Vec3]:
    result: Dict[Coord, Vec3] = {}
    for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw.strip()
        if not line or line.lower().startswith(("node", "displacements", "---")):
            continue
        values: List[float] = []
        for token in line.replace(":", " ").replace(",", " ").split():
            try:
                values.append(float(token))
            except ValueError:
                pass
        if len(values) >= 7:
            coord = (int(round(values[1])), int(round(values[2])), int(round(values[3])))
            result[coord] = (float(values[4]), float(values[5]), float(values[6]))
    if not result:
        raise ValueError(f"no coordinate displacement rows parsed from {path}")
    return result


def voxel_corners(coord: Coord) -> Iterable[Coord]:
    x, y, z = coord
    for dx in (0, 1):
        for dy in (0, 1):
            for dz in (0, 1):
                yield (x + dx, y + dy, z + dz)


def average_voxel_displacements(elements: Sequence[Tuple[int, int, Coord]], node_vectors: Dict[Coord, Vec3]) -> Dict[Coord, Vec3]:
    averaged: Dict[Coord, Vec3] = {}
    for _element_id, _material, coord in elements:
        vectors = [node_vectors[corner] for corner in voxel_corners(coord) if corner in node_vectors]
        if not vectors:
            averaged[coord] = (0.0, 0.0, 0.0)
            continue
        n = float(len(vectors))
        averaged[coord] = (
            sum(v[0] for v in vectors) / n,
            sum(v[1] for v in vectors) / n,
            sum(v[2] for v in vectors) / n,
        )
    return averaged


def write_voxel_coordinates(case_dir: Path, elements: Sequence[Tuple[int, int, Coord]], voxel_vectors: Dict[Coord, Vec3], voxel_size: Vec3) -> None:
    unloaded_path = case_dir / "voxel_coordinates_unloaded.tsv"
    loaded_path = case_dir / "voxel_coordinates_loaded.tsv"
    with unloaded_path.open("w", encoding="utf-8", newline="") as handle:
        handle.write("element_id\tmaterial\tx\ty\tz\n")
        for element_id, material, (x, y, z) in elements:
            handle.write(f"{element_id}\t{material}\t{x}\t{y}\t{z}\n")
    with loaded_path.open("w", encoding="utf-8", newline="") as handle:
        handle.write("element_id\tmaterial\tx\ty\tz\tdx\tdy\tdz\tx_deformed\ty_deformed\tz_deformed\n")
        vx, vy, vz = voxel_size
        for element_id, material, (x, y, z) in elements:
            dx, dy, dz = voxel_vectors.get((x, y, z), (0.0, 0.0, 0.0))
            xd = float(x) + dx / vx
            yd = float(y) + dy / vy
            zd = float(z) + dz / vz
            handle.write(
                f"{element_id}\t{material}\t{x}\t{y}\t{z}\t"
                f"{dx:.12g}\t{dy:.12g}\t{dz:.12g}\t{xd:.12g}\t{yd:.12g}\t{zd:.12g}\n"
            )


def write_gm_coordinates(case_dir: Path, elements: Sequence[Tuple[int, int, Coord]], voxel_vectors: Dict[Coord, Vec3], voxel_size: Vec3) -> None:
    unloaded_path = case_dir / "unloaded_gm_3d_coordinates.csv"
    loaded_path = case_dir / "loaded_gm_3d_coordinates.csv"
    vx, vy, vz = voxel_size
    with unloaded_path.open("w", encoding="utf-8", newline="") as unloaded, loaded_path.open("w", encoding="utf-8", newline="") as loaded:
        uwriter = csv.writer(unloaded)
        lwriter = csv.writer(loaded)
        uwriter.writerow(["landmark_id", "x", "y", "z"])
        lwriter.writerow(["landmark_id", "x", "y", "z"])
        for landmark_id, (_element_id, _material, (x, y, z)) in enumerate(elements):
            x0, y0, z0 = float(x) * vx, float(y) * vy, float(z) * vz
            dx, dy, dz = voxel_vectors.get((x, y, z), (0.0, 0.0, 0.0))
            uwriter.writerow([landmark_id, f"{x0:.12g}", f"{y0:.12g}", f"{z0:.12g}"])
            lwriter.writerow([landmark_id, f"{x0 + dx:.12g}", f"{y0 + dy:.12g}", f"{z0 + dz:.12g}"])


def main() -> int:
    parser = argparse.ArgumentParser(description="Export unloaded and loaded coordinate files from VoxFE solver outputs.")
    parser.add_argument("--case-dir", required=True)
    parser.add_argument("--script", required=True)
    parser.add_argument("--displacement-with-coords", default="displacement_standard_with_coords.txt")
    parser.add_argument("--summary", default="")
    args = parser.parse_args()

    case_dir = Path(args.case_dir).resolve()
    script_path = Path(args.script).resolve()
    displacement_path = case_dir / args.displacement_with_coords
    model_path = parse_model_path(script_path)
    voxel_size = parse_voxel_size(script_path)
    elements = parse_model(model_path)
    node_vectors = parse_node_displacements(displacement_path)
    voxel_vectors = average_voxel_displacements(elements, node_vectors)
    write_voxel_coordinates(case_dir, elements, voxel_vectors, voxel_size)
    write_gm_coordinates(case_dir, elements, voxel_vectors, voxel_size)

    summary = {
        "case_dir": str(case_dir),
        "script": str(script_path),
        "model": str(model_path),
        "voxel_size": list(voxel_size),
        "elements": len(elements),
        "node_displacements": len(node_vectors),
        "outputs": {
            "voxel_coordinates_unloaded": str(case_dir / "voxel_coordinates_unloaded.tsv"),
            "voxel_coordinates_loaded": str(case_dir / "voxel_coordinates_loaded.tsv"),
            "unloaded_gm_3d_coordinates": str(case_dir / "unloaded_gm_3d_coordinates.csv"),
            "loaded_gm_3d_coordinates": str(case_dir / "loaded_gm_3d_coordinates.csv"),
        },
    }
    summary_path = Path(args.summary) if args.summary else case_dir / "coordinate_export_summary.json"
    summary_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps(summary, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
