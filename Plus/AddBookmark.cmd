@Mode 60,17 & Color 9F & Title SumatraPDF addin Add Bookmark [via cpdf] v'24-11-04--01
@echo off & SetLocal EnableDelayedExpansion & pushd %~dp0 & goto MAIN
Do not delete the above two lines since they are needed to prepare this script.

ToDo 
Add more description about how to use ?


:MAIN
set /a "test=0+%2"
if "!test!" == "" goto help
if not exist "%~dpn1.pdf" goto help

set "cpdf=%~dp0cpdf\cpdf.exe"
if not exist "%cpdf%" goto :dependencies

rem clean-up any failed run
if exist "%temp%\bookmarks-out.txt" del /q "%temp%\bookmarks-out.txt"

rem export existing bookmarks to append to (is this needed apart from ensure -utf8 -out?)
"%cpdf%" -list-bookmarks -utf8 "%~dpn1.pdf" 2>nul 1>"%temp%\bookmarks-out.txt"

REM important to allow for UTF input we switch cp to 65001
For /f "tokens=2 delims=:" %%G in ('chcp') Do set _codepage=%%G
chcp 65001 > nul

REM page is a given as %2
REM echo Target Top of
REM set /p "BkPge=Page ?"

echo Top Level=0
set /p "BkLvl=Level ?"
echo description
rem e.g. 可以添加或编辑书签吗
set /p "BkTxt=Text ?"
set "BkAct=FitH 842"

echo %BkLvl% "%BkTxt%" %2 "[%2 /%BkAct%]">>"%temp%\bookmarks-out.txt"


REM Combine
copy "%~dpn1.pdf" "%~dpn1-bak.pdf" >nul
"%cpdf%" -add-bookmarks "%temp%\bookmarks-out.txt" "%~dpn1-bak.pdf" -o "%~dpn1.pdf"

:eof
REM clean-up
chcp %_codepage% >nul
del /q "%temp%\bookmarks-out.txt"
exit /b

:dependencies
md cpdf
cd cpdf
curl -O https://raw.githubusercontent.com/coherentgraphics/cpdf-binaries/master/Windows32bit/cpdf.exe
cd ..
pause &exit /b

:help
echo needs input filename.pdf # (# = page you gave page # = !test!)
pause
