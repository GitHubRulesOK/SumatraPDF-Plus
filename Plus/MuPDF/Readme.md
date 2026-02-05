Mutool is the command line core build of MuPDF Utilities.
The programmable editing is acheived by calling `MuTool RUN script.js [...] [...]`

The following scripts are simple proof of concepts you can enhance as desired.

### mutool run DelPdfAnnots.js input.pdf [output.pdf]
Will blindly attempt to remove all annot types (for finer control you would need to target by type)
it cannot be "stealth" as it will retain the now empty `/Annots[]` tag in the page dictionary for example:
```
9 0 obj
<</Type/Page/MediaBox[0 0 595 842]/Rotate 0/Resources 7 0 R/Contents 8 0 R/Parent 2 0 R/Annots[]>>
endobj
```
### mutool run ReportAnnots.js [-f=N] [-l=N] input.pdf 
Will produce a filename-annots.txt listing of this -b option format or as default single lines
```
Page: 1
Author: WDAGUtilityAccount    
Modified: D:20260116215925Z     
Subtype: /FreeText 
Rect: [128.48616 460.0332 329.48616 561.0332]
Contents: This is a text...
----------------------------------------
...
```
OR
```
page=1 author=WDAGUtilityAccount     modified=D:20260116215925Z      subtype=/FreeText  rect=[128.48616 460.0332 329.48616 561.0332] contents=This is a text...
...
```
The script can be easily modified to exclude certain types or alter layout.
You may be suprised that there are "popout" entries added by certain /Types and if you want to include those simply remove the `//` at start of the line `//          if (annotObj.get("Subtype") == "Popup") continue;` which means bypass reporting that type.
the dafault is a silent console but -c option is added to use with redirection etc. To stop file write you can easily comment that line.

### mutool run HL2Text.js [-f=N] [-l=N] [-o|-o=filename.txt] [-s] file.pdf

Extract text under PDF HighLight HLZone2TXT.js Works with MuPDF 1.27 Improved version  
-f= to -l= are page ##'s  
-o writes an output filename: will be "input-annots.txt" unless specified  
-s is for no console stream (pointless without -o)  

### mutool run SeekAndHL.js [-a=HLmode] [-c=RRGGBBAA] [-f=N] [-i] [-l=N] [-n] -s="text" [-t | -t="custom"] [-q] file.pdf

Add PDF highlight annotations over matching text. Works with MuPDF 1.27 Improved version
 -a=             Default=HL (Highlight, Squiggly, StrikeOut, Underline)
 -c=RRGGBBAA     highlight colour (default FFFF00FF) AA=Highlight Opacity (FF=100% for lines or HL 50% Blend)
 -f=# / -l=#     first/last page numbers, same # = one page
 -i              case-insensitive searching
 -n              count-only mode (no save, no annotations)
 -s="find text"  Required literal quoted search string (supports spaces) may not always match seen plain text (Not full UTF)
 -t              embed above search string into annotation
 -t="text"       embed a custom text comment
 -q              quite

Note: UL/SQ/ST annotations are full opacity yet may appear faint with light colours. E.g. default Yellow 1 pt may look invisible.

To use for just find a match (no write a file) use either  `mutool run SeekAndHL.js -n -s"phrase" file.pdf` OR `mutool run SeekAndHL.js -i -n -s"phrase" file.pdf`
Example from a mixed source describing MuPDF and mupdf over 2 pages
```
>mutool run seekandhl.js -i -n -s="Mupdf" SO79283524.pdf
Page 1: 8 matches
Page 2: 3 matches
Total matches: 11
>mutool run seekandhl.js -n -s="mupdf" SO79283524.pdf
Page 1: 6 matches
Page 2: 2 matches
Total matches: 8
>mutool run seekandhl.js  -n -s="MuPDF" SO79283524.pdf
Page 1: 2 matches
Page 2: 1 matches
Total matches: 3
```
