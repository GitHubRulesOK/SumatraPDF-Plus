This is a collection of files intended to be used with (or without) SumatraPDF by place in a Subfolder called "Plus".

They are mainly Proof Of Concept's (PoC's) and thus may have bugs or customisation needs based on your own use but provided with the aim to be a companion for various related tasks

Most are self documented so read the contents before running to edit or change for your own usage.  
Some may depend on other resources and may need an online connection to fetch 3rd party apps.

Bookmarks
---
There are 3 files here related to PDF bookmarks.
AddBookmark simply appends a single bookmark without adjusting location and for multiple additions consider the use of BentoPDF. However for Auto-Bookmarking use Tracker Xchange editor.  
The other 2 files List-Bookmarks and Add-Bookmarks are for bulk export and import thus easy reordering or bulk editing. When wishing to set ALL levels it may be worth altering them first automaticallly with coherent cpdf before export to avoid a lot of find and replace.

**JPG2PDF**
---
This is now to be retired as replaced by PiCs2PDF (see below) which accepts multiple PDF compatible types.

Measure **NEW
---
This HTA depends on a compiled support DDE.exe so you need both files and they can only work if SumatraPDF is viewing the target file but can be PDF, eBook or Images etc.  
The HTA is a GUI that you use to the side, as it cannot "Stay on top" but need to be able to interact with SumatraPDF mouse clicks.  
It should be self descriptive when you click `Get Pos` or `Calibrate`, which allows you to set a custom scalar, such as for Maps, CAD Architecture or Mechanical Drawings.  
NOTE it does NOT draw lines only GET's one or two points.  
![drawing.png](https://github.com/GitHubRulesOK/SumatraPDF-Plus/blob/master/Images/drawing.png)



Navigator
---
This is a complex beast compared to the others and you need to edit the Config.ini to see its potential
![Navigator Image](https://github.com/GitHubRulesOK/MyNotes/raw/master/images/navigator.png)

PiCs2PDF
---
Not yet added here as still work in progress but is functional and can be used to convert CBZ to PDF if you run with a CMD file.
See PiCs2PDF.PDF here https://github.com/GitHubRulesOK/MyNotes/tree/master/C%23
