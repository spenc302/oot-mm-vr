# Building

The Windows x64 Release build has been verified with Visual Studio 2022, CMake, and vcpkg OpenXR.
A Quest 2 arm64 Debug APK also builds successfully; headset gameplay and on-device behavior have not
been verified.

1. Run `tools/fetch-upstream.sh` (Linux/WSL2 or Git Bash; needs git and python3). Pass `--no-submodules`
   to skip libultraship/torch while only checking the patch/layout. WSL users: keep the checkout in the
   Linux filesystem, not under `/mnt/c`.
2. On Windows run `tools/build-windows.ps1` after fetching upstream. Otherwise configure Ship of Harkinian from `src/shipwright` as upstream documents, adding `-DMMVR_ENABLE=ON`
   (Windows D3D11 or Android GLES only; the option errors elsewhere).
3. For Quest, install JDK 17, then install the Android SDK packages (review Google's license terms first):
   `powershell -ExecutionPolicy Bypass -File tools/install-quest-sdk.ps1 -AcceptLicenses`.
   The script installs Android SDK 35, NDK 27.2.12479018, Build Tools 35.0.0, and CMake 3.30.3 under
   `%LOCALAPPDATA%\Android\Sdk`. It requires `-AcceptLicenses` because it accepts the Android SDK
   licenses on your behalf.
4. Build the APK from the repository root with
   `powershell -ExecutionPolicy Bypass -File tools/build-quest.ps1 -Variant Debug`.
   The resulting APK is `android/app/build/outputs/apk/debug/app-debug.apk`. The app targets arm64-v8a,
   uses GLES 3, and loads the statically linked SDL2/SoH native library. Release signing and device
   installation are not configured by this test pipeline.

The shared core and platform/session sources live together in `src/mmvr-runtime/`. To build runtime
self-checks, configure with `-DMMVR_BUILD_TESTS=ON`, build the `mmvr-*checks` and
`mmvr-runtime-tests` targets, then run `ctest --test-dir <build>/mmvr-runtime -C Release
--output-on-failure`. Bring your own legally obtained game dump; it is not bundled in the APK. Quest
standalone gameplay, hand tracking, controller fallback, and performance still need on-device validation.
