# Build

## Base tree

Use a Firefly RK3328 Android 10 SDK compatible with the reference project.

`scripts/verify-base.sh` checks the relevant files against
`config/base-files.sha256` and also recognizes the known-good patched state
from `config/patched-files.sha256`.

Reference workspace identifiers:

    Firefly SDK Git HEAD:
    c03667ba6f15005a3f340cdf7bf0689e1e4611fb

    OpenGApps aosp_build Git HEAD:
    816160a352a46fc08d50dcbcd88a02df977312aa

The reference Firefly snapshot does not retain an upstream Git remote or
`.repo/manifest.xml`, so the file hash manifests are authoritative for
compatibility checking.

The tested `vendor/opengapps/build` repository is:

    https://github.com/opengapps/aosp_build.git

`vendor/opengapps/sources` is not an independent Git repository in the
reference snapshot, so no separate revision is recorded for it.

Do not mix files from unrelated RK3328 Android releases. The proprietary
audio HAL patcher accepts only known original and known patched SHA256 values
and refuses to modify an unknown binary.

## Mandatory Python 2 environment

Every host-side SDK/build invocation must use the bundled Python 2 environment:

```bash
cd /opt/devel/Firefly/android10sdk
export PATH="$PWD/prebuilts/python/linux-x86/2.7.5/bin:$PATH"
export PYTHON="$PWD/prebuilts/python/linux-x86/2.7.5/bin/python2.7"
export PYTHONPATH="$PWD/host-tools/python2-modules"
hash -r
```

Without it, Firefly's build scripts may run under Python 3 and fail in `auto_generator.py`; the bundled 32-bit Python also needs the matching zlib module from `host-tools/python2-modules`.

The repository scripts source `scripts/env.sh` automatically.

## Prepare a clean SDK

Run these commands from the `rock64-android10-tv` repository:

    export SDK=/opt/devel/Firefly/android10sdk
    ./scripts/verify-base.sh
    ./scripts/apply-patches.sh

On a compatible pristine tree, `verify-base.sh` reports that the SDK is
ready for `apply-patches.sh`.

The source modifications are already provided in
`patches/local-source-fixes.patch`. `scripts/export-current-patches.sh` is
only a maintainer utility for regenerating that patch from the known-good
reference workspace.

## Product registration

`roc_rk3328_pc_gapps` is registered automatically by `patches/local-source-fixes.patch` in `device/rockchip/rk3328/AndroidProducts.mk`.

The resulting lunch target must be:

```text
roc_rk3328_pc_gapps-userdebug
```

## Build

```bash
export SDK=/opt/devel/Firefly/android10sdk
./scripts/build.sh
```

The important order is:

```text
make
mkimage.sh
verify out super.img == rockdev super.img
mkupdate.sh
```

Do not call `mkupdate.sh` immediately after `make`: Firefly packages from `rockdev/Image-$TARGET_PRODUCT`, so skipping `mkimage.sh` can silently create an update image containing an older `super.img`.
