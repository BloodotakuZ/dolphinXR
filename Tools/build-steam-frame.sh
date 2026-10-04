#!/usr/bin/env bash
# Copyright 2026 Dolphin Emulator Project
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail

if [[ $(uname -s) != Linux || $(uname -m) != aarch64 ]]; then
  echo 'Build on an ARM64 Linux host. This script does not cross-compile or use FEX.' >&2
  exit 1
fi

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo"
cmake --preset steam-frame "$@"
cmake --build --preset steam-frame --parallel "${DOLPHINXR_BUILD_JOBS:-$(nproc)}"

# A relocatable application layout, not a self-contained distribution: system
# Qt/audio/etc. libraries must still be available on the target.
package="$repo/dist/dolphinxr-steam-frame"
mkdir -p "$package"
cp Build-steam-frame/Binaries/dolphin-emu "$package/"
cp -a Data/Sys "$package/"
cp -a LICENSES "$package/"
cp COPYING "$package/"
cp docs/SteamFrame.md "$package/"
cp Tools/launch-steam-frame.sh "$package/launch-steam-frame.sh"
chmod +x "$package/launch-steam-frame.sh"
git rev-parse HEAD > "$package/source-revision.txt"
ldd "$package/dolphin-emu" > "$package/build-host-libraries.txt"
echo "Application staged in $package"
