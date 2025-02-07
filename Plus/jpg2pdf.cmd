@echo off & setlocal EnableDelayedExpansion & set "filename=%~f1"
REM Update 2025-02-07 Include background colours (If transparent, page readers should show on a white ground)
REM
REM This file will accept a filename or "Drag and drop" a basic JPG file to wrap as a centred single page PDF
if /I not exist "%~dpn1.jpg" echo %filename% is not a .jpg & pause & exit /b
REM
REM cleanup any failed prior runs ! Use the .bin extension as file is considered BINary
if exist "%temp%\jpgdat*.*" del "%temp%\jpgdat*.*"
REM IMPORTANT we first write a media header, here either based on prefered dimensions as integers
REM ISO A4 Portrait    set /a "PgW=595,PgH=842" or ISO A4 Landscape     set /a "PgW=842,PgH=595"
REM USA Letter Upright set /a "PgW=612,PgH=792" or USA Letter Landscape set /a "PgW=612,PgH=792"

REM Any custom page can also be used (Thus we allow for decimals if desired) but keep as 5 distinct
REM digital numbers with a dot e.g. ###.## or ####.# or #####. MAXimum allowed numbers were 14400. 
REM small numbers 00#.## work but may cause or have issues later. We will try to allow for that later!

REM example 7.5"x6" Horizontal Postcard is set /a "PgW=540,PgH=432" or for Vertical 6"x7.5" we can use
set "PgW=432.00" & set "PgH=540.00"

REM Set a background colour as 1/% RGB using 0.00 for none and 1.00 for full or .### for %colour
REM IMPORTANT NOTE BgC = total 14 characters long
REM We can use a transparent page background but still needs 14 characters hence we can "hack" with n
REM "BgC=n 0.00 0.0 0.0"
REM Example Black=0.00 0.00 0.00 White=1.00 1.00 1.00 and Mid Grey is either =0.50 0.50 0.50 OR
set "BgC=.500 .500 .500"

REM Ok now start to build PDF file wrapper
:MAIN
echo %%PDF-1.7> "%temp%\jpgdat1.bin"
echo %%ANSI>> "%temp%\jpgdat1.bin"
echo 1 0 obj ^<^</Type/Catalog/Pages 2 0 R^>^> endobj>> "%temp%\jpgdat1.bin"
echo 2 0 obj ^<^</Type/Pages/Count 1/Kids [3 0 R]^>^> endobj>> "%temp%\jpgdat1.bin"
echo 3 0 obj ^<^</Type/Page/MediaBox [000.00 000.00 %PgW% %PgH%]/Rotate 0.00/Resources 4 0 R/Contents 5 0 R/Parent 2 0 R^>^> endobj>> "%temp%\jpgdat1.bin"
echo 4 0 obj ^<^</XObject^<^</Img0 6 0 R^>^>^>^> endobj>> "%temp%\jpgdat1.bin"
echo 5 0 obj ^<^</Length 76^>^>>> "%temp%\jpgdat1.bin"
echo stream>> "%temp%\jpgdat1.bin"

REM Ensure the Page Matrix lengths conform with the set Media size then apply as offsets
REM Get and write current image data
@echo fsObj = new ActiveXObject("Scripting.FileSystemObject");var ARGS = WScript.Arguments;var img=new ActiveXObject("WIA.ImageFile");var filename=ARGS.Item(0);img.LoadFile(filename);WScript.StdOut.Write("set /a ImW="+img.Width+",ImH="+img.Height);> "%temp%\jpgdata.js"
@cscript //nologo "%temp%\jpgdata.js" "%filename%"> "%temp%\jpgdat1.bat"
call "%temp%\jpgdat1.bat"
Rem we need to sanitize entries such as "PgH=080.00" which would be seen as illegal and ensure null is at least 1
FOR /F "tokens=* delims=0" %%A IN ("%PgW%") DO SET "PgW=%%A"
set /A "PgW=PgW/1" && IF "%PgW%" LEQ "0" SET "PgW=1"
FOR /F "tokens=* delims=0" %%A IN ("%PgH%") DO SET "PgH=%%A"
set /A "PgH=PgH/1" && IF "%PgH%" LEQ "0" SET "PgH=1"
set /a "Calc1=!ImH!*%PgW%/!ImW!"
set /a "CalcY=(%PgH%-!Calc1!)/2"
if %CalcY% GEQ 1 set "PgO=%PgW% 0 0 !Calc1! 0 !CalcY!" & goto skip
set /a "Calc1=%ImW%*%PgH%/%ImH%"
set /a "CalcX=(%PgW%-!Calc1!)/2"
set "PgO=!Calc1! 0 0 %PgH% !CalcX! 0"
:skip
set "CmX=%PgO% cm                    "
set "CM=%CmX:~0,24%"
echo q 0 0 %PgW% %PgH% re %BgC% rg f q %cm% /Img0 Do Q Q>> "%temp%\jpgdat1.bin"
echo endstream>> "%temp%\jpgdat1.bin"
echo endobj>> "%temp%\jpgdat1.bin"
echo 6 0 obj ^<^</Type/XObject/Subtype/Image/ColorSpace/DeviceRGB/BitsPerComponent 8/Filter/DCTDecode>> "%temp%\jpgdat1.bin"

REM Get and write current image data again
@echo fsObj = new ActiveXObject("Scripting.FileSystemObject");var ARGS = WScript.Arguments;var img=new ActiveXObject("WIA.ImageFile");var filename=ARGS.Item(0);img.LoadFile(filename);WScript.StdOut.Write("/Width "+img.Width+"/Height "+img.Height);> "%temp%\jpgdata.js"
@cscript //nologo "%temp%\jpgdata.js" "%filename%">> "%temp%\jpgdat1.bin"
for %%I in ("%filename%") do @echo /Length %%~zI^>^>>> "%temp%\jpgdat1.bin"
echo stream>> "%temp%\jpgdat1.bin"

REM Now append image
copy /b "%temp%\jpgdat1.bin"+"%filename%" "%temp%\jpgdat2.bin"
echo/>> "%temp%\jpgdat2.bin"
echo endstream>> "%temp%\jpgdat2.bin"
echo endobj>> "%temp%\jpgdat2.bin"

REM prep the trailer BEWARE do not use #>> "%temp%\jpgdat2.bin" for example add space after 0 7 and %startxref%
for %%I in ("%temp%\jpgdat2.bin") do set "startxref=%%~zI"
echo xref>> "%temp%\jpgdat2.bin"
echo 0 7 >> "%temp%\jpgdat2.bin"
echo 0000000000 65535 f>> "%temp%\jpgdat2.bin"
echo 0000000017 00000 n>> "%temp%\jpgdat2.bin"
echo 0000000063 00000 n>> "%temp%\jpgdat2.bin"
echo 0000000116 00000 n>> "%temp%\jpgdat2.bin"
echo 0000000242 00000 n>> "%temp%\jpgdat2.bin"
echo 0000000286 00000 n>> "%temp%\jpgdat2.bin"
echo 0000000415 00000 n>> "%temp%\jpgdat2.bin"
echo/>> "%temp%\jpgdat2.bin"
echo trailer>> "%temp%\jpgdat2.bin"
echo ^<^</Size 7/Info^<^</Producer (JPG2PDF.cmd)^>^>/Root 1 0 R^>^>>> "%temp%\jpgdat2.bin"
echo startxref>> "%temp%\jpgdat2.bin"
echo %startxref% >> "%temp%\jpgdat2.bin"
echo %%%%EOF>> "%temp%\jpgdat2.bin"

REM call the result
copy "%temp%\jpgdat2.bin" "%~dpn1.pdf"
if exist "%temp%\jpgdat*.*" del "%temp%\jpgdat*.*"
