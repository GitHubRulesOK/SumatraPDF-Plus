@Mode 60,17 & Color 9F & Title SumatraPDF addin Export Bookmarks [via cpdf] v'24-12-04--03
@echo off & SetLocal EnableDelayedExpansion & pushd %~dp0 & goto MAIN
Do not delete the above two lines since they are needed to prepare this script.

ToDo 
Add more description about how to use ?

This file is based on placed in a Plus folder where SumatraPDF-settings.txt is

for example
C:\Users\Your name\AppData\Local\SumatraPDF\SumatraPDF-settings.txt

C:\Users\Your name\AppData\Local\SumatraPDF\Plus\List-Bookmarks.cmd

Only on first run it needs internet access to download recent cpdf.exe

To RUN either drag and drop a PDF file on this CMD or in SumatraPDF Advanced options add it to 


ExternalViewers [
	[
		CommandLine = "C:\Users\ PUT your user name here \AppData\Local\SumatraPDF\plus\List-Bookmarks.cmd" "%1" 
		Name = Export all &Bookmarks for this PDF as filename.bkm
		Filter = *.pdf
		Key = B
	]
]

:MAIN
if not exist "%~dpn1.pdf" goto help

set "cpdf=%~dp0cpdf\cpdf.exe"
if not exist "%cpdf%" goto :dependencies

rem export existing bookmarks to filename folder
"%cpdf%" -list-bookmarks -utf8 "%~dpn1.pdf" 2>nul 1>"%~dpn1-pdf.bkm"

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
