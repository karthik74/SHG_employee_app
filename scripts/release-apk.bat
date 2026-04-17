@echo off
REM Bump the build number in pubspec.yaml and build a release APK.
REM
REM Usage:
REM   scripts\release-apk.bat          - bump +N by 1 and build APK
REM   scripts\release-apk.bat aab      - build AAB (bundle) instead
REM
setlocal enabledelayedexpansion

pushd "%~dp0\.."

set "mode=%1"
if "%mode%"=="" set "mode=build"

for /f "tokens=2" %%A in ('findstr /b /c:"version:" pubspec.yaml') do set "current=%%A"
if not defined current (
  echo ERROR: could not find version line in pubspec.yaml
  popd
  exit /b 1
)

for /f "tokens=1,2 delims=+" %%A in ("%current%") do (
  set "name=%%A"
  set "code=%%B"
)

set /a code+=1
set "new_version=%name%+%code%"

powershell -NoProfile -Command "(Get-Content 'pubspec.yaml') -replace '^version:\s.*','version: %new_version%' | Set-Content 'pubspec.yaml'"

echo Version: %current% -^> %new_version%
echo.

call flutter clean
if "%mode%"=="aab" (
  call flutter build appbundle --release
  set "out=build\app\outputs\bundle\release\app-release.aab"
) else (
  call flutter build apk --release
  set "out=build\app\outputs\flutter-apk\app-release.apk"
)

echo.
echo Built: %out%
echo Version: %new_version%

popd
endlocal
