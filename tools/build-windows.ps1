# Configure and build Ship of Harkinian with the MMVR runtime on Windows (PCVR / D3D11).
# Untested: written from Shipwright's BUILDING.md and Majora's Mask VR's build notes.
# Run from the repo root in PowerShell after tools/fetch-upstream.sh (Git Bash or WSL).
param([ValidateSet('Release','Debug')][string]$Config = 'Release')
$ErrorActionPreference = 'Stop'
$cmake = (Get-Command cmake -ErrorAction SilentlyContinue).Source
if (-not $cmake) { $cmake = 'C:\Program Files\CMake\bin\cmake.exe' }
$src = Join-Path $PSScriptRoot '..\src\shipwright' | Resolve-Path
if (-not (Test-Path (Join-Path $src 'libultraship\CMakeLists.txt'))) {
    throw 'Submodules missing. Run tools/fetch-upstream.sh without --no-submodules first.'
}
$build = Join-Path $PSScriptRoot '..\build\x64'
& $cmake -S $src -B $build -G 'Visual Studio 17 2022' -T v143 -A x64 -DMMVR_ENABLE=ON
if ($LASTEXITCODE) { throw 'configure failed' }
& $cmake --build $build --config $Config
if ($LASTEXITCODE) { throw 'build failed' }
Write-Host "Built. Generate oot.o2r per Shipwright's docs (your own ROM), then run soh.exe from $build\soh\$Config"
