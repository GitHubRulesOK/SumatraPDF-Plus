@echo off & setlocal EnableDelayedExpansion & set "filename=%~f1"
REM See https://stackoverflow.com/questions/79389037/imagemagick-net-center-image-on-7-5x6-page-size
REM cleanup any failed prior runs !
if exist "%temp%\jpgdat*.*" del "%temp%\jpgdat*.*"
REM we write a media header here based on prefered dimensions as integers

    REM A4 portrait
REM set /a "PgW=595,PgH=842"
    REM A4 Landscape
REM set /a "PgW=842,PgH=595"

    REM USA Letter Upright
REM set /a "PgW=612,PgH=792"

REM Any custom page can over-ride (Thus allow for decimals if desired) but keep
REM as 5 distinct digital numbers with a dot e.g. ###.## or ####.# as numbers
REM small numbers 00#.## work but may cause or have issues later.

REM 7.5"x6" postcard Horizontal set /a "PgW=540,PgH=432" or
set "PgW=540.00" & set "PgH=432.00"

:MAIN
echo %%PDF-1.7> "%temp%\jpgdat1.txt"
echo %%ANSI>> "%temp%\jpgdat1.txt"
echo 1 0 obj ^<^</Type/Catalog/Pages 2 0 R^>^> endobj>> "%temp%\jpgdat1.txt"
echo 2 0 obj ^<^</Type/Pages/Count 1/Kids [ 3 0 R ]^>^> endobj>> "%temp%\jpgdat1.txt"
echo 3 0 obj ^<^</Type/Page/MediaBox [000.00 000.00 %PgW% %PgH%]/Rotate 0.00/Resources 4 0 R/Contents 5 0 R/Parent 2 0 R^>^> endobj>> "%temp%\jpgdat1.txt"
echo 4 0 obj ^<^</XObject^<^</Img0 6 0 R^>^>^>^> endobj>> "%temp%\jpgdat1.txt"
echo 5 0 obj ^<^</Length 37^>^>>> "%temp%\jpgdat1.txt"
echo stream>> "%temp%\jpgdat1.txt"

REM we ensure the Page Matrix conforms with Set Media size then apply offset
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
echo q %cm% /Img0 Do Q>> "%temp%\jpgdat1.txt"
echo endstream>> "%temp%\jpgdat1.txt"
echo endobj>> "%temp%\jpgdat1.txt"
echo 6 0 obj ^<^</Type/XObject/Subtype/Image/ColorSpace/DeviceRGB/BitsPerComponent 8/Filter/DCTDecode>> "%temp%\jpgdat1.txt"

REM Get and write current image data
@echo fsObj = new ActiveXObject("Scripting.FileSystemObject");var ARGS = WScript.Arguments;var img=new ActiveXObject("WIA.ImageFile");var filename=ARGS.Item(0);img.LoadFile(filename);WScript.StdOut.Write("/Width "+img.Width+"/Height "+img.Height);> "%temp%\jpgdata.js"
@cscript //nologo "%temp%\jpgdata.js" "%filename%">> "%temp%\jpgdat1.txt"
for %%I in ("%filename%") do @echo /Length %%~zI^>^>>> "%temp%\jpgdat1.txt"
echo stream>> "%temp%\jpgdat1.txt"

REM append image
copy /b "%temp%\jpgdat1.txt"+"%filename%" "%temp%\jpgdat2.txt"
echo/>> "%temp%\jpgdat2.txt"
echo endstream>> "%temp%\jpgdat2.txt"
echo endobj>> "%temp%\jpgdat2.txt"

REM prep the trailer BEWARE #>> "%temp%\jpgdat2.txt"
for %%I in ("%temp%\jpgdat2.txt") do set "startxref=%%~zI"
echo xref>> "%temp%\jpgdat2.txt"
echo 0 7 >> "%temp%\jpgdat2.txt"
echo 0000000000 65535 f>> "%temp%\jpgdat2.txt"
echo 0000000017 00000 n>> "%temp%\jpgdat2.txt"
echo 0000000063 00000 n>> "%temp%\jpgdat2.txt"
echo 0000000118 00000 n>> "%temp%\jpgdat2.txt"
echo 0000000244 00000 n>> "%temp%\jpgdat2.txt"
echo 0000000288 00000 n>> "%temp%\jpgdat2.txt"
echo 0000000378 00000 n>> "%temp%\jpgdat2.txt"
echo/ >> "%temp%\jpgdat2.txt"
echo trailer>> "%temp%\jpgdat2.txt"
echo ^<^</Size 7/Info^<^</Producer (JPG2PDF.cmd)^>^>/Root 1 0 R^>^>>> "%temp%\jpgdat2.txt"
echo startxref>> "%temp%\jpgdat2.txt"
echo %startxref%>> "%temp%\jpgdat2.txt"
echo %%%%EOF>> "%temp%\jpgdat2.txt"

REM call the result
copy "%temp%\jpgdat2.txt" "%~dpn1.pdf"
if exist "%temp%\jpgdat*.*" del "%temp%\jpgdat*.*"
