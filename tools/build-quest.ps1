param(
    [ValidateSet('Debug', 'Release')]
    [string]$Variant = 'Debug',
    [string]$SdkRoot = $env:ANDROID_SDK_ROOT
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not $SdkRoot) {
    $SdkRoot = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
}
if (-not (Test-Path (Join-Path $SdkRoot 'platforms\android-35\android.jar'))) {
    throw "Android SDK 35 is missing at '$SdkRoot'. Install SDK platform 35, NDK 27.2.12479018, and CMake 3.30.3."
}
if (-not (Test-Path (Join-Path $SdkRoot 'ndk\27.2.12479018\source.properties'))) {
    throw "Android NDK 27.2.12479018 is missing from '$SdkRoot'."
}
if (-not (Test-Path (Join-Path $SdkRoot 'cmake\3.30.3\bin\cmake.exe'))) {
    throw "Android CMake 3.30.3 is missing from '$SdkRoot'."
}
$jdk = $env:JAVA_HOME
if (-not $jdk -or -not (Test-Path (Join-Path $jdk 'bin\java.exe'))) {
    $jdk = Get-ChildItem (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft') -Directory -Filter 'jdk-17*' -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty FullName
}
if (-not $jdk -or -not (Test-Path (Join-Path $jdk 'bin\java.exe'))) {
    throw 'Java 17 is required. Install a JDK 17 and set JAVA_HOME before building.'
}
$env:JAVA_HOME = $jdk
$env:PATH = (Join-Path $jdk 'bin') + ';' + $env:PATH
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Git is required to fetch the pinned SDL2 Android Java sources.'
}

$env:ANDROID_HOME = $SdkRoot
$env:ANDROID_SDK_ROOT = $SdkRoot
$sdlRoot = Join-Path $repo 'build\quest\SDL'
if (-not (Test-Path (Join-Path $sdlRoot 'android-project\app\src\main\java\org\libsdl\app\SDLActivity.java'))) {
    New-Item -ItemType Directory -Force -Path (Split-Path $sdlRoot) | Out-Null
    & git clone --depth 1 --branch release-2.32.10 https://github.com/libsdl-org/SDL.git $sdlRoot
    if ($LASTEXITCODE -ne 0) { throw 'Could not fetch the pinned SDL2 Android project sources.' }
}

$sdlApp = Join-Path $sdlRoot 'android-project\app\src\main'
$generated = Join-Path $repo 'android\app\build\generated\sdl'
$javaDestination = Join-Path $generated 'java\org\libsdl\app'
$resDestination = Join-Path $generated 'res'
New-Item -ItemType Directory -Force -Path $javaDestination, $resDestination | Out-Null
Copy-Item (Join-Path $sdlApp 'java\org\libsdl\app\*') $javaDestination -Recurse -Force
Copy-Item (Join-Path $sdlApp 'res\*') $resDestination -Recurse -Force

$gradleVersion = '8.9'
$gradleRoot = Join-Path $repo "build\tools\gradle-$gradleVersion"
$gradle = Join-Path $gradleRoot "gradle-$gradleVersion\bin\gradle.bat"
if (-not (Test-Path $gradle)) {
    $toolsRoot = Join-Path $repo 'build\tools'
    $zip = Join-Path $toolsRoot "gradle-$gradleVersion-bin.zip"
    New-Item -ItemType Directory -Force -Path $toolsRoot | Out-Null
    Invoke-WebRequest "https://services.gradle.org/distributions/gradle-$gradleVersion-bin.zip" -OutFile $zip
    Expand-Archive -Path $zip -DestinationPath $gradleRoot -Force
}

Push-Location (Join-Path $repo 'android')
try {
    & $gradle --no-daemon ":app:assemble$Variant"
    if ($LASTEXITCODE -ne 0) { throw 'Gradle failed to configure, compile, or package the Quest APK.' }
} finally {
    Pop-Location
}

$apk = Join-Path $repo "android\app\build\outputs\apk\$($Variant.ToLowerInvariant())\app-$($Variant.ToLowerInvariant()).apk"
if (-not (Test-Path $apk)) { throw "Gradle completed without producing the expected APK: $apk" }
Write-Host "Quest APK: $apk"
