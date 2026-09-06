# Technical notes

This document records the fixes that turned the Firefly RK3328 Android 10 tree into a usable ROCK64 Android TV image.

## 1. Audio HAL: Firefly `/dev/vmdrm0` assumption

Firefly's prebuilt Rockchip audio HAL contains vendor DRM logic that expects `/dev/vmdrm0`. ROCK64 does not expose that device, and the check prevents normal audio HAL operation.

Patched prebuilts:

```text
vendor/rockchip/common/tinyalsa/lib/hw/audio.primary.rk30board.so
vendor/rockchip/common/tinyalsa/lib64/hw/audio.primary.rk30board.so
```

The patch makes `get_vendor_drm()` return zero immediately:

```text
32-bit file offset 0x220ea:
    movs r0,#0
    bx lr

64-bit file offset 0x35af8:
    mov w0,#0
    ret
```

Known-good post-patch SHA256:

```text
cc6e68b34dedf19c1f805e808794d76b80f66f9c8b3c5e94c434bf6f1d520e59  32-bit
f5863b85d4a53c46834cf695e8d2eff143e0a350ae74aacab1b60456f2a798c5  64-bit
```

The runtime HIDL audio service uses the 32-bit HAL, but both prebuilts are patched for consistency.

## 2. Boot animation never stopped on `box`

Firefly modified `WindowManagerService.performEnableScreen()` so the boot-animation stop / SurfaceFlinger `BOOT_FINISHED` path was skipped when:

```text
ro.target.product=box
```

ROCK64 uses the `box` target path. Removing only that vendor wrapper restores normal Android boot completion behavior without redesigning WindowManager.

## 3. Bluetooth

ROCK64 does not have Bluetooth hardware. The target disables Rockchip/BCM/RTK Bluetooth flags and makes common Rockchip package inclusion conditional so Bluetooth framework packages/HALs are not installed accidentally.

Target flags include:

```make
BOARD_HAVE_BLUETOOTH := false
BOARD_HAVE_BLUETOOTH_BCM := false
BOARD_HAVE_BLUETOOTH_RTK := false
BOARD_BLUETOOTH_SUPPORT := false
BOARD_BLUETOOTH_LE_SUPPORT := false
```

## 4. Keep the Wi-Fi software stack

Disabling Wi-Fi completely seemed attractive because ROCK64 has no onboard Wi-Fi, but it breaks Google TV setup:

```text
SetupWraith -> WifiManager == null -> NPE
```

Exposing only a fake Wi-Fi feature without the software stack was worse: `WifiServiceImpl` entered an initialization path that could block `system_server`.

Final design: keep Rockchip's Android Wi-Fi framework/HAL/userspace integration even though no physical onboard Wi-Fi device is present.

## 5. SetupWraith vs AOSP Provision

Both Google SetupWraith and AOSP `Provision` were present as setup-wizard candidates. PackageManager could then fail to resolve the setup wizard package correctly.

OpenGApps integration is changed so SetupWraith overrides Provision:

```make
LOCAL_OVERRIDES_PACKAGES := Provision
```

SetupWraith also receives default fine/coarse location permissions required by its Wi-Fi initialization path.

## 6. Android TV UI mode

Firefly's TV overlay used:

```xml
<integer name="config_defaultUiModeType">1</integer>
<bool name="config_lockUiMode">true</bool>
```

This reports a normal UI mode even though the product characteristics say `tv`. Google Play Services then attempted to load resources that exist only in the television configuration and Google sign-in failed.

The fix is:

```xml
<integer name="config_defaultUiModeType">4</integer>
<bool name="config_lockUiMode">true</bool>
```

Runtime validation:

```text
am get-config -> television
IUiModeManager.getCurrentModeType() -> 4
```

## 7. Leanback / TV framework

The project explicitly installs:

    android.software.leanback

This feature is operationally important because SystemServer uses it when
deciding whether to start the TV remote service.

The build does not add a custom `rock64-tv-features.xml` and does not depend
on forcing `android.software.leanback_only` or
`android.hardware.type.television`.

TV operation is instead validated by the product characteristics and
UiModeManager:

    ro.build.characteristics contains tv
    IUiModeManager.getCurrentModeType() -> 4

`com.google.android.tv.installed` may be supplied by the Google TV package
set, but it is not created by the ROCK64 feature XML in this repository.

## 8. Google TV Remote and `/dev/uinput`

Google TV Remote initially failed with:

```text
Cannot open /dev/uinput: Permission denied.
Cannot create device for virtual-remote
```

The Firefly `ueventd.rc` entry owned `/dev/uinput` by `uhid:uhid`; `system_server` did not have access.

Final entry:

```text
/dev/uinput  0660  system  bluetooth
```

After the change, TvRemoteService can create the virtual remote input bridge.

## 9. Preserve MediaShell signature

AOSP's prebuilt processing can uncompress JNI libraries and zipalign a `PRESIGNED` APK. For MediaShell this changes APK bytes and destroys the original APK Signature Scheme v2/v3 signature.

The OpenGApps integration bypasses that transformation for `AndroidMediaShell` by installing the original prebuilt APK verbatim.

The repository does not redistribute MediaShell itself.

## 10. Build packaging trap

Firefly `mkupdate.sh` packages files from:

```text
rockdev/Image-$TARGET_PRODUCT
```

not directly from `out/target/product/...`.

Therefore the safe sequence is always:

```text
make
./mkimage.sh
verify super.img hashes
./FFTools/mkupdate/mkupdate.sh ...
```

Skipping `mkimage.sh` can produce a perfectly valid-looking update image containing an old `super.img`.
