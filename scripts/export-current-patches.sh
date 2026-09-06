#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$HERE/scripts/env.sh"

SDK="$(readlink -f "$SDK")"
OUT="$HERE/patches/local-source-fixes.patch"
: > "$OUT"

items=(
  'frameworks/base|services/core/java/com/android/server/wm/WindowManagerService.java'
  'system/core|rootdir/ueventd.rc'
  'device/rockchip|rk3328/AndroidProducts.mk'
  'device/rockchip|rk3328/roc_rk3328_pc/BoardConfig.mk'
  'device/rockchip|common/device.mk'
  'device/rockchip|common/tv/tv_base.mk'
  'device/rockchip|common/tv/overlay/frameworks/base/core/res/res/values/config.xml'
  'vendor/opengapps|build/modules/SetupWraithPrebuilt/Android.mk'
  'vendor/opengapps|build/core/prebuilt_apk.mk'
)

for item in "${items[@]}"; do
    project=${item%%|*}
    rel=${item#*|}
    full="$project/$rel"
    file="$SDK/$full"

    if [[ ! -e "$file" ]]; then
        echo "[WARN] missing: $full" >&2
        continue
    fi

    repo_root=$(
        git -C "$(dirname "$file")" rev-parse --show-toplevel 2>/dev/null
    ) || {
        echo "[WARN] not tracked by Git: $full" >&2
        continue
    }

    repo_root="$(readlink -f "$repo_root")"
    repo_rel="$(realpath --relative-to="$repo_root" "$file")"

    echo "[EXPORT] $full"
    echo "         repo: $repo_root"

    if [[ "$repo_root" == "$SDK" ]]; then
        # Monolithic SDK repository: repo_rel already contains
        # frameworks/base, device/rockchip, etc.
        git -C "$repo_root" diff --binary HEAD -- "$repo_rel" >> "$OUT"
    else
        # Android repo-style nested Git project. Prefix its diff paths
        # so the resulting patch is applicable from the SDK root.
        repo_prefix="$(realpath --relative-to="$SDK" "$repo_root")"

        git -C "$repo_root" diff --binary \
            --src-prefix="a/$repo_prefix/" \
            --dst-prefix="b/$repo_prefix/" \
            HEAD -- "$repo_rel" >> "$OUT"
    fi
done

if [[ ! -s "$OUT" ]]; then
    echo "ERROR: no tracked changes were exported." >&2
    exit 1
fi

echo
echo "Created: $OUT"
