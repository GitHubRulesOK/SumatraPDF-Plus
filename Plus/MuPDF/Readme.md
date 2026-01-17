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
### mutool run ReportAnnots.js input.pdf  [--lines]
Will produce a filename-annots.txt listing of this format or as single --lines
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
