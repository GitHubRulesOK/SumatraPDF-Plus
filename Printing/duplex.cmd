@echo off
REM EDIT the following to where your copy of sumatrapdf portable or installed is located, simplest is same folder
cd /d "%~dp0"
set "sumatrapdf=%~dp0SumatraPDF.exe"
REM Ensure we have a recent UNIVERSAL official only version and remove the version number 
if not exist "%SumatraPDF%" curl https://www.sumatrapdfreader.org/dl/rel/3.6.1/SumatraPDF-3.6.1.exe -Lo SumatraPDF.exe
REM should also respond to https://files.sumatrapdfreader.org/software/sumatrapdf/rel/3.6.1/SumatraPDF-3.6.1.exe
for %%I in ("SumatraPDF.exe") do if %%~zI LSS 12000000 echo download is too small (under 12 Mb) &pause&exit /B
if not exist "%~1" echo you did not drop on me a file or specify a filename to print &pause&exit /B

REM now your standard checks for printer exists etc
REM NONE of which need python or any other application installations.
REM the one LARGE ELEPHANT is an odd number of pages SEE https://github.com/sumatrapdfreader/sumatrapdf/issues/295#issuecomment-2744690669

REM IMPORTANT pages MUST BE FACE DOWN WITH 1 at top of stack to be used FIRST (NATURAL ORDER)
REM to print 1 to 5 of 9 pages then the number of pages does not matter it will be all as quick as all others

 "%SumatraPDF%" -print-to-default -print-settings "1-2000,odd" "%~1"

echo Now turn the paper over (1 was printed first) and press enter PAGE 2 will be printed on BACK of PAGE 1 
echo NOTE there may be a last sheet in hopper so don't forget to check and add to the final stack face down.
pause

REM to print 2 to 8 of 9 pages then the number of pages does not matter it will be all as quick as all others
REM page 9 without a 10 will be left in the input tray and need collection.

 "%SumatraPDF%" -print-to-default -print-settings "1-2000,even" "%~1"
