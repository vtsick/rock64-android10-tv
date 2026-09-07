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

## Build from scratch

The following procedure starts with the original Firefly RK3328 Android 10
SDK and produces the Rockchip update image used by this project.

### 1. Host requirements

Firefly recommends a 64-bit Linux build host with at least 16 GB of RAM plus
swap and roughly 150 GB of free disk space.

The original Firefly Android 10 build environment uses JDK 8. You will also
need the normal Android/Firefly build dependencies, `p7zip`/`7z`, Git and
Git LFS.

This project has been developed and tested with the Firefly Android 10 SDK
on a modern Linux host. Some package names in Firefly's original Ubuntu
instructions are obsolete on newer Ubuntu releases.

### 2. Download the Firefly RK3328 Android 10 SDK

Use the official Firefly ROC-RK3328-PC Android 10 build page:

https://wiki.t-firefly.com/en/ROC-RK3328-PC/android_compile_android10.html

Download all four parts of:

    firefly_rk3328_android10.0_git_20211215.7z.001
    firefly_rk3328_android10.0_git_20211215.7z.002
    firefly_rk3328_android10.0_git_20211215.7z.003
    firefly_rk3328_android10.0_git_20211215.7z.004

Verify them before extraction:

    md5sum firefly_rk3328_android10.0_git_20211215.7z.*

Expected checksums:

    1e441dffb2d13f82164ad5aa82bc5dab  firefly_rk3328_android10.0_git_20211215.7z.001
    676e644f0e6f1883e53cc95531aa4929  firefly_rk3328_android10.0_git_20211215.7z.002
    6c8684d46ae6a9941e700168e02896a9  firefly_rk3328_android10.0_git_20211215.7z.003
    9fbe55f8fe7523909fceefc87de6021e  firefly_rk3328_android10.0_git_20211215.7z.004

Choose an SDK directory. The examples in this repository use:

    export SDK=/opt/devel/Firefly/android10sdk

Create it and extract the first archive part there; `7z` automatically reads
the remaining parts:

    mkdir -p "$SDK"
    cd "$SDK"
    7z x /path/to/firefly_rk3328_android10.0_git_20211215.7z.001 -r -o.
    git reset --hard

Do **not** run Firefly's `.bundle/update` procedure before applying this
project. The ROCK64 patchset is validated against the known-good SDK snapshot
and `scripts/verify-base.sh` will reject an incompatible source tree.

The reference SDK Git HEAD used by this project is:

    c03667ba6f15005a3f340cdf7bf0689e1e4611fb

### 3. Add OpenGApps build integration

The product uses the OpenGApps AOSP build integration with the `tvstock`
variant:

https://github.com/opengapps/aosp_build

Install Git LFS first and initialize it:

    git lfs install

Clone the OpenGApps AOSP build system into the Android tree:

    mkdir -p "$SDK/vendor/opengapps"
    git clone https://github.com/opengapps/aosp_build.git \
        "$SDK/vendor/opengapps/build"

    git -C "$SDK/vendor/opengapps/build" checkout \
        816160a352a46fc08d50dcbcd88a02df977312aa

The tested `aosp_build` revision is therefore:

    816160a352a46fc08d50dcbcd88a02df977312aa

OpenGApps also requires the architecture-independent, ARM and ARM64 source
repositories. ARM64 depends on the ARM source repository, so all three are
required:

    mkdir -p "$SDK/vendor/opengapps/sources"

    git clone --depth=1 \
        https://gitlab.opengapps.org/opengapps/all.git \
        "$SDK/vendor/opengapps/sources/all"

    git clone --depth=1 \
        https://gitlab.opengapps.org/opengapps/arm.git \
        "$SDK/vendor/opengapps/sources/arm"

    git clone --depth=1 \
        https://gitlab.opengapps.org/opengapps/arm64.git \
        "$SDK/vendor/opengapps/sources/arm64"

Fetch the Git LFS objects:

    for d in all arm arm64; do
        git -C "$SDK/vendor/opengapps/sources/$d" lfs pull
    done

The OpenGApps APK source repositories are not pinned by this project. The
exact reference revision is recorded only for `vendor/opengapps/build`.
`scripts/verify-base.sh` verifies the OpenGApps build files that are modified
by the ROCK64 patchset.

### 4. Get this project

Clone this repository outside the Android source tree:

    mkdir -p /opt/devel/rock64
    cd /opt/devel/rock64
    git clone https://github.com/vtsick/rock64-android10-tv.git
    cd rock64-android10-tv

If building a particular released version, check out its tag, for example:

    git checkout v1.0.0

### 5. Verify the original SDK

The Firefly Android 10 build tools require their bundled Python 2 environment.
The project scripts configure this automatically, but the equivalent
environment is:

    cd /opt/devel/Firefly/android10sdk

    export PATH="$PWD/prebuilts/python/linux-x86/2.7.5/bin:$PATH"
    export PYTHON="$PWD/prebuilts/python/linux-x86/2.7.5/bin/python2.7"
    export PYTHONPATH="$PWD/host-tools/python2-modules"
    hash -r

Set the SDK path and run the strict pristine-tree check:

    export SDK=/opt/devel/Firefly/android10sdk
    cd /opt/devel/rock64/rock64-android10-tv

    ./scripts/verify-base.sh

A matching original tree reports:

    [ OK ] Compatible pristine Firefly RK3328 Android 10 SDK
           Ready for scripts/apply-patches.sh

If this check fails, do not force the patch onto the tree. The SDK or the
OpenGApps build integration does not match the version tested by this
project.

### 6. Apply the ROCK64 patches

Run:

    export SDK=/opt/devel/Firefly/android10sdk
    ./scripts/apply-patches.sh

This performs three kinds of changes:

1. applies `patches/local-source-fixes.patch`;
2. installs the ROCK64 product/default-permission/Leanback files;
3. applies the hash-guarded binary fix to the Firefly audio HAL.

Verify the resulting tree:

    ./scripts/verify-base.sh

The result should now be:

    [ OK ] Compatible ROCK64-patched Firefly RK3328 Android 10 SDK

`apply-patches.sh` is idempotent and may safely be run again on the known
patched state.

### 7. Build Android and create the Rockchip update image

The build script performs the complete required sequence:

    make
    ./mkimage.sh
    verify out/target/.../super.img == rockdev/.../super.img
    mkupdate.sh

Run:

    cd /opt/devel/Firefly/android10sdk

    export PATH="$PWD/prebuilts/python/linux-x86/2.7.5/bin:$PATH"
    export PYTHON="$PWD/prebuilts/python/linux-x86/2.7.5/bin/python2.7"
    export PYTHONPATH="$PWD/host-tools/python2-modules"
    hash -r

    export SDK=/opt/devel/Firefly/android10sdk
    cd /opt/devel/rock64/rock64-android10-tv

    ./scripts/build.sh

To override the number of parallel build jobs:

    JOBS=16 ./scripts/build.sh

The lunch target is:

    roc_rk3328_pc_gapps-userdebug

The final Rockchip firmware is expected at:

    /opt/devel/Firefly/android10sdk/rockdev/Image-roc_rk3328_pc_gapps/ROCK64_Android10_TV.img

`scripts/build.sh` deliberately runs `mkimage.sh` before creating the update
image and verifies that the `super.img` copied into `rockdev` matches the
freshly built `super.img`. This prevents accidentally packaging an older
Android image.

### 8. Flash and verify

Flash `ROCK64_Android10_TV.img` using Rockchip Loader/MaskRom mode and a
Rockchip update-image tool. See `docs/FLASH.md`.

After Android has completed its first boot:

    cd /opt/devel/rock64/rock64-android10-tv
    ./scripts/postboot-check.sh

Applications can then be installed with ADB as described in
`docs/SIDELOAD.md`.

## Patchset maintenance

Users do not need to run `scripts/export-current-patches.sh`. The ready-to-apply source patch is stored in `patches/local-source-fixes.patch`.

`scripts/export-current-patches.sh` is a maintainer tool used against the known-good reference SDK to regenerate that patch from the exact source modifications.

The proprietary binary audio HAL fix is handled separately by `scripts/patch-audio-hal.py`; no proprietary `.so` files are stored here. The patcher accepts only known original or already-patched SHA256 hashes and refuses to modify unknown binaries.

## Google apps

This repository does **not** redistribute Google Play Services, Play Store, SetupWraith, MediaShell, AtvRemoteService, or any other proprietary Google APK. Users must obtain any required Google packages separately and comply with their licenses/terms.

## License

Original scripts and documentation in this repository are licensed under the MIT License. Patch content generated from upstream projects remains subject to the corresponding upstream licenses.
