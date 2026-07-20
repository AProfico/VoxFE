#!/usr/bin/env sh
set -eu

rm -f "$HOME/.local/bin/voxfe-uv"
rm -f "$HOME/.local/share/applications/voxfe-uv.desktop"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
fi

echo "VoxFE-UV user launcher removed. The release folder was not deleted."
