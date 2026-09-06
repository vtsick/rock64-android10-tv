# ROCK64 Android 10 TV

A reproducible patch/integration layer that turns the Firefly RK3328 Android 10 SDK into a usable Android TV build for the PINE64 ROCK64.

The project deliberately does **not** mirror the complete Android source tree and does **not** redistribute Google proprietary APKs. It keeps only the ROCK64-specific integration, patches, helper scripts, and documentation needed to reproduce the working build.

## Tested result

Working on ROCK64:

- Android 10 / API 29
- Android TV UI mode
- Ethernet
- HDMI audio
- Google account sign-in
- Google TV Remote input
- YouTube
- Jellyfin
- Spotify
- IPTV clients installed by sideload

Hardware notes:

- ROCK64 has no onboard Bluetooth; Bluetooth is disabled in the build.
- ROCK64 has no onboard Wi-Fi. The Android Wi-Fi **software stack is intentionally kept**, because removing it breaks Google SetupWraith on this Android 10 TV stack.

Known limitation:

- Google Play Store reaches `AccessRestrictedActivity` on this build. The project treats Play Store as unsupported; applications can be installed by ADB/sideload.
- Chromecast/MediaShell special Cast certificate provisioning may fail with HTTP 401. Ordinary Widevine provisioning works.

## Repository layout

```text
.
├── README.md
├── CHANGELOG.md
├── LICENSE
├── config/
│   ├── base-files.sha256
│   └── patched-files.sha256
├── docs/
│   ├── BUILD.md
│   ├── FLASH.md
│   ├── KNOWN_ISSUES.md
│   ├── SIDELOAD.md
│   └── TECHNICAL_NOTES.md
├── files/
│   ├── android.software.leanback.xml
│   └── setupwraith-default-permissions.xml
├── product/
│   └── roc_rk3328_pc_gapps.mk
├── patches/
│   ├── README.md
│   └── local-source-fixes.patch
└── scripts/
    ├── apply-patches.sh
    ├── build.sh
    ├── env.sh
    ├── export-current-patches.sh
    ├── make-update-img.sh
    ├── patch-audio-hal.py
    ├── postboot-check.sh
    └── verify-base.sh
```

## Quick start

1. Obtain and unpack a compatible Firefly RK3328 Android 10 SDK.
2. Prepare the OpenGApps integration under `vendor/opengapps`.
3. Clone or copy this repository outside the Android source tree.
4. Verify the pristine SDK, apply the ROCK64 changes, and build:

    export SDK=/opt/devel/Firefly/android10sdk
    ./scripts/verify-base.sh
    ./scripts/apply-patches.sh
    ./scripts/build.sh

5. Flash the resulting Rockchip update image over USB Loader/MaskRom. See [docs/FLASH.md](docs/FLASH.md).

## Patchset maintenance

Users do not need to run `scripts/export-current-patches.sh`. The ready-to-apply source patch is stored in `patches/local-source-fixes.patch`.

`scripts/export-current-patches.sh` is a maintainer tool used against the known-good reference SDK to regenerate that patch from the exact source modifications.

The proprietary binary audio HAL fix is handled separately by `scripts/patch-audio-hal.py`; no proprietary `.so` files are stored here. The patcher accepts only known original or already-patched SHA256 hashes and refuses to modify unknown binaries.

## Google apps

This repository does **not** redistribute Google Play Services, Play Store, SetupWraith, MediaShell, AtvRemoteService, or any other proprietary Google APK. Users must obtain any required Google packages separately and comply with their licenses/terms.

## License

Original scripts and documentation in this repository are licensed under the MIT License. Patch content generated from upstream projects remains subject to the corresponding upstream licenses.
