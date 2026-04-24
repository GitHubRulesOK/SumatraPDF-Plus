@echo off

REM This is a template command file to use with 
REM https://github.com/GitHubRulesOK/SumatraPDF-Plus/blob/master/Plus/MuPDF/SeekAndHL.js
REM There are multiple options for the SeekAndHL.js such as auto add comments or page range but for this demo,
REM below are the minimum and for convenience we will use -i along with !color! because both are unquoted.
REM the Wordlist is a simple CSV file with as many lines and entries as you desire but for this demo is only 3 columns
REM "Needle Phrase to find",Hex colour as RRGGBBAA,Case sensitive true or false e.g.
REM "Bingo",FF800080,false
REM "Bluey",4080FF80,true
REM "Aunty Brandy",FF8000FF,false

setlocal enabledelayedexpansion
for /f "tokens=2 delims=:" %%A in ('chcp') do set "OLDCP=%%A"
chcp 65001 >nul
REM Start in the script directory
cd /d "%~dp0"

REM Path to SumatraPDF 3.7+
set "SumatraPDF=C:\Program Files\SumatraPDF\SumatraPDF.exe"
if not exist "%SumatraPDF%" echo SumatraPDF path is wrong & pause & exit /b
if "%~1"=="" echo Usage: Seek.cmd input.pdf & pause & exit /b
set "INPUT=%~1"

REM Prepare a "TOTAL" file
set "TOTAL=%tmp%\totals.txt"
> "%TOTAL%" echo Results for "%INPUT%":

REM Make working copies for filtering so each run adds to the last
set "WORK=%tmp%\work.pdf"
set "TEXT=%tmp%\work.txt"
copy /y "%INPUT%" "%WORK%" >nul

REM use the "wordlist.csv" file with one line per cycle
for /f "usebackq tokens=1,2,3 delims=," %%A in ("wordlist.csv") do (
    set "TERM=%%~A" & set "COLOR=%%~B" & set "CASE=%%~C"
    echo Highlighting: !TERM!  Color: !COLOR!  CaseSensitive: !CASE!
    echo( >> "%TOTAL%" & echo Term: !TERM! >> "%TOTAL%"
    set "OPTIONS=-c=!COLOR!"
    if /i "!CASE!"=="false" set "OPTIONS=-c=!COLOR! -i"

    "%SumatraPDF%" run "%~dp0SeekAndHL.js" !OPTIONS!  -r="%TEXT%" -s="!TERM!" -t "%WORK%"

REM Filter only positive hits
    findstr /r /c:"Page [0-9][0-9]*: [1-9][0-9]* matches" "%TEXT%" >> "%TOTAL%"
    REM Replace "%WORK%" with the newly highlighted "%tmp%\work-hl.pdf"
    if exist "%tmp%\work-hl.pdf" copy /y "%tmp%\work-hl.pdf" "%WORK%" >nul
    del "%TEXT%" "%tmp%\work-hl.pdf" >nul
)
REM we will for Concept not autosave the results but show in SumatraPDF for user to read or save as desired
echo.
echo Opening final highlighted PDF...
start="" "%SumatraPDF%"  -new-window "%TOTAL%" "%WORK%"
echo.
echo Done. Review highlights and save temporary TXT AND / OR PDF files if desired.
chcp %OLDCP% >nul
pause

