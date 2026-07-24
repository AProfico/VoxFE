from __future__ import annotations

import argparse
import re
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True)
    parser.add_argument("--target", required=True)
    parser.add_argument("--method", required=True)
    parser.add_argument("--max-iter", required=True)
    parser.add_argument("--min-iter", default="0")
    parser.add_argument("--tolerance", required=True)
    parser.add_argument("--compute-sed", default=None, choices=("true", "false"))
    args = parser.parse_args()

    source = Path(args.source)
    target = Path(args.target)
    lines = source.read_text(encoding="utf-8", errors="replace").splitlines()

    out: list[str] = []
    has_algorithm = False
    has_max_iter = False
    has_min_iter = False
    has_tolerance = False
    has_compute_sed = False
    for line in lines:
        if re.match(r"^\s*ALGORITHM_FEA\s+", line, re.IGNORECASE):
            out.append(f"ALGORITHM_FEA {args.method}")
            has_algorithm = True
        elif re.match(r"^\s*MAX_ITER\s+", line, re.IGNORECASE):
            out.append(f"MAX_ITER {args.max_iter}")
            has_max_iter = True
        elif re.match(r"^\s*(MIN_ITER|MINIMUM_ITER|MINIMUM_ITERATIONS)\s+", line, re.IGNORECASE):
            out.append(f"MIN_ITER {args.min_iter}")
            has_min_iter = True
        elif re.match(r"^\s*TOLERANCE\s+", line, re.IGNORECASE):
            out.append(f"TOLERANCE {args.tolerance}")
            has_tolerance = True
        elif re.match(r"^\s*COMPUTE_SED(?:\s+.*)?$", line, re.IGNORECASE):
            if args.compute_sed is None:
                out.append(line)
            else:
                out.append(f"COMPUTE_SED {args.compute_sed}")
            has_compute_sed = True
        else:
            out.append(line)

    insert_at = 0
    if not has_algorithm:
        out.insert(insert_at, f"ALGORITHM_FEA {args.method}")
        insert_at += 1
    if not has_max_iter:
        out.insert(insert_at, f"MAX_ITER {args.max_iter}")
        insert_at += 1
    if str(args.min_iter).strip() not in {"", "0"} and not has_min_iter:
        out.insert(insert_at, f"MIN_ITER {args.min_iter}")
        insert_at += 1
    if not has_tolerance:
        out.insert(insert_at, f"TOLERANCE {args.tolerance}")
        insert_at += 1
    if args.compute_sed is not None and not has_compute_sed:
        out.insert(insert_at, f"COMPUTE_SED {args.compute_sed}")

    target.write_text("\n".join(out).rstrip() + "\n", encoding="utf-8", newline="\n")
    print(f"Prepared {target}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
