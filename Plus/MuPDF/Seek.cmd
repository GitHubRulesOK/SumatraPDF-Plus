@echo off
goto MAIN

 VERSION 3 we use convert for non-PDF filetypes and Version 2 was changed to use | as seperator in wordlist.

 This is a template command file to use with 
 https://github.com/GitHubRulesOK/SumatraPDF-Plus/blob/master/Plus/MuPDF/SeekAndHL.js

 There are multiple options for the SeekAndHL.js such as auto add comments or page range but for this demo,
 below are the minimum and for convenience we will use -i along with !color! because both are unquoted.

 The Wordlist is a simple CSV file with as many lines and entries as you desire but for this demo is only 3 columns
 Use the "wordlist.csv" file with one line per cycle

 NOTE due to comma problems we now use | as seperator
 "Needle Phrase to find"|Hex colour as RRGGBBAA|Case sensitive true or false e.g.
 "Bingo"|FF800080|false
 "Bluey"|4080FF80|true
 "Aunty Brandy"|FF8000FF|false

 For demo see https://github.com/sumatrapdfreader/sumatrapdf/issues/5578#issuecomment-4313787248

 VERSION 3 includes a list of non PDF formats that can be easily converted, for %%x in (epub fb2 htm html mobi txt xhtml xps),
 however the PDF pages may not reflect the source page format so beware the page numbers may be not in sync. The txt report is
 thus just indicative of the number of matches (phrase count).

 MuPDF and thus SumatraPDF may render others but may need prior handling, For example FB2.zip (FBZ) would need to be unpacked
 (TAR -XF) to the simpler file.FB2. Also some others like DjVu need export pages as text (Right Click) to be re-converted to PDF.

:MAIN
setlocal enabledelayedexpansion
for /f "tokens=2 delims=:" %%A in ('chcp') do set "OLDCP=%%A"
chcp 65001 >nul
REM Start in the script directory
cd /d "%~dp0"

REM Path to SumatraPDF 3.7+
set "SumatraPDF=C:\Program Files\SumatraPDF\SumatraPDF.exe"
if not exist "%SumatraPDF%" echo SumatraPDF path is wrong & pause & exit /b
if "%~1"=="" echo Usage: Seek.cmd inputfile.ext & pause & exit /b
set "INPUT=%~f1"
if not exist "%INPUT%" echo Cannot find "%INPUT%"&pause&exit /b
set "WORK=%tmp%\work.pdf"
del /f /q "%WORK%" >nul 2>&1
set "EXT=%~x1"
REM --- If already PDF, skip conversion ---
if /i "%EXT%"==".pdf" (
    echo seeking text in %INPUT%
    copy /y "%INPUT%" "%WORK%" >nul
    goto skip
)
set "OK="
for %%x in (epub fb2 htm html mobi txt xhtml xps) do if /i "%EXT%"==".%%x" set "OK=1"
if not defined OK echo Unsupported file type: %EXT% so Cannot convert your file to PDF.&pause&exit /b
echo Converting "%~1" to PDF...
"%SumatraPDF%" convert -o "%WORK%" "%~f1"
if not exist "%WORK%" echo Cannot convert your file to PDF.&pause&exit /b

:skip
REM Prepare a "TOTAL" file
set "TOTAL=%tmp%\totals.txt"
> "%TOTAL%" echo Results for "%INPUT%":

REM use the "wordlist.csv" file with one line per cycle NOTE due to comma problems we use | as seperator
REM imortant we disable delayedexpansion at start of loop
setlocal disabledelayedexpansion
REM Make working copies for filtering so each run adds to the last
set "TEXT=%tmp%\work.txt"
for /f "usebackq tokens=1,2,3 delims=|" %%A in ("wordlist.csv") do (
    set "TERM=%%~A" & set "COLOR=%%~B" & set "CASE=%%~C"
REM Now safely re-enable delayed expansion
    setlocal EnableDelayedExpansion
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
REM Now safely endlocal for next pass
    endlocal
)
REM Now safely endlocal outside the loop
endlocal

REM we will for Concept not autosave the results but show in SumatraPDF for user to read or save as desired
echo.
echo Opening final highlighted PDF...
start="" "%SumatraPDF%"  -reuse-instance "%TOTAL%" "%WORK%"
echo.
echo Done. Review highlights and save temporary TXT AND / OR PDF files if desired.
chcp %OLDCP% >nul
pause
