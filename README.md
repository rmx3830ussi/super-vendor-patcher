# Super Vendor Patcher

Patches Unisoc device fstab files inside the vendor image to disable
File-Based Encryption (FBE), then repacks the super/vendor partitions
and regenerates vbmeta.

## What it does

For each fstab file listed in `config/`, removes:
- `fileencryption=aes-256-xts:aes-256-cts:v2+inlinecrypt_optimized`
- `keydirectory=/metadata/vold/metadata_encryption`
- `inlinecrypt` (preceding the fileencryption flag)

## Supported fstab files

- fstab.uis7863_6h10 / fstab.uis7863_6h10_go
- fstab.uis7865_6h10 / fstab.uis7865_6h10_go
- fstab.ums9230_1h10 / fstab.ums9230_1h10_go
- fstab.ums9230_4h10 / fstab.ums9230_4h10_go
- fstab.ums9230_6h10 / fstab.ums9230_6h10_go
- fstab.ums9230_14c10_go
- fstab.ums9230_dhaka / fstab.ums9230_dhaka_go
- fstab.ums9230_hulk / fstab.ums9230_hulkU
- fstab.ums9230_latte

## Structure

- `config/` — patch definitions (which files, what to strip)
- `patches/` — reference patched fstab files
- `scripts/` — unpack/patch/repack helper scripts
- `.github/workflows/` — CI build (TBD)

## Status

Work in progress.
