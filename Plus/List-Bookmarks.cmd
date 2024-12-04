@Mode 60,17 & Color 9F & Title SumatraPDF addin Export Bookmarks [via cpdf] v'24-12-04--01
@echo off & SetLocal EnableDelayedExpansion & pushd %~dp0 & goto MAIN
Do not delete the above two lines since they are needed to prepare this script.

ToDo 
Add more description about how to use ?

This file is based on placed in a Plus folder where SumatraPDF-settings.txt is
for example
C:\Users\Your name\AppData\Local\SumatraPDF\SumatraPDF-settings.txt

C:\Users\Your name\AppData\Local\SumatraPDF\Plus\AddBookmark.cmd

Only on first run it needs internet access to download recent cpdf.exe

:MAIN
if not exist "%~dpn1.pdf" goto help

set "cpdf=%~dp0cpdf\cpdf.exe"
if not exist "%cpdf%" goto :dependencies

rem export existing bookmarks to filename folder
"%cpdf%" -list-bookmarks -utf8 "%~dpn1.pdf" 2>nul 1>"%~dpn1-pdf.bmk"

REM clean-up
:eof
exit /b

:dependencies
md cpdf
cd cpdf
curl -O https://raw.githubusercontent.com/coherentgraphics/cpdf-binaries/master/Windows32bit/cpdf.exe
cd ..
pause &exit /b

:help
echo needs input filename.pdf 
pause
