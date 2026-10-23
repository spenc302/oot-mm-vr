# First test (PCVR theater mode)

Goal of this milestone: OoT appears on a virtual screen in the headset on a Windows PC (Quest 2 via Link or
Air Link, or any OpenXR runtime). Not expected yet: head-tracked world view, hand input, Quest standalone.

Why theater: the runtime defaults to theater mode (`sceneGameplay = false`) until game code calls
`mmvr::SetScene(true, ...)`, and nothing in OoT does that yet. The D3D11 backend hooks in patch 0002 submit
the finished frame to the headset, so no OoT game-side code is needed for this.

1. `tools/fetch-upstream.sh`, then `tools/build-windows.ps1` (see BUILDING.md).
2. Make your own `oot.o2r` from your ROM as Shipwright documents.
3. Set your OpenXR runtime active (Oculus app, or SteamVR), connect the headset, run `soh.exe`.
4. Keys (from the libultraship hooks): F8 recenter, F7 toggle stereo, F9 toggle first person.
   Play with keyboard or a gamepad; XR controller to N64 pad mapping does not exist for OoT yet.

Send back: the build log tail on failure; on a run, `mmvr.log` and `mmvr-frame-timing.json` from the working
directory, plus what you saw (black screen, no headset session, theater visible, crash).

Likely first failures: vcpkg not finding `openxr-loader`; link errors from libultraship hooks that reference
MM-only runtime symbols; a runtime that expects MM data files.
