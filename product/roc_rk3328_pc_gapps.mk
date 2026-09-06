# ROCK64 Android 10 TV build with OpenGApps TVStock

$(call inherit-product, device/rockchip/rk3328/roc_rk3328_pc/roc_rk3328_pc.mk)

GAPPS_VARIANT := tvstock
$(call inherit-product, vendor/opengapps/build/opengapps-packages.mk)

PRODUCT_NAME := roc_rk3328_pc_gapps
PRODUCT_MODEL := ROCK64 Android TV 10 GApps

# Google TV SetupWraith assumes that WifiManager exists even on this
# Ethernet-only ROCK64 target. Keep the Android/Rockchip Wi-Fi software
# stack enabled even though ROCK64 has no onboard Wi-Fi hardware.
PRODUCT_COPY_FILES += \
    device/rockchip/rk3328/roc_rk3328_pc/setupwraith-default-permissions.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/default-permissions/setupwraith-default-permissions.xml

# Required by SystemServer to start TvRemoteService.
PRODUCT_COPY_FILES += \
    device/rockchip/rk3328/roc_rk3328_pc/android.software.leanback.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/android.software.leanback.xml
