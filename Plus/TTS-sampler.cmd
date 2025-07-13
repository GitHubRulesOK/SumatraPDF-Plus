@echo off&Mode 35,3&Color 3F&Title TTS-sampler v2025-13-07-02
REM see IMPORTANT  notes below
goto MAIN

This is not intended as a fully working application but a SAMPLE
of what is possible by using a multi-format file to text conversion.

Balabolka text extraction can work with many SumatraPDF file formats such as
 
AZW, AZW3, CHM, DjVu, EPUB, FB2, FB3, HTML, MD, MHT, MOBI, PDF, PRC,
TCR, TXT (aswell as others see https://www.cross-plus-a.com/btext.htm)
The IFilter interface may be used for files with unknown extensions.

For OCR of images a tesseract engine would be required and filetyes filtered.

This file will download on 1st run the latest dependencies if not present.

Can be run standalone or via ExternalViewers in SumatraPDF-settings.txt. For example

ExternalViewers [
	[
		CommandLine = "C:\Users\K\AppData\Local\SumatraPDF\plus\TTS-sampler.cmd" "%1" page=1-N
		Name = Send file &To TTS sampler
		Filter = *.*
		Key = T
	]
]

:MAIN
REM set your choice of X2T and TTS.exe here and edit options in later lines
REM IMPORTANT change the following lines for your own instalation

REM IMPORTANT if you see the Balabolka message Error: OLE error 8004503A
REM it usually means a voice was not found or assigned ! default here is -n Zira

set "plus=%~dp0"

set "X2T=%plus%blb2txt\blb2txt.exe"
set "TTS=%plus%balcon\balcon.exe"
if not exist "%X2T%" goto dependencies

REM delete any prior run
if exist "%temp%\Balcon-TTS.txt" del "%temp%\Balcon-TTS.txt"

echo Extracting text for TexT 2 Speech
"%X2T%" -out "%temp%\Balcon-TTS.txt" -f "%~1"

echo To kill audio Text To Speech output
echo Close this window, using  X  above.
"%TTS%" -n Zira -f "%temp%\Balcon-TTS.txt"
pause >nul
exit /b

:dependencies
Color 4F
Echo About to download TTS dependencies
echo OR TO ABORT, CLOSE using  X  above.
pause

CD /d "%plus%"
MD balcon
CD balcon
curl -O https://www.cross-plus-a.com/balcon.zip
if exist balcon.zip Tar -xf balcon.zip
cd ..

MD blb2txt
CD blb2txt
curl -O https://www.cross-plus-a.com/blb2txt.zip
if exist blb2txt.zip Tar -xf blb2txt.zip
cd ..
