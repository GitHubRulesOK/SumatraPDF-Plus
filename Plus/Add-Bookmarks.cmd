@Mode 65,17 & Color 9F & Title SumatraPDF Import Bookmarks [via cpdf] v'26-07-26--02
@echo off & SetLocal EnableDelayedExpansion & pushd %~dp0 & goto MAIN
Do not delete the above two lines since they are needed to prepare this script.

Updated from v'26-01-21--01 
- changed filenames to match sumatrapdf-tool run List-BM.js which uses export and import filename-BM.txt
- improved download link for cpdf.exe dependency

ToDo 
Add more description about how to use with set level before list ?

This file is based on placed in a Plus folder below where SumatraPDF-settings.txt is

for example
C:\Users\Your name\AppData\Local\SumatraPDF\SumatraPDF-settings.txt

C:\Users\Your name\AppData\Local\SumatraPDF\Plus\Add-Bookmarks.cmd

Only on first run it may need internet access to download most recent cpdf.exe

To RUN either drag and drop a PDF file on this CMD or in SumatraPDF Advanced options add it to 


ExternalViewers [
	[
		CommandLine = "C:\Users\ PUT your user name here \AppData\Local\SumatraPDF\plus\Add-Bookmarks.cmd" "%1" 
		Name = Import all &Bookmarks for this PDF as filename-BM.txt
		Filter = *.pdf
		Key = +
	]
]

:MAIN
if not exist "%~dpn1-BM.txt" goto help

set "cpdf=%~dp0cpdf\cpdf.exe"
if not exist "%cpdf%" goto :dependencies

rem import existing bookmarks from filename folder
"%cpdf%" -add-bookmarks "%~dpn1-BM.txt" "%~dpn1.pdf" -o "%~dpn1-BM.pdf"
rem dir /b "%~dpn1-BM.pdf" & pause
start SumatraPDF.exe -reuse-instance "%~dpn1-BM.pdf"
REM clean-up
:eof
exit /b

:dependencies
md cpdf
cd cpdf
curl -LO https://github.com/coherentgraphics/cpdf-binaries/raw/refs/heads/master/Windows-32bit/cpdf.exe
cd ..
pause &exit /b

:help
echo needs input filename.pdf that has an adjacent filename-BM.txt
pause
