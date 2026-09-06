#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=env.sh
source "$HERE/scripts/env.sh"

./FFTools/mkupdate/mkupdate.sh \
  -l roc_rk3328_pc_gapps-userdebug \
  -t emmc \
  -n ROCK64_Android10_TV

IMG="rockdev/Image-roc_rk3328_pc_gapps/ROCK64_Android10_TV.img"
if [[ -f "$IMG" ]]; then
  sha256sum "$IMG"
else
  echo "ERROR: expected update image was not found: $IMG" >&2
  echo "       Check rockdev/Image-roc_rk3328_pc_gapps/ for the generated update image." >&2
  exit 1
fi
