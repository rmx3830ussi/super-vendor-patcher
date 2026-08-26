#!/bin/bash
# Modified badown: mediafire URL resolution unchanged, but the actual
# file transfer uses aria2c (multi-connection) instead of wget.
set -euo pipefail

function file_down_aria2 {
   # $1 = url, $2 = output filename
   aria2c -x 16 -s 16 -k 1M -o "$2" "$1"
}

function mediafire {
   file_url=$(wget -q -O- "$1" \
      | grep :\/\/download \
      | awk -F'"' '{print $2}')
   file_name=$(printf '%b' "$(echo "$file_url" \
      | awk -F'/' '{gsub("%","\\x");gsub("+"," ");print $NF}')")
   echo "Resolved: $file_name  <-  $file_url"
   file_down_aria2 "$file_url" "$file_name"
}

mediafire "$1"
