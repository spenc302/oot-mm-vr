# Building

The controller/gameplay integration and platform-runtime CMake wiring are awaiting their first build.
No full SoH build or Quest APK has been verified.

1. Run `tools/fetch-upstream.sh` (Linux/WSL2 or Git Bash; needs git and python3). Pass `--no-submodules`
   to skip libultraship/torch while only checking the patch/layout. WSL users: keep the checkout in the
   Linux filesystem, not under `/mnt/c`.
2. On Windows run `tools/build-windows.ps1` after fetching upstream. Otherwise configure Ship of Harkinian from `src/shipwright` as upstream documents, adding `-DMMVR_ENABLE=ON`
   (Windows D3D11 or Android GLES only; the option errors elsewhere).
3. Toolchain versions for the runtime on Windows/Quest follow MM VR's `BUILDING.md`
   (CMake 3.26+, VS 2022, OpenXR via vcpkg; Quest: JDK 17, Android SDK 35, NDK 27, Ninja).

The shared core and platform/session sources live together in `src/mmvr-runtime/`. Not yet verified:
any full SoH build with `MMVR_ENABLE`; compilation,
linking, Quest standalone packaging, and on-device behavior still need validation.
