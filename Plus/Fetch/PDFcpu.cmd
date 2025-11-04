@echo off
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
REM to avoid mode affecting parent environment use >Start "" this\file
pushd "%~dp0" & Mode 52,13 & Color 9F & Title PDFcpu Fetcher version 2025-11-04
set "target=..\pdfcpu"
set "exe=%target%\pdfcpu.exe"
set "zipmask=pdfcpu_*.zip"

:: Check for required system tools
curl --version >nul 2>&1 || ( echo ERROR: curl is not available. Please ensure curl.exe is in PATH. && goto end )
tar --version >nul 2>&1 || ( echo ERROR: tar is not available. Please ensure tar.exe is in PATH. && goto end)

:: Set recent version from online (e.g. version 0.11.1)
for /f "tokens=2 delims=:" %%v in ('curl -s https://api.github.com/repos/pdfcpu/pdfcpu/releases/latest ^| findstr "tag_name"') do (
    set "latest=%%v"
    set "latest=!latest:~3,-2!"
)

:: Get installed version from binary if exists
set "installed=PDFCPU is not yet installed"
if exist "%exe%" (
    for /f "tokens=2 delims= " %%a in ('"%exe%" version') do (
        set "installed=%%a"
        set "installed=!installed:~1!"
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
if /i "%installed%"=="PDFCPU is not yet installed" (
    md %target%
)
cd /d %target%

:: Download files
set "zip=pdfcpu_%latest%_Windows_i386.zip"
curl -Lo "!zip!" https://github.com/pdfcpu/pdfcpu/releases/download/v%latest%/pdfcpu_%latest%_Windows_i386.zip

:: Check file size
for %%F in ("!zip!") do set "size=%%~zF"
if %size% LSS 8435000 (echo Unexpected size Should be over 8 MBytes && goto end)

tar -xf "!zip!"
pause
xcopy /E /H /K /Y pdfcpu_%latest%_Windows_i386 .

REM perhaps some more sanity test versions here
:: Optional: Checks
if not exist pdfcpu.exe ( echo WARNING: pdfcpu.exe not found. May not be available. )
rd /s /q pdfcpu_%latest%_Windows_i386
if exist pdfcpu_%latest%_Windows_i386\*.* echo error cleaning source extraction
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
set "example=!first:pdfcpu_=!"
set "example=!example:.zip=!"
echo.
echo Enter Version number to rollback to from above
set /p choice="e.g.     !example! "
set "zip=pdfcpu_!choice!.zip"
if not exist "!zip!" (
    echo Version !choice! not found.
    goto end
)
tar -xf "!zip!"
xcopy /E /H /K /Y pdfcpu_%latest%_Windows_i386 .
rd /s /q pdfcpu_%latest%_Windows_i386
echo Rolled back to version !choice!.

:end
echo.
echo Press any key to close..&TIMEOUT /T -1 >nul
exit
