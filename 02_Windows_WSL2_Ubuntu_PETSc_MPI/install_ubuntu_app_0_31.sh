#!/usr/bin/env sh
set -eu

APP_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
APP_NAME="VoxFE-UV"
APP_ID="voxfe-uv"
LAUNCHER="$APP_DIR/launch_voxfe_uv_0_31_linux.sh"
ICON="$APP_DIR/voxfea_app_icon.png"
BIN_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
BIN_LINK="$BIN_DIR/voxfe-uv"
DESKTOP_FILE="$DESKTOP_DIR/$APP_ID.desktop"

if [ ! -f "$LAUNCHER" ]; then
    echo "ERROR: launcher not found: $LAUNCHER" >&2
    exit 1
fi

mkdir -p "$BIN_DIR" "$DESKTOP_DIR"
chmod +x "$LAUNCHER" 2>/dev/null || true

cat > "$BIN_LINK" <<EOF
#!/usr/bin/env sh
exec "$LAUNCHER" "\$@"
EOF
chmod +x "$BIN_LINK"

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=$APP_NAME
Comment=Voxel finite-element viewer and solver
Exec=$LAUNCHER
Icon=$ICON
Terminal=false
Categories=Science;Education;Graphics;Engineering;
StartupNotify=true
EOF
chmod +x "$DESKTOP_FILE" 2>/dev/null || true

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1 || true
fi

echo "$APP_NAME installed for this user."
echo "Application menu entry: $DESKTOP_FILE"
echo "Terminal command: $BIN_LINK"
echo
echo "If the command is not found yet, open a new terminal or add ~/.local/bin to PATH."
