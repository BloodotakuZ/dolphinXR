# DolphinXR on Steam Frame

This is an **experimental native Linux ARM64 build profile**, using Dolphin's
ARM64 JIT, Vulkan, and the existing OpenXR renderer. Emulation runs on the
headset. It does not require a streaming PC, Proton, FEX, or an Android APK.
It has not yet been validated on Steam Frame hardware. A successful CI build
proves compilation and basic startup, not a working VR session or game speed.

Valve recommends Linux ARM64 and OpenXR for custom native applications:
https://partner.steamgames.com/doc/steamhardware/steamframe/engines/custom

## Build

Use a native ARM64 Linux build host with GCC 12+ or Clang 15+, CMake 3.21+,
Ninja, Qt 6 (Core/Gui/Widgets/Svg and private development headers), OpenGL/EGL,
X11/Xrandr/XInput, libudev/libevdev, ALSA/PulseAudio, USB, HID, Bluetooth,
curl development packages, and gettext. Other dependencies can be built from
the pinned submodules. Do not change the immutable headset OS to install a
compiler: use a separate ARM64 build machine/container with a target-compatible
sysroot or an appropriate development environment.

```sh
git clone https://github.com/BloodotakuZ/dolphinXR.git
cd dolphinXR
git submodule update --init --recursive
bash Tools/build-steam-frame.sh
```

The script stages `dist/dolphinxr-steam-frame/`, with the executable, `Sys`,
licenses, and launcher. `DOLPHINXR_BUILD_JOBS=4` limits build parallelism.
The `steam-frame` CMake preset rejects x86, Android, generic/interpreter builds,
disabled VR/Vulkan, and headless configurations. For cross-compilation, use
`cmake --preset steam-frame` with a Linux ARM64 toolchain and matching sysroot;
the convenience script deliberately supports only native build hosts.

The GitHub **Steam Frame native ARM64** workflow compiles on Ubuntu 24.04 ARM64
and uploads a development archive. This archive is **not self-contained**:
Qt plugins, audio/input libraries, and other linked libraries must be available
on the target. `build-host-libraries.txt` records dependencies. Ubuntu artifacts
must be checked against the actual SteamOS libraries; do not assume ABI
compatibility or copy arbitrary libraries onto the headset. A SteamOS-compatible
distribution package remains a separate milestone.

The OpenXR SDK is pinned to the public 1.1.63 release. The inherited gitlink
referenced `a170408a4dc893da8b5cc3955455917603a4d305`, which the configured
Khronos remote could not fetch. Exceptions are enabled only for the SDK loader
target: this release contains unconditional `try`/`catch` blocks, even with its
exception-handling option disabled. Dolphin keeps its `-fno-exceptions` build.
The inherited fmt gitlink also references an unavailable commit
(`ebd44f36916fb4f02b9c83cba21aff294deea66a`); it is replaced with the public
12.0.0 release. The remaining Linux dependency gitlinks were successfully
retrieved during preparation of this profile.

## Deploy and launch

Enable Developer Mode and transfer the entire staged application directory
using Valve's SteamOS Devkit Client:
https://partner.steamgames.com/doc/steamhardware/steamframe/loadgames

Add `launch-steam-frame.sh` as a native non-Steam application or use the Devkit
Client. Do not enable a Steam compatibility tool for this executable.
The launch script must be beside `dolphin-emu` and `Sys`, and executable.

```sh
./launch-steam-frame.sh --check
./launch-steam-frame.sh --configure
./launch-steam-frame.sh "/path/to/game.rvz"
```

`--check` checks architecture, application layout, and linked libraries. It does
not create an OpenXR session or validate Qt plugins. `--configure` opens the Qt
frontend to configure games, controller bindings, and VR options. Running a game
selects Vulkan, enables immersive OpenXR mode, and disables the desktop mirror.
Additional Dolphin options are accepted after the game path, for example
`--config GFX.VR.ResolutionScale=0.75` for a lower eye render resolution.
These command-line settings are temporary. They do not rewrite graphics config.

User data is kept separately in
`${XDG_DATA_HOME:-$HOME/.local/share}/dolphinxr-steam-frame`.
Set `DOLPHINXR_USER_DIR` to choose another save/config directory.
The launcher respects OpenXR runtime discovery and `XR_RUNTIME_JSON`; it does
not assume a particular Steam installation path or replace the active runtime.

The frontend currently requires a working desktop compositor / Qt platform
plugin even when the mirror is disabled. Launch through Steam's native desktop
environment. **Do not select NoGUI headless mode**: the inherited Vulkan
presenter skips presentation when there is no desktop swapchain. A direct
headset-only frontend needs further renderer work.

## Controllers and performance

Valve documents Oculus Touch emulation for Frame controllers by default. The
fork already suggests Oculus Touch OpenXR bindings. Map those inputs to the
desired GameCube/Wii controls in Dolphin; controller mappings, tracking offsets,
and reconnect behavior still need headset testing. A gamepad is a useful first
test. The Frame-specific interaction profile is not added by this milestone.

Start with native internal resolution and no MSAA; increase settings only after
measuring both emulation speed and XR frame time. GameCube/Wii game cadence and
headset display cadence differ. The existing XR pacing logic needs measurement
on Frame before making smoothness or full-speed claims.

The renderer has optional fixed foveation support. Eye-tracked foveation is
**not implemented** by this build profile. Do not equate Valve's foveated
streaming with native foveated game rendering.

## Hardware acceptance checks

- Confirm the deployed ELF is AArch64 and native libraries/Qt plugins resolve.
- Open a Vulkan OpenXR session; check the runtime-selected physical GPU.
- Confirm both eyes, stereo projection, 6DoF tracking, and recentering.
- Map buttons, sticks, grips, and triggers; test reconnect and headset sleep.
- Run representative GameCube and Wii games and check saves and audio.
- Measure emulation speed, XR frame pacing, resolution, temperature, and battery.
- Test shutdown, repeated game launches, and runtime/session loss.

Remaining work includes headset validation, SteamOS-compatible packaging,
controller defaults, and a frontend that can operate entirely inside VR.
