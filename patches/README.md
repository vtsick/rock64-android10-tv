# Source patchset

`local-source-fixes.patch` contains the tracked source changes required for
the ROCK64 Android 10 TV build.

Normal users do not need to regenerate this file. It is applied automatically
by `scripts/apply-patches.sh`.

`scripts/export-current-patches.sh` is a maintainer utility used only against
the known-good, already-fixed reference SDK when the source patchset needs to
be regenerated.

The proprietary Firefly audio HAL binaries are not stored in this repository.
Their small binary modification is reproduced separately by
`scripts/patch-audio-hal.py`, which accepts only known original or
already-patched SHA256 hashes.
