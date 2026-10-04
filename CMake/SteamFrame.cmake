# Copyright 2026 Dolphin Emulator Project
# SPDX-License-Identifier: GPL-2.0-or-later

# This profile targets the Linux OS running directly on the headset.
# Do not silently produce an x86, Android, or interpreter-only artifact.
if(NOT CMAKE_SYSTEM_NAME STREQUAL "Linux" OR ANDROID OR NOT _M_ARM_64 OR ENABLE_GENERIC)
  message(FATAL_ERROR "Steam Frame requires native Linux ARM64 with the ARM64 JIT. Use an ARM64 Linux build host or an ARM64 Linux toolchain/sysroot.")
endif()

if(NOT ENABLE_VR OR NOT ENABLE_VULKAN OR NOT ENABLE_QT OR ENABLE_HEADLESS)
  message(FATAL_ERROR "Steam Frame requires ENABLE_VR, ENABLE_VULKAN, and ENABLE_QT, with ENABLE_HEADLESS=OFF. The current headless Vulkan presenter is not suitable for headset rendering.")
endif()

message(STATUS "Steam Frame: Linux ARM64 JIT, Vulkan, OpenXR, and Qt frontend")
