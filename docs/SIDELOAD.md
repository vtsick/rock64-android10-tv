# Sideloading applications

Google Play Store is not required for the intended use of this image. APKs can be installed over ADB.

Single APK:

```bash
adb install -r app.apk
```

Split APK set:

```bash
adb install-multiple -r base.apk config.arm64_v8a.apk config.xhdpi.apk
```

The ROCK64 Android 10 build reports `arm64-v8a` as the primary ABI and supports `armeabi-v7a` compatibility.

Examples successfully used with this box include IPTV clients, Jellyfin, YouTube, and Spotify. Observe the distribution/license terms of each application; this repository does not redistribute third-party APKs.
