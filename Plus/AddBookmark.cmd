@Mode 65,17 & Color 9F & Title SumatraPDF addin Add Bookmark [via cpdf]  v'26-07-26--02
@echo off & SetLocal EnableDelayedExpansion & pushd %~dp0 & goto MAIN
Do not delete the above two lines since they are needed to prepare this script.

Updated from v'26-01-21--01 
- now requires a page number be given on the command line or in SumatraPDF as %p
- improved export & import logic
- improved download link for cpdf.exe dependency

ToDo 
Add more description about how to use with set level before list ?

This file is based on placed in a Plus folder below where SumatraPDF-settings.txt is

for example
C:\Users\Your name\AppData\Local\SumatraPDF\SumatraPDF-settings.txt

C:\Users\Your name\AppData\Local\SumatraPDF\Plus\Add-Bookmarks.cmd

Only on first run it may need internet access to download most recent cpdf.exe

To RUN  in SumatraPDF Advanced options add it to ExternalViewers 

ExternalViewers [
	[
		CommandLine = "C:\Users\ PUT your user name here \AppData\Local\SumatraPDF\plus\Add-Bookmarks.cmd" "%1" %p
		Name = Add (&+) a Bookmarks for this PDF page
		Filter = *.pdf
		Key = +
	]
]

:: =====
:MAIN
:: =====
set /a "test=0+%2"
if "!test!" == "" goto help
if not exist "%~dpn1.pdf" goto help
set "cpdf=%~dp0cpdf\cpdf.exe"
if not exist "%cpdf%" goto dependencies
:: clean-up
del /q "%temp%\bookmark-list.txt" 2>nul
del /q "%temp%\prefixed.txt" 2>nul
del /q "%temp%\sorted.txt" 2>nul
:: export existing bookmarks
"%cpdf%" -list-bookmarks -utf8 "%~dpn1.pdf" > "%temp%\bookmark-list.txt"
:: switch to UTF‑8
for /f "tokens=2 delims=:" %%G in ('chcp') do set "_codepage=%%G"
chcp 65001 > nul
:: ==========
::  ADD Entry
:: ==========
echo Adding Bookmark Entry for page !test!
echo For Top most level use =0
set /p "BkLvl=Level ?="
echo Bookmark Text to add
set /p "BkTxt=Text ?="
set "BkAct=XYZ 0 0 null"
:: append new bookmark
echo %BkLvl% "%BkTxt%" %2 "[%2/%BkAct%]" >> "%temp%\bookmark-list.txt"
:: =====
::  SORT
:: =====
for /f "usebackq delims=" %%L in ("%temp%\bookmark-list.txt") do (
  set "line=%%L"
  for /f "tokens=1 delims=[" %%A in ("%%L") do set "left=%%A"
  set "left=!left:~0,-1!"
  set "left=!left:open=!"
  set page="
  for %%W in (!left!) do set "page=000000%%W"
  set "page=!page:~-6!"
  echo !page!  %%L >> "%temp%\sortme.txt"
)
sort "%temp%\sortme.txt" /O "%temp%\sorted.txt"
del /q "%temp%\bookmark-list.txt" & if exist "%temp%\bookmark-list.txt" echo cannot delete  "temp\bookmark-list.txt" & pause & exit /b
del /q "%temp%\sortme.txt" >nul & if exist "%temp%\sortme.txt" echo cannot delete "temp\sortme.txt" & pause & exit /b
for /f "usebackq tokens=1,* delims= " %%A in ("%temp%\sorted.txt") do (echo %%B) >> "%temp%\bookmark-list.txt"
if not exist "%temp%\bookmark-list.txt" echo cannot find sorted "temp\bookmark-list.txt" & pause & exit /b
copy "%~dpn1.pdf" "%~dpn1-bak.pdf" >nul

:: ===
:import
:: ===
"%cpdf%" -add-bookmarks "%temp%\bookmark-list.txt" "%~dpn1-bak.pdf" -o "%~dpn1.pdf"
if errorlevel 1 goto error

:: ===
:cleanup
:: ===
chcp %_codepage% >nul
del /q "%temp%\bookmark-list.txt"
pause
exit /b

:: ===
:dependencies
:: ===
md cpdf
cd cpdf
curl -LO https://github.com/coherentgraphics/cpdf-binaries/raw/refs/heads/master/Windows-32bit/cpdf.exe
cd ..
pause
exit /b

:: ===
:error
:: ===
echo.
echo CPDF reported a problem possibly with the bookmark order.
echo The bookmark file may be manualy edited in Notepad.
echo.
choice /c EA /m "Press E to Edit in NotePad or A to Abort this run"
if errorlevel 2 goto cleanup
if errorlevel 1 %SystemRoot%\notepad.exe "%temp%\bookmark-list.txt"
echo.
echo Re-parsing corrected bookmark file...
echo.
goto import
exit /b

:: ===
:help
:: ===
echo needs input filename.pdf # (# = page your input page # = !test!)
pause
