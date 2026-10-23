# PCVR gameplay and controller input

Goal of this milestone: launch OoT through OpenXR on Windows, render gameplay in stereo, and verify Quest Touch
input reaches the existing N64 controls. Not expected yet: a head-relative OoT camera,
bare-hand tracking/interactions, or Quest standalone packaging.

`Play_Main` now signals gameplay to the runtime; title/menu scenes remain theater. OoT does not provide the
MM-specific HUD display-list pointer, so its complete native gameplay frame is rendered to the stereo views
and the separate HUD quad is omitted. The controller adapter preserves native keyboard/gamepad input when
OpenXR input is not focused and maps the runtime's Touch actions into the game's pad state when active.

1. `tools/fetch-upstream.sh`, then `tools/build-windows.ps1` (see BUILDING.md).
2. Make your own `oot.o2r` from your ROM as Shipwright documents.
3. Set your OpenXR runtime active (Oculus app, or SteamVR), connect the headset, run `soh.exe`.
4. Use F8 to recenter and F7 to toggle stereo. Verify ordinary play, menus, and transitions with the Touch
   controllers; use keyboard/gamepad as a fallback. Do not treat F9 first-person mode as implemented: OoT
   does not yet provide the runtime's required camera callback.

## Verified locally

- Windows x64 Release configuration and full `soh.exe` build with `MMVR_ENABLE=ON`.
- Runtime and game-side `OotVR.cpp` compile and link with the OpenXR loader.
- Seven runtime/core CTest checks pass with `MMVR_BUILD_TESTS=ON`.
- The executable was not launched: a user-provided `oot.o2r` and an active OpenXR headset/runtime are needed
  to validate actual gameplay and controller behavior.

Send back: the build log tail on failure; on a run, `mmvr.log` and `mmvr-frame-timing.json` from the working
directory, plus what you saw (black screen, no headset session, theater visible, crash).

Quest standalone remains unverified and needs separate Android dependency, packaging, and device validation.
