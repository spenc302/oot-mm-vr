param(
    [string]$SdkRoot = (Join-Path $env:LOCALAPPDATA 'Android\Sdk'),
    [switch]$AcceptLicenses
)

$ErrorActionPreference = 'Stop'
if (-not $AcceptLicenses) {
    throw 'Review Google Android SDK license terms, then rerun with -AcceptLicenses to install SDK components.'
}

$jdk = $env:JAVA_HOME
if (-not $jdk -or -not (Test-Path (Join-Path $jdk 'bin\java.exe'))) {
    $jdk = Get-ChildItem (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft') -Directory -Filter 'jdk-17*' -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty FullName
}
if (-not $jdk -or -not (Test-Path (Join-Path $jdk 'bin\java.exe'))) {
    throw 'Install a JDK 17 before installing Android SDK packages.'
}
$env:JAVA_HOME = $jdk
$env:PATH = (Join-Path $jdk 'bin') + ';' + $env:PATH

$toolsVersion = '16111833'
$toolsUrl = "https://dl.google.com/android/repository/commandlinetools-win-$($toolsVersion)_latest.zip"
$toolsHash = '57d04f2d75eb8e8fffc5000a987e5de4b5a63e9d'
$toolsRoot = Join-Path $SdkRoot 'cmdline-tools'
$latest = Join-Path $toolsRoot 'latest'
$sdkManager = Join-Path $latest 'bin\sdkmanager.bat'
if (-not (Test-Path $sdkManager)) {
    $staging = Join-Path $env:TEMP "android-cmdline-tools-$toolsVersion"
    $archive = "$staging.zip"
    New-Item -ItemType Directory -Force -Path $staging, $toolsRoot | Out-Null
    $curl = Get-Command curl.exe -ErrorAction Stop
    & $curl.Source -L --fail --silent --show-error $toolsUrl -o $archive
    if ($LASTEXITCODE -ne 0) { throw 'Could not download Android command-line tools.' }
    $actualHash = (Get-FileHash -Path $archive -Algorithm SHA1).Hash.ToLowerInvariant()
    if ($actualHash -ne $toolsHash) {
        throw "Android command-line tools checksum mismatch: expected $toolsHash, got $actualHash."
    }
    Expand-Archive -Path $archive -DestinationPath $staging -Force
    Move-Item -Path (Join-Path $staging 'cmdline-tools') -Destination $latest -Force
    $sdkManager = Join-Path $latest 'bin\sdkmanager.bat'
}

$env:ANDROID_HOME = $SdkRoot
$env:ANDROID_SDK_ROOT = $SdkRoot
$processInfo = New-Object System.Diagnostics.ProcessStartInfo
$processInfo.FileName = $env:ComSpec
$processInfo.Arguments = '/d /s /c ""{0}" --sdk_root="{1}" --licenses"' -f $sdkManager, $SdkRoot
$processInfo.UseShellExecute = $false
$processInfo.RedirectStandardInput = $true
$process = New-Object System.Diagnostics.Process
$process.StartInfo = $processInfo
if (-not $process.Start()) { throw 'Could not start sdkmanager to accept the reviewed SDK licenses.' }
for ($i = 0; $i -lt 100; $i++) { $process.StandardInput.WriteLine('y') }
$process.StandardInput.Close()
$process.WaitForExit()
if ($process.ExitCode -ne 0) { throw "sdkmanager license step failed with exit code $($process.ExitCode)." }

$processInfo.Arguments = '/d /s /c ""{0}" --sdk_root="{1}" "platform-tools" "platforms;android-35" "build-tools;35.0.0" "ndk;27.2.12479018" "cmake;3.30.3"' -f $sdkManager, $SdkRoot
$processInfo.RedirectStandardInput = $false
$process = New-Object System.Diagnostics.Process
$process.StartInfo = $processInfo
if (-not $process.Start()) { throw 'Could not start sdkmanager to install the Quest build packages.' }
$process.WaitForExit()
if ($process.ExitCode -ne 0) { throw "sdkmanager could not install the Quest build packages (exit code $($process.ExitCode))." }
Write-Host "Android SDK packages installed under $SdkRoot"
