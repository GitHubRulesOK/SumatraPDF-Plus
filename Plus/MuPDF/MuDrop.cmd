@echo off & Mode 55,10 & Color 9F & Title MuTool Drop wrapper v'26-02-24--04
REM this MuPDF MuTool Drop wrapper for ES5.js scripts requires MuTool 1.27 or newer. A 32 & 64 bit version is located  
REM currently at https://github.com/GitHubRulesOK/SumatraPDF-Plus/releases/download/x32Utilities/mutool.exe
(SETLOCAL ENABLEDELAYEDEXPANSION) && (SETLOCAL ENABLEEXTENSIONS) || Echo Unable to expand and extend && pause && exit /b
cd /d "%~dp0" & set "MuTool=" & set "Size=0"
:: User-editable location If you want a 64 bit ONLY MuTool rather than download a more universal 32 bit verion,
:: edit mutool.exe to your folder like set "MuTool=c:\program files\mupdf\mutool.exe" (keep outer quote marks).
set "MuTool=%~dp0mutool.exe"

:: OPTIONAL CHECK MuTool VERSION
if not exist "%MuTool%" echo MuTool.exe is missing. & CALL :FETCH
set "MuVer=1" & "%MuTool%" -v 2>ver.txt&for /f "tokens=3,4 delims=. " %%V in (ver.txt) do set "MuVer=%%V%%W"&del ver.txt
if %MuVer% LSS 127 echo Needs MuTool v 1.27 or newer. & CALL :FETCH

:: MAIN ENTRY We expect a filename.pdf AFTER any command args (they start with -)
REM for testing use set "DBG=ON" or include -d at start of this cmd e.g. MuDrop -d Hello.pdf
set "DBG=OFF"
if "%~1"=="-d" set "DBG=ON"
if "%DBG%"=="ON" Mode 120,10 & echo CMDLINE="%*"

:: VERIFY we have at least one valid filename the default means to exit is "Cancel" Button REPLY is "UserAbort" and should exit
set "INFILE=" & for %%A in (%*) do (set "ARG=%%~A" && if not "!ARG:~0,1!"=="-" set "INFILE=!ARG!")
if "%DBG%"=="ON" echo DBG INFILE = "!INFILE!"

:: YOU can add any CUSTOM arg handlers here like if %1=-foo then blah. Here we check 3x -T=Action -P=#[,...] optional 3rd -X=...EXTRA 
set "TASK=" & set "PAGES=" & set "EXTRA="
for /f "tokens=1-3 delims= " %%a in ("%*") do (if not "%%a"=="" call :ARGS "%%a" & if not "%%b"=="" call :ARGS "%%b" & if not "%%c"=="" call :ARGS "%%c")
:: the Reply if set will be !T!= !P!= and !X!=
set "task=!T!" & set "pages=!P!" & set "EXTRA=!X!"
if "%DBG%"=="ON" echo DBG After  TASK="!TASK!" PAGES="!PAGES!" EXTRA="!EXTRA!"

if exist "!INFILE!" goto :GOT_INFILE
:ASK_INFILE
if "%DBG%"=="ON" echo DBG MISSING INFILE calling ASKFILENAME & pause
set "REGEX=^[^<>|]+$" & call :BUILD_MSGBOX "Enter PDF filename:" "Input File" "Invalid filename characters."
call :ASKFILENAME & if "!REPLY!"=="UserAbort" (echo Aborted Asking for INPUT PDF & pause & goto :EOF)
echo "!REPLY!" & pause
set "INFILE=!REPLY!" & if not exist "!INFILE!" goto :ASK_INFILE
:GOT_INFILE

:: CORE FUNCTIONS do some TASK with "!INFILE!" we first check if -t=SomeAction was gived in command and on CANCEL WILL EXIT CMD
if "%DBG%"=="ON" echo DBG entered core with INFILE = "!INFILE!" TASK = "!TASK!" & pause
rem if NOT "!TASK!"=="" goto :GOT_TASK
if defined TASK goto :GOT_TASK
:: Preset some desired tasks `n sets a newline. Numbers are easier to list. This example uses 5 and "!REPLY!" can be any ONE word.
:: Summary the user prompt can be visually ordered any sequence and each newline starts with `n the choices work by numbers=1word "!REPLY!"
set "REGEX=^[1-5]$" & if "%DBG%"=="ON" echo DBG starting preset TASKS & pause
CALL :BUILD_MSGBOX "Select task:`n1 = List All Pages As Lines`n2 = List All Pages As Blocks`n3 = List by ask for Pages `n4 = Convert`n5 = Run" "Choose Task" "Enter 1-5 only"
call :ASKTASK & if "%DBG%"=="ON" echo DBG REPLY = "!REPLY!" TASK = "!TASK!" & pause
if "!REPLY!"=="UserAbort" goto :EOF
:GOT_TASK

:: LAST CHANCE - decide PAGES based on TASK
:: 1. SKIP - tasks that do NOT use pages at all, beware the names must match the tasks
for %%W in (ListAsBlocks ListAsLines) do (if "!TASK!"=="%%W" set "PAGES=" & goto GOT_PAGES)
:: 2. ALL - tasks that need SET pages
for %%W in (Info ) do (if "!TASK!"=="%%W" set "PAGES=1-N" goto GOT_PAGES)
:: 3. ALL - tasks that default to ALL pages
for %%W in (Export) do (if "!TASK!"=="%%W" set "PAGES=ALL" goto GOT_PAGES)
REM IF NOT !PAGES!="" goto GOT_PAGES
if defined PAGES goto GOT_PAGES
:GOT_TASK

:NEED_PAGES
:: Ask for PAGES range this was the original main function and on CANCEL WILL EXIT CMD
if NOT "!PAGES!"=="" goto :GOT_PAGES
rem set "REGEX=^(all|even|odd|end|[0-9]+|[0-9]+-[0-9]+)(,(all|even|odd|end|[0-9]+|[0-9]+-[0-9]+))*$"
set "REGEX=^(all|((even|odd|end|[0-9]+|[0-9]+-(?:[0-9]+|end|odd|even|all))(,(even|odd|end|[0-9]+|[0-9]+-(?:[0-9]+|end|odd|even|all)))*))$"
CALL :BUILD_MSGBOX "Enter PAGES range (e.g. 1,3-5,7):" "Page Range" "Invalid input. Use only digits, commas, and hyphens."
CALL :ASKPAGES
if "%DBG%"=="ON" echo DBG PAGES = "!PAGES!" & pause
if "!REPLY!"=="UserAbort" goto :EOF
:GOT_PAGES

REM echo !Task! & pause
:: We should now have filename task and pages(or range or not set)
CALL :TASK_!TASK!

:: CORE END We exit CMD here AFTER A TASK
pause
:EOF
set "Size=" & set "MuTool=" & set "LAST=" & set "CLEANED=" & set "FIRST=" & set "INFILE=" & set "REGEX=" & set "REPLY="
del "%temp%\msgbox.vbs" >nul & exit /b
exit /b

::TASKS these should be aligned with ASKTASK above and below so one per number

:TASK_Info
rem MuTool.exe  "!INFILE!" filename should be "quoted" info and !PAGES! should not be quoted
Mode 130,30 & Color 9F 
"%MuTool%" info "!INFILE!" !PAGES!
exit /b

:TASK_DelAnnots
set "OUTFILE=%INFILE:.pdf=-cleaned.pdf%"
"%MuTool%" run annots.js -m=delannots -p=!PAGES! "!INFILE!"
echo Removed annotations ? "!OUTFILE!"
exit /b

:TASK_ListAsBlocks
REM for as blocks use block mode (-b)
set "OUTFILE=%INFILE:.pdf=-List.txt%"
Mode 100,100 & Color 9F 
if "%DBG%"=="ON" echo calling "%MuTool%" run list-annots.js -b -r="!OUTFILE!" "!INFILE!"
"%MuTool%" run List-annots.js -b -r="!OUTFILE!" "!INFILE!"
echo Reported annotations ? as "!OUTFILE!"
exit /b

:TASK_ListAsLines
REM for as lines use verbose mode (-v)
set "OUTFILE=%INFILE:.pdf=-List.txt%"
Mode 150,30 & Color 9F 
if "%DBG%"=="ON" echo calling "%MuTool%" run list-annots.js -v -r="!OUTFILE!" "!INFILE!"
"%MuTool%" run List-annots.js -v -r="!OUTFILE!" "!INFILE!"
echo Reported annotations ? as "!OUTFILE!"
exit /b

:TASK_ListAsPages
set "PAGEARG=" & if /i not "!PAGES!"=="all" set "PAGEARG=-p=!PAGES!"
set "OUTFILE=%INFILE:.pdf=-List.txt%"
Mode 150,30 & Color 9F 
if "%DBG%"=="ON" echo calling "%MuTool%" run List-annots.js -v !PAGEARG! -r="!OUTFILE!" "!INFILE!" & pause
"%MuTool%" run List-annots.js -v !PAGEARG! -r="!OUTFILE!" "!INFILE!"
echo Reported annotations ? as "!OUTFILE!"
exit /b

::WRAPPER FUNCTIONS those not needed can be removed (starting with the last) beware any ASK... requires :BUILD_MSGBOX
:BUILD_MSGBOX
if "%DBG%"=="ON" echo REGEX  = "%REGEX%"
if "%DBG%"=="ON" echo PARAMS = %1 %2 %3
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

:ARGS
set "test=%~1" && for %%S in (t p x) do (if /i "!test:~1,1!"=="%%S" (set "%%S=!test:~3!"))
exit /b

:ASKTASK
set "TASKS=ListAsLines ListAsBlocks ListAsPages Export Info"
set "REPLY=" & set "TASK=" & for /f "delims=" %%A in ('cscript //nologo "%temp%\msgbox.vbs"') do set "REPLY=%%~A"
if "%DBG%"=="ON" echo DBG Task REPLY = "!REPLY!"
if "!REPLY!"=="UserAbort" exit /b
if "!REPLY!"=="" goto ASKTASK
for /f "tokens=%REPLY%" %%T in ("%TASKS%") do set "TASK=%%T"
if "%DBG%"=="ON" echo DBG Task TASK = "!TASK!"
if not defined TASK goto ASKTASK
exit /b

:ASKPAGES
set "REPLY=" & set "PAGES="
for /f "delims=" %%A in ('cscript //nologo "%temp%\msgbox.vbs"') do set "REPLY=%%~A"
if "!REPLY!"=="UserAbort" exit /b
if "%DBG%"=="ON" echo DBG PAGES REPLY = "!REPLY!"
set "PAGES=!REPLY!"
if "!PAGES!"=="" goto ASKPAGES
exit /b

:ASKFILENAME
set "REPLY=" & set "INFILE="
for /f "delims=" %%A in ('cscript //nologo "%temp%\msgbox.vbs"') do set "REPLY=%%~A"
if "!REPLY!"=="UserAbort" (echo Aborting & pause & exit /b)
if /i not "!REPLY:~-4!"==".pdf" set "REPLY=!REPLY!.pdf"
if "%DBG%"=="ON" echo DBG REPLY = "!REPLY!" may [not] be qualified filename. Rechecking & pause
if exist "!REPLY!" exit /b
goto ASKFILENAME

exit /b
:FETCH
set "MuTool="
CHOICE /C YN /N /M "Would you like to download MuTool 32 bit v1.27 portable copy... Press Y for Yes, N for No."
if "%DBG%"=="ON" echo %errorlevel%
if errorlevel 2 (echo Please edit this script to your location of MuTool.exe. & pause & exit)
if not errorlevel 1 exit
curl -LO https://github.com/GitHubRulesOK/SumatraPDF-Plus/releases/download/x32Utilities/mutool.exe
if exist mutool.exe (for %%F in ("mutool.exe") do set "Size=%%~zF")
if %size% LSS 44000000 (echo Unexpected size MuTool 1.27+ should be over 42 MBytes! &&DEL mutool.exe && goto EOF)
set "dllpath=%SystemRoot%\SysWOW64"
if not exist "%dllpath%\vcruntime140.dll" set "dllpath=%SystemRoot%\System32"
if not exist "%dllpath%\vcruntime140.dll" curl -LO https://raw.githubusercontent.com/GitHubRulesOK/SumatraPDF-Plus/master/Plus/MuPDF/32bitDependencies.zip
if exist 32bitDependencies.zip tar -xf 32bitDependencies.zip
set "MuTool=%~dp0mutool.exe"
exit /b
