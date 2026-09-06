#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$HERE/scripts/env.sh"

SDK="$(readlink -f "$SDK")"
PATCH="$HERE/patches/local-source-fixes.patch"

cd "$SDK"

echo "SDK: $SDK"

if [[ ! -s "$PATCH" ]]; then
    echo "ERROR: patches/local-source-fixes.patch is missing or empty." >&2
    exit 1
fi

echo
echo "Checking source patchset..."

if git apply --check "$PATCH" 2>/dev/null; then
    echo "Applying source patchset..."
    git apply "$PATCH"
elif git apply --reverse --check "$PATCH" 2>/dev/null; then
    echo "Source patchset is already applied."
else
    echo "ERROR: source tree is neither pristine nor in the expected patched state." >&2
    echo "       Refusing to modify it." >&2
    exit 1
fi

TARGET="device/rockchip/rk3328/roc_rk3328_pc"

echo
echo "Installing ROCK64 product files..."

install -m 0644 \
    "$HERE/files/setupwraith-default-permissions.xml" \
    "$TARGET/setupwraith-default-permissions.xml"

install -m 0644 \
    "$HERE/files/android.software.leanback.xml" \
    "$TARGET/android.software.leanback.xml"

install -m 0644 \
    "$HERE/product/roc_rk3328_pc_gapps.mk" \
    "$TARGET/roc_rk3328_pc_gapps.mk"

echo
echo "Patching proprietary Firefly audio HAL..."
SDK="$SDK" python3 "$HERE/scripts/patch-audio-hal.py"

echo
echo "ROCK64 Android 10 TV patchset installed."
echo "Lunch target: roc_rk3328_pc_gapps-userdebug"
