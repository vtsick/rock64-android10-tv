#!/usr/bin/env bash
set -eo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=env.sh
source "$HERE/scripts/env.sh"

source build/envsetup.sh
lunch roc_rk3328_pc_gapps-userdebug

JOBS="${JOBS:-$(nproc)}"
make -j"$JOBS"

# Firefly's mkupdate packages from rockdev/Image-$TARGET_PRODUCT. mkimage.sh
# must therefore run after every successful make, otherwise mkupdate may pack a
# stale super.img.
./mkimage.sh

OUT_SUPER="out/target/product/roc_rk3328_pc/super.img"
ROCKDEV_SUPER="rockdev/Image-roc_rk3328_pc_gapps/super.img"

if [[ ! -f "$OUT_SUPER" || ! -f "$ROCKDEV_SUPER" ]]; then
  echo "ERROR: expected super.img is missing after mkimage.sh" >&2
  exit 1
fi

h1=$(sha256sum "$OUT_SUPER" | awk '{print $1}')
h2=$(sha256sum "$ROCKDEV_SUPER" | awk '{print $1}')
printf 'out super.img:      %s\n' "$h1"
printf 'rockdev super.img:  %s\n' "$h2"
if [[ "$h1" != "$h2" ]]; then
  echo "ERROR: rockdev contains a stale/different super.img" >&2
  exit 1
fi

"$HERE/scripts/make-update-img.sh"
