# Changelog

## 1.0.0

Initial reproducible ROCK64 Android 10 TV patchset skeleton.

Validated fixes captured by this project:

- bypass Firefly audio HAL dependency on `/dev/vmdrm0`
- stop boot animation correctly for `ro.target.product=box`
- disable nonexistent ROCK64 Bluetooth hardware and packages
- keep Wi-Fi framework stack for SetupWraith compatibility
- use Google SetupWraith instead of AOSP Provision
- grant SetupWraith location permissions required by its Wi-Fi initialization path
- set default UI mode to `UI_MODE_TYPE_TELEVISION`
- expose Leanback / television features
- permit `system_server` to open `/dev/uinput` for Google TV Remote
- preserve MediaShell APK signature when OpenGApps installs a PRESIGNED APK
- add dedicated `roc_rk3328_pc_gapps` product integration
