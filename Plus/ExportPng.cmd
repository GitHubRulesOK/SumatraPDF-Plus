@Mode 60,17 & Color 9F & Title SumatraPDF addin ExportPng [.eXt2.png(s)] v'24-11-02--09
@echo off & SetLocal EnableDelayedExpansion & pushd %~dp0 & goto MAIN
Do not delete the above two lines since they are needed to prepare this script.

 Potted version history  v'21-02-18--01 first public release (default is -r 96 dpi)
 v'21-02-18--06 very minor edits addins (..was wrong way round..) also 1-N
 is prefered and better acceptance of multiple ranges such as “6-10,12,18,21-25”
  v'24-03-20--07 very minor edits recommend use 1.20 for last known 32bit compatability
 improve file handling for "filenames with spaces" 
 * simplify to mutool be in this folder or vise versa
 v'24-11-02--08 added mutool download link
 v'24-11-02--09 adapted for SumatraPDF\plus

 Read Me 1st (you can strip out most of these comments in your working copy)
 Note: Later lines that start with :LETTERS are branches that need to be kept BUT
 any Later lines that start with : And a space, are inline comments that may be REMoved

 SumatraPDF script to EXPORT file page(s) as PNG using MuTools whilst viewing.
 TODO Optional use of current related GhostScript to allow for other formats.
 TODO Allow for use when -p password is required
 TODO allow for -R angle or -h -w (scaling)

 The aim is to not affect original file. When testing they appear to be unaffected.
 But I give no guarantees, as on occasion MuTool may attempt to fix a bad file.
 TODO use a temporary copy and delete once done.

  Current MuPDF tools are available from https://www.mupdf.com/downloads/index.html but using legacy (older)
  https://mupdf.com/downloads/archive/mupdf-1.20.0-windows-tesseract.zip (recommended as last known 32 bit version)

Methodology

 This script pases the current FileName and PageRange to MuPDF\MuTool.exe
 ONLY .PNG OUTput is offered (NO Jpg, but others are possible, Read the Manual)
 Input of many types including ePub or (o)xps and GIF/JPG/TIFF are allowed but
 no guarantee they will all be processed. Intended as an addin to SumatraPDF, but...
 When installed in the correct addins location you can right click this file and "SendTo
 Desktop as shortcut" where you can ALSO use it for drag and drop (max=ONE file)

 CAUTION due to reflow differences, ePub and FB2 page numbers and appearance may
 vary wildly from MuPDF compared to those in SumatraPDF. To get a better sync (but 
 output will never be the same) you can vary font size / name in SumatraPDF-settings.txt.

Presumptions (letter case should not matter, but relative positions do)

1) THIS FILE (ExportPng.CMD) is located in same folder with Mutool.exe in the same folder
2) there is an %addins% location stored OR set in the users Environment Variables
 
 A reminder about %addins% (skip this section if you have already added other "addins")
 This cmd script is intended to be stored in a folder relative to SumatraPDF-settings.txt
 However when run, that location can be different for every user. Thus in order that multiple
 "addins" can be found together they are stored in subfolders of ...\SumatraPDF\Addins\.
 When run, the system needs to know where the addins folder is, so we need to SET a
 system-wide environment variable e.g.  SET "addins=D:\location of\SumatraPDF\addins\"
 There is no need to add " " marks but it needs to be SET PRIOR to starting SumatraPDF.
 For many "portableapps" that function may be done as part of their start-up mechanism.
 The simplest way to set user env settings in a static system is to start Edit Env...
 and accept "Edit Environment variables for your account" where you can use Edit > New
 Variable name: (key in) addins
 Variable value: (key in or SAFER is browse directory) e.g. c:\myapps\sumatrapdf\addins\
 Once done don't forget to select OK
 For a USB start-up batch file use something like SET "addins=%~d0Apps\sumatrapdf\addins\"

3) A recent copy of mutool.exe must be in same folder
    Note that there are additional files supplied in both of the 2 latest windows zip
    files from the download links above. However, you should ONLY need one, mutool.exe

4) The SumatraPDF-settings.txt is in the folder  ...\SumatraPDF\

5) Most important THAT is NOT C:\Program Files\SumatraPDF\  However,
    %LOCALAPPDATA%\SumatraPDF\ or A:\PORTABLE\ folder SHOULD be ok,
    for multi-user you would need to change addins to a common fixed location.

6) An entry in advanced SumatraPDF-settings.txt is needed as similar to this

ExternalViewers [
	[
		CommandLine = "C:\Users\K\AppData\Local\SumatraPDF\Plus\ExportPng.cmd" "%1" page=%p
		Name = Save current page &Graphics to PNG 
		Filter = *.*
	]
]

 If you wish to always modify a range of pages and on occasion just single pages then 
 a) Remove the %p from the command line (remember to keep = at end e.g. "%1" page=)
 b) Change in Name = from "current page" to "page range"
 alternative is to have 2 different "viewer" blocks but then you would need a second shortcut

7) The shortcut for above will be ALT + F + G (Note Alt+F+many others = used or reserved)

End of readme / notes
----------------
:MAIN
: First check for the required mutool support file and that filename is valid
: if you have not placed mutool where recommended as is relative to this
: file which was set at start then you may need to adjust both here and later
: TL;DR this test should not be needed but for those users that don't RTFM

if "%addins%"=="" set "addins=%~dp0.."
if not exist "%addins%mupdf-1.20.0-windows-tesseract\mutool.exe" echo: & echo  Either MuTool.exe or this file are not in correct location & goto :mutool
if not exist "%~f1" echo: & echo "%~dpn1%~x1" & echo  Appears NOT to exist as a valid file & goto HELP

: IF you wish to add or restrict input to only certain extensions then edit the file
: extensions in the next line. NOTE .bmp, .jpg and .png are NOT multi-page
for %%X in (bmp,cbz,epub,fb2,gif,jpg,oxps,pdf,png,tif,tiff,xps,zip) do IF /I .%%X.==%~x1. goto ALLOWED
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
echo  "%~dpn1-Page-####.png"
echo:

: IMPORTANT default for png images output is highly recommended as -r 96
: BUT, if intended use is for OCR later, then it should be higher e.g. -r 300
:
"%addins%mupdf-1.20.0-windows-tesseract\mutool.exe" draw -r 96 -o "%~dpn1-Page-%%4d.png" "%~f1" "%pages%"
echo:
: pause
: Optional, you can comment, change or delete timeout if not wanted (currently 5 seconds)
timeout /t 5

:eof
exit /b

:Download Dependencies
:Mutool 32bit 1.20 is at mupdf-1.20.0-windows-tesseract
curl -O https://mupdf.com/downloads/archive/mupdf-1.20.0-windows-tesseract.zip
so 
tar -m -xf mupdf-1.20.0-windows-tesseract.zip
