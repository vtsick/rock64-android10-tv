# Known issues

## Google Play Store

Play Store opens `com.google.android.finsky.accessrestricted.AccessRestrictedActivity` with the message that the application version is incompatible with the device.

The issue persists after testing newer Android TV Play Store and Google Play Services packages. The finished project therefore treats Play Store as unsupported and uses sideloading instead.

## Chromecast / MediaShell

The Cast receiver can start and advertise itself, but special Cast X509 certificate provisioning may return HTTP 401 `Invalid Credentials` from `cast.google.com`.

Ordinary Widevine provisioning was verified separately and succeeds. Do not conflate the Cast certificate failure with general Widevine/DRM failure.

## No onboard Wi-Fi / Bluetooth

ROCK64 has neither onboard Wi-Fi nor Bluetooth. Bluetooth is disabled in the build. The Android Wi-Fi software stack is retained intentionally for framework/SetupWraith compatibility.
