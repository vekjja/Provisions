#!/usr/bin/env bash
set -euo pipefail

appimage="$1"
home="$2"

filename="${appimage##*/}"
basename_no_ext="${filename%.appimage}"
basename_no_ext="${basename_no_ext%.AppImage}"
slug="$(echo "$basename_no_ext" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"

icons_dir="$home/.local/share/icons/appimages"
extract_dir="$home/.local/share/appimages/extract/$slug"
desktop_dir="$home/.local/share/applications"
desktop_file="$desktop_dir/$slug.desktop"
stamp_file="$icons_dir/$slug.stamp"

mkdir -p "$icons_dir" "$extract_dir" "$desktop_dir"
chmod +x "$appimage"

if [[ -f "$desktop_file" && -f "$stamp_file" && "$stamp_file" -nt "$appimage" ]]; then
  exit 0
fi

rm -rf "$extract_dir"
mkdir -p "$extract_dir"
cd "$extract_dir"
"$appimage" --appimage-extract >/dev/null 2>&1

embedded_desktop="$(find squashfs-root -path '*/applications/*.desktop' -print -quit)"
name=""
comment=""
startup_wm_class=""
categories="Utility;"

if [[ -n "$embedded_desktop" ]]; then
  name="$(grep -m1 '^Name=' "$embedded_desktop" | cut -d= -f2- || true)"
  comment="$(grep -m1 '^Comment=' "$embedded_desktop" | cut -d= -f2- || true)"
  startup_wm_class="$(grep -m1 '^StartupWMClass=' "$embedded_desktop" | cut -d= -f2- || true)"
  categories="$(grep -m1 '^Categories=' "$embedded_desktop" | cut -d= -f2- || true)"
fi

if [[ -z "$name" ]]; then
  name="$(echo "$basename_no_ext" | tr '_-' '  ' | sed -E 's/ +/ /g')"
fi
if [[ -z "$categories" ]]; then
  categories="Utility;"
fi

icon_src="$(find squashfs-root/usr/share/icons -name '*.png' 2>/dev/null | sort -V | tail -1 || true)"
if [[ -z "$icon_src" ]]; then
  icon_src="$(find squashfs-root -maxdepth 1 \( -name '*.png' -o -name '*.svg' \) -print -quit || true)"
fi

icon_dest=""
if [[ -n "$icon_src" && -e "$icon_src" ]]; then
  ext="${icon_src##*.}"
  icon_dest="$icons_dir/$slug.$ext"
  cp -L "$icon_src" "$icon_dest"
fi

{
  echo "[Desktop Entry]"
  echo "Name=$name"
  [[ -n "$comment" ]] && echo "Comment=$comment"
  echo "Exec=$appimage"
  [[ -n "$icon_dest" ]] && echo "Icon=$icon_dest"
  echo "Type=Application"
  echo "Categories=$categories"
  echo "Terminal=false"
  [[ -n "$startup_wm_class" ]] && echo "StartupWMClass=$startup_wm_class"
} > "$desktop_file"

chmod +x "$desktop_file"
touch "$stamp_file"
rm -rf "$extract_dir"
