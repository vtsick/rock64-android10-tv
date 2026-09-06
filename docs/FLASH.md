# Flashing

The intended installation method is a Rockchip **update image over USB Loader/MaskRom**, not raw eMMC writing through an adapter.

Typical workflow:

1. Build `ROCK64_Android10_TV.img` with `scripts/build.sh`.
2. Put ROCK64 into Rockchip Loader or MaskRom mode.
3. Use Rockchip's Linux upgrade tool or RKDevTool on Windows to write the update image to eMMC.
4. Boot the board and allow the first Android initialization to complete.
5. Run:

```bash
./scripts/postboot-check.sh
```

If multiple ADB targets are present:

```bash
ADB_SERIAL=<serial> ./scripts/postboot-check.sh
```

Do not substitute a raw partition image for the generated Rockchip update image unless you explicitly understand and intend that different flashing workflow.
