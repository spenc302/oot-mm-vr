# Building

Milestone 0 only gets the tree into shape; a VR build is not expected to work yet.

1. `tools/fetch-upstream.sh` (Linux/WSL2 or Git Bash; needs git and python3). Pass `--no-submodules`
   to skip libultraship/torch while only checking the patch/layout. WSL users: keep the checkout in the
   Linux filesystem, not under `/mnt/c`.
2. On Windows run `tools/build-windows.ps1`, which does this step. Otherwise configure Ship of Harkinian from `src/shipwright` as upstream documents, adding `-DMMVR_ENABLE=ON`
   (Windows D3D11 or Android GLES only; the option errors elsewhere).
3. Toolchain versions for the runtime on Windows/Quest follow MM VR's `BUILDING.md`
   (CMake 3.26+, VS 2022, OpenXR via vcpkg; Quest: JDK 17, Android SDK 35, NDK 27, Ninja).

Not yet verified: any full SoH build with `MMVR_ENABLE`. `MMVR_ENABLE=ON` will currently fail at link
time because libultraship has no MMVR hooks yet (see M1 in `docs/ARCHITECTURE.md`).
