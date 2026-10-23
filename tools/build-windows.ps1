# Configure and build Ship of Harkinian with the MMVR runtime on Windows (PCVR / D3D11).
# Run from the repo root in PowerShell after tools/fetch-upstream.sh (Git Bash or WSL).
# A temporary drive mapping keeps vcpkg's batch bootstrap safe when the repo path has spaces.
param([ValidateSet('Release','Debug')][string]$Config = 'Release')
$ErrorActionPreference = 'Stop'
$cmake = (Get-Command cmake -ErrorAction SilentlyContinue).Source
if (-not $cmake) { $cmake = 'C:\Program Files\CMake\bin\cmake.exe' }
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$usedDrives = (Get-PSDrive -PSProvider FileSystem).Name
$drive = @('Z', 'Y', 'W', 'V', 'U', 'T', 'S', 'R', 'Q', 'P') |
    Where-Object { $_ -notin $usedDrives } |
    Select-Object -First 1
if (-not $drive) { throw 'No free drive letter is available for the temporary build path.' }
& subst.exe "${drive}:" $repo
if ($LASTEXITCODE) { throw 'Could not create a temporary drive mapping for the build.' }
$mappedRepo = "${drive}:\"
$src = Join-Path $mappedRepo 'src\shipwright'
if (-not (Test-Path (Join-Path $src 'libultraship\CMakeLists.txt'))) {
    & subst.exe "${drive}:" /D
    throw 'Submodules missing. Run tools/fetch-upstream.sh without --no-submodules first.'
}
$build = Join-Path $mappedRepo "build\vr-$drive"
try {
    & $cmake -S $src -B $build -G 'Visual Studio 17 2022' -T v143 -A x64 -DMMVR_ENABLE=ON
    if ($LASTEXITCODE) { throw 'configure failed' }
    & $cmake --build $build --config $Config
    if ($LASTEXITCODE) { throw 'build failed' }
    $executable = Join-Path $src "x64\$Config\soh.exe"
    Write-Host "Built. Generate oot.o2r per Shipwright's docs (your own ROM), then run $executable"
} finally {
    & subst.exe "${drive}:" /D
}
