#!/usr/bin/env bash
# Copyright 2026 Dolphin Emulator Project
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail

app_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
binary="$app_dir/dolphin-emu"

if [[ ${1:-} == --help ]]; then
  echo 'Usage: launch-steam-frame.sh [--check | --configure | GAME [Dolphin options...]]'
  echo 'Run --configure once to map a controller, then launch a game through Steam.'
  exit 0
fi

if [[ $(uname -s) != Linux || $(uname -m) != aarch64 ]]; then
  echo 'This launcher requires native ARM64 Linux on Steam Frame.' >&2
  exit 1
fi
if [[ ! -x $binary || ! -d $app_dir/Sys ]]; then
  echo 'Keep the launcher beside dolphin-emu and its Sys directory in the staged application.' >&2
  exit 1
fi
if [[ -n ${XR_RUNTIME_JSON:-} && ! -r $XR_RUNTIME_JSON ]]; then
  echo "XR_RUNTIME_JSON is unreadable: $XR_RUNTIME_JSON" >&2
  exit 1
fi
# Respect the runtime selected by the OpenXR loader. Never hard-code a SteamVR
# installation path or copy a desktop/x86 runtime into the headset package.
if command -v ldd >/dev/null; then
  libraries=$(ldd "$binary" 2>&1) || { echo "$libraries" >&2; exit 1; }
  if [[ $libraries == *'not found'* ]]; then
    echo "$libraries" >&2
    echo 'Missing native runtime libraries; see SteamFrame.md.' >&2
    exit 1
  fi
fi
if [[ ${1:-} == --check ]]; then
  echo 'Native platform, application layout, and linked libraries passed basic checks.'
  echo 'OpenXR session creation, Qt plugins, tracking, and rendering still require a headset launch.'
  exit 0
fi

user_dir=${DOLPHINXR_USER_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/dolphinxr-steam-frame}
mkdir -p "$user_dir"
if [[ ${1:-} == --configure || $# == 0 ]]; then
  [[ $# == 0 ]] || shift
  exec "$binary" --user "$user_dir" --video_backend Vulkan "$@"
fi
game=$1
shift
if [[ ! -f $game ]]; then
  echo "Game file not found: $game" >&2
  exit 1
fi
exec "$binary" --user "$user_dir" --video_backend Vulkan \
  --config GFX.VR.EnableOpenXR=True --config GFX.VR.FlatScreen=False \
  --config GFX.VR.MirrorView=3 --batch --exec "$game" "$@"
