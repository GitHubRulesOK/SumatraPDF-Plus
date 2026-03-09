@echo off
cd /d "%~dp0"
setlocal enabledelayedexpansion
REM ###
REM User-configurable tool location
REM ###
set "CPDF=%~dp0cpdf\cpdf.exe"
REM ###
REM Ensure cpdf.exe exists
REM ###
if not exist "!CPDF!" (
    echo Downloading latest cpdf ^(32-bit^)
    curl -Lo cpdf\master.zip https://github.com/coherentgraphics/cpdf-binaries/archive/master.zip
    echo Extracting cpdf.exe
    tar -O -xf cpdf\master.zip */Windows32bit/cpdf.exe > "!CPDF!"
    "!CPDF!" -version
)
if not exist "!CPDF!" ( echo Failed to obtain cpdf.exe & del cpdf\master.zip & goto :EOF )
REM ###
REM Input file handling
REM ###
set "EXT=%~x1"
if /I not "%EXT%"==".pdf" (
echo Drag and drop a PDF onto this script, or run:
echo %0 input.pdf
goto :EOF
)
set "IN=%~1"
if not exist "!IN!" (
echo File not found: "!IN!"
goto :EOF
)
"!CPDF!" -pages "!IN!">"%temp%\pagecount.txt" & set /p PAGECOUNT=<"%temp%\pagecount.txt"
REM ###
REM Ask for page range
REM ###
set "PAGES="
:NEED_PAGES
set "REGEX=^(all|reverse|odd|even|portrait|landscape|end|~[0-9]+|~(?:end|odd|even|all)|[0-9]+|[0-9]+[-~](?:[0-9]+|~[0-9]+|end|odd|even|all|~(?:end|odd|even|all)))(,(all|reverse|odd|even|portrait|landscape|end|~[0-9]+|~(?:end|odd|even|all)|[0-9]+|[0-9]+[-~](?:[0-9]+|~[0-9]+|end|odd|even|all|~(?:end|odd|even|all))))*$"

CALL :BUILD_MSGBOX "CPDF PAGE ranges (e.g. 1,3-5odd,end There are many others): current end = !PAGECOUNT!" "Page Range from %~nx1" "Invalid input. Use only digits, commas, hyphens, tilde, and keywords per the manual."
CALL :ASKPAGES
if "!REPLY!"=="UserAbort" goto :EOF
if "!PAGES!"=="" goto NEED_PAGES
REM if "!PAGES!"=="" ( echo No range entered. & goto :EOF )
echo Page range accepted: "!PAGES!"
REM ###
REM Build output filename
REM ###
set "OUT=%~dpn1-extraction.pdf"
REM ###
REM Perform extraction
REM ###
echo Extracting pages !PAGES!
"!CPDF!" "%IN%" !PAGES! -o "%OUT%"
if exist "%OUT%" (
    echo Created: "%OUT%"
) else (
    echo Extraction failed.
)
if exist "%~dp0..\SumatraPDF.exe" (
start "" "%~dp0..\SumatraPDF.exe" -reuse-instance "%OUT%"
)

:EOF
endlocal
pause
set "REGEX=" & set "REPLY="
if exist "%temp%\msgbox.vbs" del "%temp%\msgbox.vbs" >nul
exit /b

:BUILD_MSGBOX
> "%temp%\msgbox.vbs" (
  echo Dim i,r,invalid,ch,n:Set r=New RegExp:r.Pattern="%REGEX%":r.IgnoreCase=True
  echo Do
  echo   msg = Replace(%1,"`n",vbCrLf^):i = InputBox(msg,%2^)
  echo   If VarType(i^) ^<^> 8 Then WScript.Echo "UserAbort":WScript.Quit 0
  echo   If i ^<^> "" And r.Test(i^) Then Exit Do
  echo   MsgBox %3,48,"Error"
  echo Loop
  echo WScript.Echo Trim(i^)
)
exit /b
:ASKPAGES
set "REPLY=" & set "PAGES="
for /f "delims=" %%A in ('cscript //nologo "%temp%\msgbox.vbs"') do set "REPLY=%%~A"
if "!REPLY!"=="UserAbort" exit /b
set "PAGES=!REPLY!"
if "!PAGES!"=="" goto ASKPAGES
exit /b

