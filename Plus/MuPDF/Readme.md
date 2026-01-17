Mutool is the command line core build of MuPDF Utilities.
The programmable editing is acheived by calling `MuTool RUN script.js [...] [...]`

The following scripts are simple proof of concepts you can enhance as desired.

### mutool run DelPdfAnnots.js input.pdf [output.pdf]
will blindly attempt to remove all annot types (for finer control you would need to target by type)
it cannot be "stealth" as it will retain the now empty `/Annots[]` tag in the page dictionary for example:
```
9 0 obj
<</Type/Page/MediaBox[0 0 595 842]/Rotate 0/Resources 7 0 R/Contents 8 0 R/Parent 2 0 R/Annots[]>>
endobj
```
