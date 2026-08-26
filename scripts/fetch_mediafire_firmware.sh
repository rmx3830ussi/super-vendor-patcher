#!/bin/bash
# Usage: fetch_mediafire_firmware.sh <workdir> <url1> <url2> <url3>
set -euo pipefail
WORKDIR="$1"; shift
URLS=("$@")

sudo mkdir -p "$WORKDIR/fw"
sudo chown -R "$(whoami)":"$(whoami)" "$WORKDIR"
cd "$WORKDIR/fw"

echo "== Checking for duplicate mediafire file IDs =="
declare -A seen_ids
for u in "${URLS[@]}"; do
  id="$(echo "$u" | grep -oE '/file/[^/]+' | head -n1 | cut -d'/' -f3)"
  if [ -z "$id" ]; then
    echo "ERROR: could not extract a mediafire file ID from URL: $u" >&2
    exit 1
  fi
  if [ -n "${seen_ids["$id"]+x}" ]; then
    echo "ERROR: duplicate mediafire ID '$id' found in more than one URL." >&2
    echo "  -> $u" >&2
    echo "  -> ${seen_ids["$id"]}" >&2
    exit 1
  fi
  seen_ids["$id"]="$u"
done
echo "No duplicates found."

echo "== Downloading firmware parts via aria2 =="
for u in "${URLS[@]}"; do
  "$OLDPWD/scripts/badown_aria2.sh" "$u"
done
ls -la

echo "== Extracting multi-part 7z archive (auto-detects .002/.003 from .001) =="
FIRST_PART=$(ls -1 *.7z.001 2>/dev/null | head -n1)
if [ -z "$FIRST_PART" ]; then
  echo "ERROR: no *.7z.001 file found among downloads. Files present:" >&2
  ls -la >&2
  exit 1
fi
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
