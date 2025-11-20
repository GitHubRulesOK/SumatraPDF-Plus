# SumatraPDF-Plus
AutoHotKey and Other Scripts to HotFix user requested enhancements to SumatraPDF (see below)  
It is my personal compendium so decide which bits you do not require and delete accordingly.

Be aware due to the unusual uses some scripts employ they may raise "False Positives" in 
Anti-Virus scanners, you can read the contents as Open Source plain text before download 
And normally if you download a script as .txt you can then rename to a run time extension.

Purpose 
------- 
A collection of temporary fixes to provide some Feature Requests from either

SumatraPDF issues https://github.com/sumatrapdfreader/sumatrapdf/issues

or the User Forum https://forum.sumatrapdfreader.org/

As / If / When any features are implimented in official / pre-releases they may be removed here.

Requirements
------------
Expects to be run at the same time as SumatraPDF from https://www.sumatrapdfreader.org/free-pdf-reader.html

Expects (later will need) to be in a subdirectory named \plus in the folder with SumatraPDF-settings.txt

Needs a copy of AutoHotKeyU32[or U64].exe to be renamed as plus.exe in same \plus subfolder.

Get the latest copy from https://autohotkey.com/download/ahk.zip

 Plus Functions list
--------------------
   +  CTRL [& SHIFT] 4 = Web Lookup / Search
   +  CTRL [& SHIFT] 5 = Translate / Including Text to Speech
   +  (part done) Optionally reassign some hotkeys / shortcuts
   +  Reassign Double Click from single to multi word selection (Click & Drag)
   +  Reassign Single Click temporarily from Left to Right (Click & Drag Page)
   
      Caution This may block above multi-word selection, Right click to stop
   +  Reassign Right Click to call All commands on tablets (without two tap exit) for fullscreen mode

2021
Slowly migrating some updated "Addins" from https://github.com/GitHubRulesOK/MyNotes/tree/master/AppNotes/SumatraPDF/Addins

2025  
Multiple additions and updates.
Printerinfo is based on https://github.com/JensBejer/PrinterInformation/blob/main/PrinterInformation/PrinterInformation.
This version is a self compiling cmd file for use on Windows 10+
