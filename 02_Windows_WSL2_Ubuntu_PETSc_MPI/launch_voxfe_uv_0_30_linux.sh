#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"

APP="VoxFE_UV_0_27_fast.pyz"
if [ ! -f "$APP" ]; then
    echo "ERROR: $APP was not found." >&2
    exit 1
fi

PYTHON_EXE="${PYTHON_EXE:-}"
if [ -z "$PYTHON_EXE" ] && [ -x ".venv/bin/python" ]; then
    PYTHON_EXE=".venv/bin/python"
fi
if [ -z "$PYTHON_EXE" ]; then
    PYTHON_EXE="python3"
fi

exec "$PYTHON_EXE" "$APP" "$@"
