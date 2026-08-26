#!/bin/bash
# Strips FBE encryption flags from a single fstab file (in place).
# Usage: strip_encryption.sh <fstab-file>
set -euo pipefail
f="$1"
sed -i \
  -e 's/inlinecrypt,fileencryption=aes-256-xts:aes-256-cts:v2+inlinecrypt_optimized/fileencryption=aes-256-xts:aes-256-cts/' \
  -e 's/,fileencryption=aes-256-xts:aes-256-cts:v2+inlinecrypt_optimized//' \
  -e 's/,keydirectory=\/metadata\/vold\/metadata_encryption//' \
  "$f"
echo "Patched: $f"
