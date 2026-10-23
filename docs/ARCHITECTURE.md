# Architecture and milestones

## How Majora's Mask VR is wired (observed in v0.36)
- `src/mmvr-runtime`: shared OpenXR core, session, stereo/projection, frame and GPU timing, GLES multiview, input and
  controller profiles, comfort/locomotion helpers (~18k lines, 118 files). Exposes ~28 `extern "C" MMVR_*` functions.
- `2s2h/VR`: ~34k lines of game-side code that calls the runtime from player/actor/camera code.
- Vendored, modified `libultraship`: ~220 `MMVR` references, mostly `interpreter.cpp` (99),
  `gfx_opengl.cpp` (51), `gfx_direct3d11.cpp` (21), `Fast3dWindow.cpp` (10).
- CMake: option `MMVR_ENABLE`, `add_subdirectory(../mmvr-runtime)` from the Shipwright root, link to libultraship and the game target.
  `patches/0001` reproduces this for Shipwright (verified to apply to the pinned commit; not built).

## Known gaps
- Roughly 5.7k of the runtime's 18k lines looked game-agnostic by a crude keyword scan; the rest touches
  MM concepts (forms, masks, bottles, Kafei). Needs a real split before OoT can share it cleanly.
- Shipwright's libultraship is a submodule (kenix3 `port-maintenance`). It needs equivalent hooks to MM's;
  oot-vr's `libultraship` VR files (from ShinyWindow's libultraship-vr, MIT) are a reference.
- The runtime's self-checks compile with MSVC/NDK clang; g++ rejects `core_tests.cpp` (same on MM's original).
  They have not been run here.
- No Quest 2 performance baseline exists for either game.
- Quest Touch actions are now copied into OoT's native pad input on the game thread; the fallback path keeps
  regular keyboard/gamepad input when XR actions are inactive.
- OoT marks `Play_Main` as gameplay, enabling the runtime's gameplay presentation. OoT still has no
  game-specific camera callback, hand-tracking extension, tracked-hand renderer, or full item/combat adapter.
- Stereo gameplay no longer depends on MM's separate HUD pointer: OoT's native frame is rendered directly to
  the stereo views, and the runtime's separate HUD quad is omitted when no overlay list is supplied.
- Quest standalone remains unverified: Android OpenXR dependency discovery, app lifecycle, and APK packaging
  need end-to-end work and a device build.

## Milestones
- M0: layout, pinned upstream, CMake patch, stub `OotVR` hooks.
- M1a (done, unbuilt): `patches/0002` ports MM's libultraship VR hooks onto Shipwright's pinned libultraship.
- M1b (in progress): compile/link the runtime and libultraship hooks, then verify stereo gameplay and Touch-to-N64 input on PCVR.
- M2: head-relative OoT camera callback, bare-hand tracking/visuals, VR settings, and Quest Android dependency/build/package lifecycle.
- M3: game-specific hands, items, bow/hookshot, combat, climbing, ocarina, and comfort/accessibility polish.
- M4: split runtime into game-agnostic core + per-game adapters; shared settings so both games match.

## patches/0002 (libultraship hooks)
Derived by diffing MM VR's vendored `libultraship` against its recorded baseline (kenix3 `7cb1022`),
after normalizing CRLF line endings, then trial-applying to Shipwright's pinned `da6daf1`.
The two baselines differ in only 7 files, so only one hunk conflicted (the custom-shader push/pop in
`interpreter.cpp`); it was resolved by hand, keeping Shipwright's empty-stack guard in `gfx_pop_shader`.
- Included: 32 files, +5.3k/-0.5k lines: Fast3D interpreter, OpenGL/D3D11/DXGI/SDL2 backends, window/gui,
  GBI headers, and the interpreter test `.inc` files (which `interpreter.cpp` includes unconditionally),
  plus `host_address.h`, `SDLAudioPlayer.h` and `ControlDeck.cpp`.
- Left out as not VR-related: MM's config/resource/archive hardening (atomic config writes, resource loader and
  manager changes, stb checksum pinning, Context/CrashHandler edits). Port separately if wanted.
- Verified: applies cleanly with `git apply --check` to the pinned libultraship.
- Not verified: that it compiles, or that Shipwright-specific code paths (for example OoT's own display-list and
  shader usage) behave with the hooks. Android needs the OpenXR loader and SDL2 targets MM defines in
  `CMake/MMVR-AndroidDependencies.cmake`; not ported yet (M2).

## Changes since M1a
- `patches/0003`: adds the vcpkg port `openxr-loader` to libultraship's Windows package list when `MMVR_ENABLE` is set.
- `patches/0004`: feeds active OpenXR pad state into OoT's `Input` after native pad acquisition and signals gameplay
  when `Play_Main` is running. The native input path remains active if XR input is unavailable.
- `patches/0001` reordered: runtime is added after libultraship (so vcpkg has run), links `ImGui` for
  `imgui.h`, then links into libultraship and the game.
- Runtime copy: MM's published CMake references `tests/periodic-report-check.cpp`, which MM's repo omits, so that
  target is dropped here; remaining self-check executables are `EXCLUDE_FROM_ALL`. `tests/prop-contact-benchmark.cpp` added.
- All patches verified with `git apply --check` only. Nothing has been compiled.
