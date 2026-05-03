#!/bin/bash
set -euo pipefail

url="${1:?Usage: $0 <youtube-url>}"

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

############################################################
# 1. Download best audio (no conversion yet)
############################################################
yt-dlp \
  -f bestaudio \
  --no-playlist \
  -o "$workdir/input.%(ext)s" \
  "$url"

input_file="$(find "$workdir" -type f | head -n 1)"

############################################################
# 2. Title → filesystem-safe name
############################################################
title="$(yt-dlp --get-title "$url")"

safe_name="$(printf "%s" "$title" |
  sed -E '
    s/[^a-zA-Z0-9._-]+/./g;
    s/\.+/\./g;
    s/^\.|\.$//g
  ')"

final="${safe_name}.mp3"

############################################################
# 3. Honda-safe MP3 encoding (strict CBR + zero timeline)
############################################################
ffmpeg -y \
  -fflags +genpts \
  -i "$input_file" \
  -map 0:a:0 \
  -vn -sn -dn \
  -af "asetpts=PTS-STARTPTS,aresample=44100" \
  -c:a libmp3lame \
  -ar 44100 \
  -ac 2 \
  -b:a 256k \
  -write_xing 0 \
  -write_id3v1 1 \
  -id3v2_version 3 \
  -map_metadata -1 \
  "$final"

############################################################
# 4. Done
############################################################

echo "Saved as: $final"
