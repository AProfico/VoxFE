#!/usr/bin/env sh
set -eu

APP_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
APP="$APP_DIR/VoxFE_UV_0_30_petsc_fastjapcg.pyz"

if [ ! -f "$APP" ]; then
    APP="$APP_DIR/VoxFE_UV_0_27_fast.pyz"
fi
if [ ! -f "$APP" ]; then
    echo "ERROR: viewer app was not found in $APP_DIR" >&2
    exit 1
fi

PYTHON_EXE="${PYTHON_EXE:-}"
if [ -z "$PYTHON_EXE" ] && [ -x "$APP_DIR/.venv/bin/python" ]; then
    PYTHON_EXE="$APP_DIR/.venv/bin/python"
fi
if [ -z "$PYTHON_EXE" ]; then
    PYTHON_EXE="python3"
fi

exec "$PYTHON_EXE" "$APP" "$@"
