@echo off
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
REM to avoid mode affecting parent environment use >Start "" this\file
pushd "%~dp0" & Mode 52,13 & Color 9F & Title CHShell Fetcher
set "target=..\CHShell"
set "exe=%target%\chrome-headless-shell.exe"
set "zipmask=chrome-headless-shell-win32-*.zip"

:: Check for required system tools
curl --version >nul 2>&1 || ( echo ERROR: curl is not available. Please ensure curl.exe is in PATH. && goto end )
tar --version >nul 2>&1 || ( echo ERROR: tar is not available. Please ensure tar.exe is in PATH. && goto end)

:: Get latest version online -o "%temp%\LATEST_RELEASE_STABLE.txt"
del "%temp%\LATEST_RELEASE_STABLE.txt" 2>nul
curl -s -o "%temp%\LATEST_RELEASE_STABLE.txt" https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_STABLE
:: Check file is small and starts with a 3-digit version
for %%F in ("%temp%\LATEST_RELEASE_STABLE.txt") do set "size=%%~zF"
if %size% GTR 19 echo Unexpected Version Data (Should be under 20 bytes) & goto end
findstr /r "^[0-9][0-9][0-9]\.[0-9]" "%temp%\LATEST_RELEASE_STABLE.txt" >nul
if errorlevel 1 echo Unexpected Version Data (Not starting ###.#...) & goto end
set /p latest=<"%temp%\LATEST_RELEASE_STABLE.txt"

:: Get installed version from binary if exists
set "installed=Chrome-Headless is not yet installed"
if exist "%exe%" (
 for /f "tokens=*" %%a in ('"%exe%" --version') do set "installed=%%a"
)
if /i "%~1"=="-f" goto Force
:: Default: compare versions and show help
echo Online version:                      %latest%
echo Installed: %installed%
echo.
:: Runtime switch handling no need to show usage
if /i "%~1"=="-u" goto Update
if /i "%~1"=="-r" goto Rollback
echo Usage: %~nx0 [Option]
echo.
echo Options
echo -------
echo default  Show versions and update option
echo      -f  Force install or update/overwrite
echo      -r  Rollback to previous version
echo      -u  Update or install latest version
echo.

:Update
if /i "%~1"=="-u" (
 if not "%installed%"=="%latest%" (
  goto Force
 ) else (
  echo Installed version is already up to date.
  echo Use -f to force reinstall.
  goto end
 )
)
set /p confirm="Download and install %latest%? (Y/N): "
if /i "%confirm%"=="Y" goto Force
echo Skipping update.
goto end

:Force
if /i "%installed%"=="Chrome-Headless is not yet installed" (
    md %target%
)
cd /d %target%

:: Download files
curl -L -o websocat.exe https://github.com/vi/websocat/releases/download/v1.14.0/websocat.i686-pc-windows-gnu.exe
set "zip=chrome-headless-shell-win32-%latest%.zip"
curl -o "!zip!" https://storage.googleapis.com/chrome-for-testing-public/%latest%/win32/chrome-headless-shell-win32.zip
tar -xf "!zip!"
xcopy /E /H /K /Y chrome-headless-shell-win32 .

REM perhaps some more sanity tests here
:: Optional: Check for websocat is included
if not exist websocat.exe ( echo WARNING: websocat.exe not found. Extra interop features may not be available. )
if not exist resources\accessibility\reading_mode_gdocs_helper\gdocs_script.js echo problem unpacking
rd /s /q chrome-headless-shell-win32
if exist chrome-headless-shell-win32\*.* echo error cleaning source extraction
echo Update complete to version %latest%.
goto end

:Rollback
cd /d %target%
echo Available rollback versions:
for %%f in (%zipmask%) do (
    echo   %%~nxf
    set "last=%%~nxf"
)
for %%a in ("!last:chrome-headless-shell-win32-=!") do (
    set "example=%%~na"
)
echo.
echo Enter Version number to rollback to from above
set /p choice="e.g.   !example!     "
set "zip=chrome-headless-shell-win32-!choice!.zip"
if not exist "!zip!" (
    echo Version !choice! not found.
    goto end
)
tar -xf "!zip!"
xcopy /E /H /K /Y chrome-headless-shell-win32 .
rd /s /q chrome-headless-shell-win32
echo Rolled back to version !choice!.

:end
echo.
echo Press any key to close..&TIMEOUT /T -1>nul
exit
