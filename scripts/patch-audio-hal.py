#!/usr/bin/env python3
"""Patch the Firefly RK3328 audio HAL for ROCK64.

The Firefly prebuilt audio HAL expects /dev/vmdrm0, which does not exist on
ROCK64. This patch makes get_vendor_drm() return 0.

No proprietary binaries are distributed by this project.

Safety rules:
  * known original SHA256 -> patch
  * known patched SHA256  -> leave unchanged
  * anything else         -> abort without modifying the binary
"""

import hashlib
import os
import shutil
import sys
from pathlib import Path

SDK = Path(os.environ.get("SDK", "/opt/devel/Firefly/android10sdk"))

PATCHES = [
    {
        "path": Path(
            "vendor/rockchip/common/tinyalsa/lib/hw/"
            "audio.primary.rk30board.so"
        ),
        "offset": 0x220EA,
        # Thumb: movs r0,#0 ; bx lr
        "bytes": bytes.fromhex("00207047"),
        "original_sha256":
            "14bec190076b480e16726034436217a7e7174faba350582a8d406b16852a2127",
        "patched_sha256":
            "cc6e68b34dedf19c1f805e808794d76b80f66f9c8b3c5e94c434bf6f1d520e59",
    },
    {
        "path": Path(
            "vendor/rockchip/common/tinyalsa/lib64/hw/"
            "audio.primary.rk30board.so"
        ),
        "offset": 0x35AF8,
        # AArch64: mov w0,#0 ; ret
        "bytes": bytes.fromhex("00008052c0035fd6"),
        "original_sha256":
            "01bd0f1c82070022b22763ec9e718e9175f5f58fff3635f1bf8324b1797f8be4",
        "patched_sha256":
            "f5863b85d4a53c46834cf695e8d2eff143e0a350ae74aacab1b60456f2a798c5",
    },
]


def sha256_bytes(data):
    return hashlib.sha256(data).hexdigest()


def sha256_file(path):
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def patch_one(spec):
    path = SDK / spec["path"]

    if not path.is_file():
        raise RuntimeError("missing file: %s" % path)

    current = sha256_file(path)

    if current == spec["patched_sha256"]:
        print("[ OK ] already patched: %s" % spec["path"])
        return

    if current != spec["original_sha256"]:
        raise RuntimeError(
            "unknown Firefly binary: %s\n"
            "       expected original: %s\n"
            "       expected patched:  %s\n"
            "       actual:            %s"
            % (
                spec["path"],
                spec["original_sha256"],
                spec["patched_sha256"],
                current,
            )
        )

    data = bytearray(path.read_bytes())
    off = spec["offset"]
    end = off + len(spec["bytes"])

    if end > len(data):
        raise RuntimeError("patch offset beyond EOF: %s" % path)

    data[off:end] = spec["bytes"]

    result = sha256_bytes(data)
    if result != spec["patched_sha256"]:
        raise RuntimeError(
            "generated patched image has unexpected SHA256 for %s\n"
            "       expected: %s\n"
            "       actual:   %s"
            % (spec["path"], spec["patched_sha256"], result)
        )

    backup = Path(str(path) + ".pre-vmdrm-bypass")

    if backup.exists():
        backup_hash = sha256_file(backup)
        if backup_hash != spec["original_sha256"]:
            raise RuntimeError(
                "existing backup has unexpected SHA256: %s\n"
                "       expected: %s\n"
                "       actual:   %s"
                % (backup, spec["original_sha256"], backup_hash)
            )
    else:
        shutil.copy2(path, backup)

    path.write_bytes(data)

    final = sha256_file(path)
    if final != spec["patched_sha256"]:
        shutil.copy2(backup, path)
        raise RuntimeError(
            "post-write verification failed for %s; original restored"
            % spec["path"]
        )

    print("[ OK ] patched: %s" % spec["path"])
    print("       sha256=%s" % final)


def main():
    for spec in PATCHES:
        patch_one(spec)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print("ERROR: %s" % exc, file=sys.stderr)
        raise SystemExit(1)
