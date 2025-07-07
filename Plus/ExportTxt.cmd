@Mode 60,17 & Color 9F & Title SumatraPDF addin ExportTxt [.eXt2.Txt(s)] v'25-01-20--01
@echo off & SetLocal EnableDelayedExpansion & pushd %~dp0 & goto MAIN
Do not delete the above two lines since they are needed to prepare this script.

 Potted version history  v'25-01-20--01 first public release (default is simple left justified plain text)
 
 Read Me 1st (you can strip out most of these comments in your working copy)
 Note: Later lines that start with :LETTERS are branches that need to be kept BUT
 any Later lines that start with : And a space, are inline comments that may be REMoved

 SumatraPDF script to EXPORT file page(s) as TXT using MuTools whilst viewing.
 TODO Optional use of current related GhostScript to allow for other formats.
 TODO Allow for use when -p password is required
 TODO allow for -R angle or -h -w (scaling)

 The aim is to not affect original file. When testing they appear to be unaffected.
 But I give no guarantees, as on occasion MuTool may attempt to fix a bad file.
 TODO use a temporary copy and delete once done.

  Current MuPDF tools are available from https://www.mupdf.com/downloads/index.html
  https://mupdf.com/downloads/archive/mupdf-1.20.0-windows-tesseract.zip (recommended as last known 32 bit version)

Methodology

 This script pases the current FileName and PageRange to MuPDF\MuTool.exe
 ONLY .TXT OUTput is offered (NO Stext or ePub, but others are possible, Read the Manual)
 Input of many types including ePub or (o)xps and GIF/JPG/TIFF are allowed but
 no guarantee they will all be processed. Intended as an addin to SumatraPDF, but...
 When installed in the correct Plus location you can right click this file and "SendTo
 Desktop as shortcut" where you can ALSO use it for drag and drop (max=ONE file)

 CAUTION due to reflow differences, ePub and FB2 page numbers and appearance may
 vary wildly from MuPDF compared to those in SumatraPDF. To get a better sync (but 
 output will never be the same) you can vary font size / name in SumatraPDF-settings.txt.

Presumptions (letter case should not matter, but relative positions do)

1) THIS FILE (ExportTxt.CMD) is located in same folder with Mutool.exe in the same folder
2) there is an %Plus% location stored OR set in the users Environment Variables
 
 A reminder about %Plus% (skip this section if you have already added other "addins")
 This cmd script is intended to be stored in a folder relative to SumatraPDF-settings.txt
 However when run, that location can be different for every user. Thus in order that multiple
 "addins" can be found together they are stored in subfolders of ...\SumatraPDF\Plus\.
 When run, the system needs to know where the Plus folder is, so we need to SET a
 system-wide environment variable e.g.  SET "Plus=D:\location of\SumatraPDF\Plus\"
 There is no need to add " " marks but it needs to be SET PRIOR to starting SumatraPDF.
 For many "portableapps" that function may be done as part of their start-up mechanism.
 The simplest way to set user env settings in a static system is to start Edit Env...
 and accept "Edit Environment variables for your account" where you can use Edit > New
 Variable name: (key in) Plus
 Variable value: (key in or SAFER is browse directory) e.g. c:\myapps\sumatrapdf\Plus\
 Once done don't forget to select OK
 For a USB start-up batch file use something like SET "Plus=%~d0Apps\sumatrapdf\Plus\"

3) A recent copy of mutool.exe must be in same folder
    Note that there are additional files supplied in both of the 2 latest windows zip
    files from the download links above. However, you should ONLY need one, mutool.exe

4) The SumatraPDF-settings.txt is in the folder  ...\SumatraPDF\

5) Most important THAT is NOT C:\Program Files\SumatraPDF\  However,
    %LOCALAPPDATA%\SumatraPDF\ or A:\PORTABLE\ folder SHOULD be ok,
    for multi-user you would need to change addins to a common fixed location.

6) An entry in advanced SumatraPDF-settings.txt is needed as similar to this for 3.6 pre-release

ExternalViewers [
	[
		CommandLine = "C:\Users\K\AppData\Local\SumatraPDF\Plus\ExportTxt.cmd" "%1" page=%p
		Name = Extract page &text
		Filter = *.*
                Key = t
	]
]

 If you wish to always modify a range of pages and on occasion just single pages then 
 a) Remove the %p from the command line (remember to keep = at end e.g. "%1" page=)
 b) Change in Name = from "current page" to "page range"
 alternative is to have 2 different "viewer" blocks but then you would need a second shortcut

7) The shortcut for above will be ALT + F + t (Note Alt+F+many others = used or reserved)

A possible alternative may be "C:\Users\poppler\22.02\pdftotext.exe" -nopgbrk -layout -enc UTF-8 -f %p -l %p "%1"
But needs better page selector

End of readme / notes
----------------
:MAIN
: First check for the required mutool support file and that filename is valid
: if you have not placed mutool where recommended as is relative to this
: file which was set at start then you may need to adjust both here and later
: TL;DR this test should not be needed but for those users that don't RTFM

if "%plus%"=="" set "plus=%~dp0"
if not exist "%plus%mupdf\mutool.exe" echo: & echo  Either MuTool.exe or this file are not in correct location & goto :mutool
if not exist "%~f1" echo: & echo "%~dpn1%~x1" & echo  Appears NOT to exist as a valid file & goto HELP

: IF you wish to add or restrict input to only certain extensions then edit the file
: extensions in the next line.
for %%X in (epub,fb2,oxps,pdf,xps) do IF /I .%%X.==%~x1. goto ALLOWED
echo  %~x1 Appears to be unacceptable & goto HELP

:ALLOWED
: Very basic check if %2=Page[s] , case should not matter, with/without s
for %%p in (-P, -Page, -Pages, Page, Pages) do if /i %2.==%%p. goto PASS
: For use with drag and drop a file, we also pass for input of range
if %2.==. goto RANGE

:HELP
echo:
echo  Example Usage : "%~nx0" "C:\pdfs\in.pdf" pages=2-5
echo:
echo  You can specify just one single page, e.g.  Page=15  or
echo  a range like Pages=5-10 etc.  or page=1-N (ALL pages)
echo:
echo  See https://www.mupdf.com/docs/manual-mutool-draw.html
echo  for other options.
echo:
echo  Call page without values to manually enter a page-range
echo:
echo  ^> "%~nx0" "C:\pdfs\in.pdf" page (Note s^&= are optional)
echo:
pause & exit \b

:PASS
: There should be no error if the file is held open in SumatraPDF
: but later may need to add an info or similar test for a standalone file
: There is little check if the Pages=range is valid so beware what is acceptable,
if %3.==. goto RANGE
: However, if given, lets remind user which page(s) was / were requested
set pages="%3"
for %%R in (All,1-N) do if /i %3.==%%R. set pages=1-N
echo:
echo  Page Range requested: page(s) = %pages% & goto RUN

:RANGE
echo:
echo  Enter page number or page-range or "r-a,n-g,e-s" (abort=0) 
set /p pages="Range = "
if %pages%.==0. exit /b

:RUN
: All should be now OK to run MuTool with <filename> <pages>
echo:
echo  Exporting page(s)=%pages% as 
echo  "%~dpn1-Page-####.txt"
echo:

: IMPORTANT default for txt output may be affected by spacing etc. highly recommend use HTML

:
"%Plus%mupdf\mutool.exe" draw -r 200 -o "%~dpn1-Page-%%4d.txt" "%~f1" "%pages%"
echo:
echo Done & dir /b "%~dpn1-Page-*.txt"
: pause
: Optional, you can comment, change or delete timeout if not wanted (currently 10 seconds)
timeout /t 10

:eof
popd
exit /b

:Download Dependencies
echo on
: Mutool 32bit 1.20 is at mupdf-1.20.0-windows-tesseract we use this because last universal 32&64bit
curl -L -O https://mupdf.com/downloads/archive/mupdf-1.20.0-windows-tesseract.zip
tar -m -xf mupdf-1.20.0-windows-tesseract.zip
ren mupdf-1.20.0-windows-tesseract mupdf
echo Dependencies Downloaded and unpacked. Please run again. 
pause
