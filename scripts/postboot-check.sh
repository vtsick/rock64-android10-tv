#!/usr/bin/env bash
set -u
ADB=(adb)
if [[ -n "${ADB_SERIAL:-}" ]]; then
  ADB+=( -s "$ADB_SERIAL" )
fi

ok()   { printf '[ OK ] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; }
fail() { printf '[FAIL] %s\n' "$*"; }

prop() { "${ADB[@]}" shell getprop "$1" 2>/dev/null | tr -d '\r'; }
feature() { "${ADB[@]}" shell pm has-feature "$1" 2>/dev/null | tr -d '\r'; }

"${ADB[@]}" get-state >/dev/null || exit 1

[[ "$(prop ro.build.version.sdk)" == 29 ]] && ok "Android API 29" || warn "API=$(prop ro.build.version.sdk)"
[[ "$(prop ro.build.characteristics)" == *tv* ]] && ok "ro.build.characteristics contains tv" || fail "ro.build.characteristics=$(prop ro.build.characteristics)"
[[ "$(prop sys.boot_completed)" == 1 ]] && ok "boot completed" || warn "sys.boot_completed=$(prop sys.boot_completed)"

[[ "$(feature android.software.leanback)" == true ]] \
  && ok "android.software.leanback" \
  || fail "android.software.leanback missing"

for f in android.software.leanback_only android.hardware.type.television com.google.android.tv.installed; do
  if [[ "$(feature "$f")" == true ]]; then
    ok "$f"
  else
    printf '[INFO] %s not advertised\n' "$f"
  fi
done

uimode=$("${ADB[@]}" shell service call uimode 3 2>/dev/null | tr -d '\r')
if grep -q '00000004' <<<"$uimode"; then
  ok "UiModeManager current mode = television (4)"
else
  fail "UiModeManager current mode is not television: $uimode"
fi

uinput=$("${ADB[@]}" shell 'ls -lZ /dev/uinput 2>/dev/null' | tr -d '\r')
if [[ -n "$uinput" ]]; then
  echo "[INFO] /dev/uinput: $uinput"
else
  fail "/dev/uinput missing"
fi

if "${ADB[@]}" shell pm list packages | grep -q '^package:com.android.bluetooth'; then
  warn "Bluetooth package is present"
else
  ok "Bluetooth package absent"
fi

if "${ADB[@]}" shell dumpsys media.audio_flinger >/dev/null 2>&1; then
  ok "AudioFlinger responds"
else
  warn "AudioFlinger check failed"
fi

echo
printf 'Model: %s\n' "$(prop ro.product.model)"
printf 'Product: %s\n' "$(prop ro.product.name)"
printf 'Target product: %s\n' "$(prop ro.target.product)"
