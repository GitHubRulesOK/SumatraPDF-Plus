@echo off
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
REM to avoid mode affecting parent environment use >Start "" this\file
pushd "%~dp0" & Mode 52,13 & Color 9F & Title BentoPDF Fetcher version 2026-01-19
set "target=..\BentoPDF"
set "bat=%target%\Version.bat"
set "zipmask=dist-*.zip"

:: Check for required system tools
curl --version >nul 2>&1 || ( echo ERROR: curl is not available. Please ensure curl.exe is in PATH. && goto end )
tar --version >nul 2>&1 || ( echo ERROR: tar is not available. Please ensure tar.exe is in PATH. && goto end)

:: Set recent version from online (e.g. version 0.14.0)
for /f "tokens=2 delims=:" %%v in ('curl -s https://api.github.com/repos/alam00000/bentopdf/releases/latest ^| findstr "tag_name"' )do (
    set "latest=%%v"
    set "latest=!latest:~3,-2!"
)

:: Get installed version from batch file if exists
set "installed=BentoPDF is not yet installed"
if exist "%bat%" (
    for /f "tokens=2 delims= " %%a in ('"%bat%"') do (
        set "installed=%%a"
        set "installed=!installed!"
        goto :done1
    )
)
:done1

if /i "%~1"=="-f" goto Force
:: Default: compare versions and show help
echo Online version: %latest%
echo Installed:      %installed%
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
echo      -u  Update or [re]install latest version
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
set /p confirm="Download and [RE]install %latest%? (Y/N): "
if /i "%confirm%"=="Y" goto Force
echo Skipping update.
goto end

:Force
if /i "%installed%"=="BentoPDF is not yet installed" (
    md %target%
)
cd /d %target%

:: Download files
REM we have a dependency on any miniserver (we thus look for miniserve.exe) so first check
if not exist miniserve.exe (
curl -Lo miniserve.exe https://github.com/svenstaro/miniserve/releases/download/v0.32.0/miniserve-0.32.0-i686-pc-windows-msvc.exe
) else (
echo Did not find required miniserve.exe & pause & exit /b
)
:: Check server file size
for %%F in ("miniserve.exe") do set "size=%%~zF"
if %size% LSS 1979904 (echo Unexpected size miniserve version 0.32+ should be over 1.9 MBytes! && goto end)
REM supports -V version so perhaps use that too

set "zip=dist-%latest%.zip"
curl -Lo "!zip!" https://github.com/alam00000/BentoPDF/releases/download/v%latest%/dist-%latest%.zip
:: Check dist-file size
for %%F in ("!zip!") do set "size=%%~zF"
if %size% LSS 17000000 (echo Unexpected size recent versions since 1.14 should be over 170 MBytes! && goto end)

tar -xf "!zip!"
REM xcopy /E /H /K /Y dist-%latest% .
@echo @echo BentoPDF %latest% > version.bat
REM perhaps some more sanity test versions here
:: Optional: Checks

if not exist version.bat ( echo WARNING: version.bat not found. May not be available. ) & pause & exit /b
echo Update complete to version %latest%.
goto end

:Rollback
cd /d %target%
echo Available rollback versions:
set "first="
for %%f in (%zipmask%) do (
    echo   %%~nxf
    if "!first!" == "" set "first=%%~nxf"
)
:: Strip prefix and suffix
set "example=!first:dist-=!"
set "example=!example:.zip=!"
echo.
echo Enter Version number to rollback to from above
set /p choice="e.g.     !example! "
set "zip=dist-!choice!.zip"
if not exist "!zip!" (
    echo Version !choice! not found.
    goto end
)
echo unpacking  dist-!choice! from "!zip!"
tar -xf "!zip!"
echo Rolled back to version !choice!.
@echo @echo BentoPDF !choice! > version.bat

:end
echo.
echo Press any key to close..&TIMEOUT /T -1 >nul
exit
