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

echo "== Recursively extracting any nested archives until a .pac appears =="
EXTRACT_DIR="$WORKDIR/fw/extracted"
for pass in 1 2 3 4 5; do
  PAC_CHECK=$(find "$EXTRACT_DIR" -iname "*.pac" | head -n1)
  if [ -n "$PAC_CHECK" ]; then
    echo "Found .pac on pass $pass: $PAC_CHECK"
    break
  fi
  NESTED=$(find "$EXTRACT_DIR" -type f \( -iname "*.zip" -o -iname "*.rar" -o -iname "*.7z" \))
  if [ -z "$NESTED" ]; then
    echo "No .pac and no further nested archives found on pass $pass. Stopping."
    break
  fi
  echo "-- Pass $pass: found nested archive(s), extracting --"
  echo "$NESTED"
  while IFS= read -r archive; do
    dest="${archive%.*}_extracted"
    sudo 7z x "$archive" -o"$dest" -y
    sudo rm -f "$archive"
  done <<< "$NESTED"
done

echo "== Locating .pac file =="
PAC_FILE=$(find "$EXTRACT_DIR" -iname "*.pac" | head -n1)
if [ -z "$PAC_FILE" ]; then
  echo "ERROR: no .pac file found after recursive extraction. Contents:" >&2
  find "$EXTRACT_DIR" -type f >&2
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
