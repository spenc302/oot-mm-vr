# PCVR gameplay and controller input

This milestone covers OoT's Windows OpenXR path and the initial Quest standalone build. The OoT first-person
camera callback and Quest APK have compile/build coverage, but no headset gameplay has been validated.

`Play_Main` now signals gameplay to the runtime; title/menu scenes remain theater. OoT does not provide the
MM-specific HUD display-list pointer, so its complete native gameplay frame is rendered to the stereo views
and the separate HUD quad is omitted. The controller adapter preserves native keyboard/gamepad input when
OpenXR input is not focused and maps the runtime's Touch actions into the game's pad state when active.

1. `tools/fetch-upstream.sh`, then `tools/build-windows.ps1` (see BUILDING.md).
2. Make your own `oot.o2r` from your ROM as Shipwright documents.
3. Set your OpenXR runtime active (Oculus app, or SteamVR), connect the headset, run `soh.exe`.
4. Use F8 to recenter and F7 to toggle stereo. Verify ordinary play, menus, and transitions with the Touch
   controllers; use keyboard/gamepad as a fallback. F9 requests the first-person view; verify camera height,
   head movement, turning, and that cutscenes/sub-camera views retain their native camera.

## Verified locally

- Windows x64 Release configuration and full `soh.exe` build with `MMVR_ENABLE=ON`.
- Runtime and game-side `OotVR.cpp` compile and link with the OpenXR loader.
- Seven runtime/core CTest checks pass with `MMVR_BUILD_TESTS=ON`.
- OoT now supplies a head-anchored first-person camera view during main-camera gameplay; the callback yields
  to native camera views outside that state. This has compile coverage only, not headset/gameplay validation.
- The executable was not launched: a user-provided `oot.o2r` and an active OpenXR headset/runtime are needed
  to validate actual gameplay and controller behavior.

Send back: the build log tail on failure; on a run, `mmvr.log` and `mmvr-frame-timing.json` from the working
directory, plus what you saw (black screen, no headset session, theater visible, crash).

## Quest 2 APK smoke test

Build with `tools/build-quest.ps1 -Variant Debug`; the arm64 APK is
`android/app/build/outputs/apk/debug/app-debug.apk`. The APK contains no game ROM or copyrighted game assets.

On a Quest 2 with developer mode/ADB enabled:

1. Install `app-debug.apk` with `adb install -r`.
2. Launch the app and provide your own legally obtained `oot.o2r` using the game's supported data/import path.
   The first-run game-data flow has not yet been verified on Android.
3. Check that the app enters VR, the head-tracked stereo view renders and recenters correctly, and the Touch
   controller fallback still drives OoT's native controls.
4. If the runtime exposes `XR_EXT_hand_tracking`, enable hand tracking in Quest settings and test left-hand
   wrist movement for the analog stick; left pinch/fist for Z/L; right pinch/middle-finger pinch/fist for
   A/trigger, C-down, and B. Verify tracking loss releases held buttons. Check the basic hand proxies and note
   their lack of world-depth occlusion.
5. Record launch/crash behavior, controller/hand input, visual artifacts, and performance.

The app was not installed or run because no Android/Quest device is currently connected. Send back the build log
tail on failure; after an on-device run, share `mmvr.log` and `mmvr-frame-timing.json` if available, along with
what you saw (black screen, no headset session, missing game data, tracking/input issues, or crash).
