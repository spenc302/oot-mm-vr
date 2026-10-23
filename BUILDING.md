# Building

The Windows x64 Release build has been verified with Visual Studio 2022, CMake, and vcpkg OpenXR.
No headset gameplay or Quest APK has been verified.

1. Run `tools/fetch-upstream.sh` (Linux/WSL2 or Git Bash; needs git and python3). Pass `--no-submodules`
   to skip libultraship/torch while only checking the patch/layout. WSL users: keep the checkout in the
   Linux filesystem, not under `/mnt/c`.
2. On Windows run `tools/build-windows.ps1` after fetching upstream. Otherwise configure Ship of Harkinian from `src/shipwright` as upstream documents, adding `-DMMVR_ENABLE=ON`
   (Windows D3D11 or Android GLES only; the option errors elsewhere).
3. Toolchain versions for the runtime on Windows/Quest follow MM VR's `BUILDING.md`
   (CMake 3.26+, VS 2022, OpenXR via vcpkg; Quest: JDK 17, Android SDK 35, NDK 27, Ninja).

The shared core and platform/session sources live together in `src/mmvr-runtime/`. To build runtime
self-checks, configure with `-DMMVR_BUILD_TESTS=ON`, build the `mmvr-*checks` and
`mmvr-runtime-tests` targets, then run `ctest --test-dir <build>/mmvr-runtime -C Release
--output-on-failure`. Quest standalone packaging, headset gameplay, and on-device behavior still need
validation.
