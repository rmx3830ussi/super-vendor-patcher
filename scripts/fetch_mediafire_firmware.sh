#!/bin/bash
# Usage: fetch_mediafire_firmware.sh <workdir> <url1> [url2] [url3] ...
set -euo pipefail
WORKDIR="$1"; shift
URLS=("$@")

sudo mkdir -p "$WORKDIR/fw"
sudo chown -R "$(whoami)":"$(whoami)" "$WORKDIR"
cd "$WORKDIR/fw"

echo "== Downloading firmware parts via aria2 =="
for u in "${URLS[@]}"; do
  "$OLDPWD/scripts/badown_aria2.sh" "$u"
done
ls -la

echo "== Extracting multi-part 7z archive (auto-detects .002/.003 from .001) =="
FIRST_PART=$(ls -1 *.7z.001 | head -n1)
sudo 7z x "$FIRST_PART" -o"$WORKDIR/fw/extracted" -y

echo "== Locating .pac file =="
PAC_FILE=$(find "$WORKDIR/fw/extracted" -iname "*.pac" | head -n1)
if [ -z "$PAC_FILE" ]; then
  echo "ERROR: no .pac file found after extraction" >&2
  exit 1
fi
echo "Found: $PAC_FILE"

echo "== Extracting .pac with PAC-Extractor =="
git clone --depth=1 https://github.com/bismoy-bot/PAC-Extractor.git "$WORKDIR/PAC-Extractor"
python3 "$WORKDIR/PAC-Extractor/extractor.py" "$PAC_FILE" "$WORKDIR/pac_out"

echo "== Locating super.img =="
SUPER_IMG=$(find "$WORKDIR/pac_out" -iname "super.img" | head -n1)
if [ -z "$SUPER_IMG" ]; then
  echo "ERROR: super.img not found inside extracted .pac" >&2
  exit 1
fi
sudo mv "$SUPER_IMG" "$HOME/super.img"
echo "Moved to: $HOME/super.img"
