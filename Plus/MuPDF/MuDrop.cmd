@echo off
REM this MuPDF MuTool Drop wrapper for ES5.js scripts requires MuTool 1.27 or newer. A 32 bit version is located  
REM currently at https://github.com/GitHubRulesOK/SumatraPDF-Plus/releases/download/x32Utilities/mutool.exe
(SETLOCAL ENABLEDELAYEDEXPANSION) && (SETLOCAL ENABLEEXTENSIONS) || Echo Unable to expand and extend && pause && exit /b
cd /d "%~dp0" & set "mutool=" & set "Size=0"
:: User-editable location If you want to use 64 bit mutool rather than download a more universal 32 bit verion,
:: edit mutool.exe to your folder like set "mutool=c:\program files\mupdf\mutool.exe" (keep outer quote marks).
set "mutool=%~dp0mutool.exe"

:: CHECK MuTool VERSION
if not exist "%mutool%" echo Mutool.exe is missing. & CALL :FETCH
set "MuVer=1" & "%mutool%" -v 2>ver.txt&for /f "tokens=3,4 delims=. " %%V in (ver.txt) do set "MuVer=%%V%%W"&del ver.txt
if %MuVer% LSS 127 echo needs MuTool v 1.27 or newer. & CALL :FETCH

:: MAIN ENTRY We expect a filename.pdf AFTER any command args (they start with -)
REM for testing use set "DEBUG=ON"
set "DEBUG=off"
if "%DEBUG%"=="ON" echo DEBUG INFILE = "%~1" & pause
for %%L in (%*) do (
set "LAST=%%L"
set "CLEANED=!LAST:"=!"
set "FIRST=!CLEANED:~0,1!"
if "!FIRST!"=="-" (set "INFILE=") else (set "INFILE=!CLEANED!")
)
if "%DEBUG%"=="ON" echo DEBUG INFILE = "!INFILE!" and CLEANED = "!CLEANED!" & pause
If not exist "%INFILE%" (
set "REGEX=^[^<>|]+$" && CALL :BUILD_MSGBOX "Enter PDF filename:" "Input File" "Invalid filename characters."
CALL :ASKFILENAME
if "!REPLY!"=="UserAbort" (echo Aborted AskFilename & pause & goto :EOF)
if "%DEBUG%"=="ON" echo INFILE = "!REPLY!"
)
if "%DEBUG%"=="ON" echo DEBUG INFILE = "!INFILE!" & pause

:: CORE FUNCTION do something with "!INFILE!"
REM this section starts with an IF ... ( and ends with ) so beware if you remove one remove the other
If exist "!INFILE!" (

:: Ask for page range this the main function and on CANCEL WILL EXIT CMD
set "REGEX=^(all|end|even|odd|[0-9,\- ]+)$"
CALL :BUILD_MSGBOX "Enter page range (e.g. 1,3-5,7):" "Page Range" "Invalid input. Use only digits, commas, and hyphens."
CALL :ASKPAGERANGE
if "!REPLY!"=="UserAbort" goto :EOF

if "%DEBUG%"=="ON" echo DEBUG PAGERANGE = "!PAGERANGE!" & pause

"%mutool%" info "!INFILE!" "!PAGERANGE!"

:: CORE END
)

:: We exit CMD here
pause
:EOF
set "Size=" & set "mutool=" & set "LAST=" & set "CLEANED=" & set "FIRST=" & set "INFILE=" & set "REGEX=" & set "REPLY="
del "%temp%\msgbox.vbs" >nul & exit /b
exit /b

::WRAPPER FUNCTIONS those not needed can be removed (starting with the last) beware any ASK... requires :BUILD_MSGBOX

:BUILD_MSGBOX
> "%temp%\msgbox.vbs" (
echo Dim i,r,invalid,ch,n:Set r=New RegExp:r.Pattern="%REGEX%":r.IgnoreCase=True
echo Do
echo i=InputBox(%1,%2^)
echo If VarType(i^) ^<^> 8 Then WScript.Echo "UserAbort":WScript.Quit 0
echo If i="" Then WScript.Echo "UserAbort":WScript.Quit 0
echo If r.Test(i^) Then Exit Do
echo invalid="":For n=1 To Len(i^):ch=Mid(i,n,1^)
echo If Not r.Test(ch^) Then invalid=invalid ^& ch
echo Next:MsgBox "Invalid characters: '" ^& invalid ^& "'." ^& vbCrLf ^& %3,48,"Error"
echo Loop
echo WScript.Echo Trim(i^)
)
exit /b

:ASKPAGERANGE
set "REPLY="
for /f "delims=" %%A in ('cscript //nologo "%temp%\msgbox.vbs"') do set "REPLY=%%~A"
if "!REPLY!"=="UserAbort" exit /b
if "%DEBUG%"=="ON" echo DEBUG PageRange REPLY = "!REPLY!"
:: VBS has already validated the input
set "PAGERANGE=!REPLY!"
exit /b

:ASKFILENAME
set "REPLY="
REM & for /f "delims=" %%A in ('cscript //nologo "%temp%\msgbox.vbs"') do set "REPLY=%%A"
for /f "delims=" %%A in ('cscript //nologo "%temp%\msgbox.vbs"') do set REPLY=%%~A
if "!REPLY!"=="UserAbort" (echo Aborted & pause & goto EOF)
if "%DEBUG%"=="ON" echo DEBUG REPLY = "!REPLY!" should be valid NOW TEST .pdf
set "INFILE=!REPLY!"
echo "!INFILE!" | find "." >nul
if errorlevel 1 set "INFILE=!INFILE!.pdf"
if not exist "!INFILE!" goto ASKFILENAME
exit /b

:FETCH
CHOICE /C YN /N /M "Would you like to download MuTool 32 bit v1.27 portable copy... Press Y for Yes, N for No."
set "mutool="
if errorlevel 2 (echo Please edit this script to your location of MuTool.exe. & pause )
if not errorlevel 1 exit
curl -LO https://github.com/GitHubRulesOK/SumatraPDF-Plus/releases/download/x32Utilities/mutool.exe
if exist mutool.exe (for %%F in ("mutool.exe") do set "Size=%%~zF")
if %size% LSS 44000000 (echo Unexpected size Mutool 1.27+ should be over 42 MBytes! &&DEL mutool.exe && goto EOF)
set "mutool=%~dp0mutool.exe"
exit /b
