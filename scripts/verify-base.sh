#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$HERE/scripts/env.sh"

BASE="$HERE/config/base-files.sha256"
PATCHED="$HERE/config/patched-files.sha256"

if [[ ! -s "$BASE" || ! -s "$PATCHED" ]]; then
    echo "ERROR: SDK hash manifests are missing." >&2
    exit 1
fi

echo "SDK: $SDK"
echo

state=

if sha256sum -c "$BASE" >/dev/null 2>&1; then
    state=pristine
elif sha256sum -c "$PATCHED" >/dev/null 2>&1; then
    state=patched
else
    echo "ERROR: SDK does not match either known-good state." >&2
    echo

    echo "===== Differences from pristine SDK ====="
    sha256sum -c "$BASE" 2>&1 |
        grep -v ': OK$' || true

    echo
    echo "===== Differences from patched SDK ====="
    sha256sum -c "$PATCHED" 2>&1 |
        grep -v ': OK$' || true

    exit 1
fi

case "$state" in
    pristine)
        echo "[ OK ] Compatible pristine Firefly RK3328 Android 10 SDK"
        echo "       Ready for scripts/apply-patches.sh"
        ;;
    patched)
        echo "[ OK ] Compatible ROCK64-patched Firefly RK3328 Android 10 SDK"
        ;;
esac

echo

# These revisions identify the known-good reference workspace.
# Hash manifests above are authoritative because the original Firefly
# snapshot does not retain an upstream Git remote/manifest.
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    root_head=$(git rev-parse HEAD)
    echo "SDK Git HEAD:              $root_head"
    if [[ "$root_head" != "c03667ba6f15005a3f340cdf7bf0689e1e4611fb" ]]; then
        echo "[WARN] Reference SDK HEAD was c03667ba6f15005a3f340cdf7bf0689e1e4611fb"
    fi
fi

if git -C vendor/opengapps/build rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    gapps_head=$(git -C vendor/opengapps/build rev-parse HEAD)
    echo "OpenGApps aosp_build HEAD: $gapps_head"
    if [[ "$gapps_head" != "816160a352a46fc08d50dcbcd88a02df977312aa" ]]; then
        echo "[WARN] Tested aosp_build HEAD was 816160a352a46fc08d50dcbcd88a02df977312aa"
    fi
fi
