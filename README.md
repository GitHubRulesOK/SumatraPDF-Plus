# SumatraPDF-Plus
Scripts to HotFix user requested enhancements to SumatraPDF (see below)  
It is my personal compendium so decide which bits you do not require and delete accordingly.

Be aware due to the unusual uses some scripts employ they may raise "False Positives" in 
Anti-Virus scanners, you can read the contents as Open Source plain text before download 
And normally if you download a script as .txt you can then rename to a run time extension.

Intended structure is This Top level folder with SumatraPDF.exe and friends (A portable version of 3.6.1 or 3.7 pre-release is recommended)
Then a middle level of scripts and a lower level of folders with dependencies.

<img width="673" height="287" alt="image" src="https://github.com/user-attachments/assets/dea66771-b7cb-436f-b0d5-d0a7b2545179" />

Some simply interact with Windows Functions like open the current file in Edge (Perhaps for "Dual" file review or add inking?)  
You can assign it to a single "Key", so here it opens the file on the left when I press the `T` key.
```
ExternalViewers [
	[
		CommandLine = c:\windows\system32\cmd.exe /r start="msedge.exe" --app="%1#page=%p"
		Name = Edge-i&t
		Filter = *.pdf
		Key = t
	]
]
```
![Edge-It.png Image](https://github.com/GitHubRulesOK/SumatraPDF-Plus/blob/master/Edge-It.png)

Purpose 
------- 
A collection of temporary fixes to provide some Feature Requests from either

SumatraPDF issues https://github.com/sumatrapdfreader/sumatrapdf/issues  
or the User Forum https://forum.sumatrapdfreader.org/  
As / If / When any features are implimented in official / pre-releases they may be removed here.  

See the Plus folder for current offerings as this top level is only shows those related to portable settings.  
There are several ways to add scripts to SumatraPDF but the easiest is via simple CMD files in a subfolder.  
```
	[
		CommandLine = ".\plus\exportpng.cmd" "%1" page=1-N
		Name = Export all pages to &Png
		Filter = *.*
		Key = P
	]
```
THe older scripted needs are now likely found in 3.6+ so most older ones have been removed.

 Plus Functions list
--------------------
2021-2025
Slowly migrated some updated "Addins" from https://github.com/GitHubRulesOK/MyNotes/tree/master/AppNotes/SumatraPDF/Addins
2025 /2026 
Multiple additions and updates. This folder has those related to SumatraPDF.exe command line or its settings.txt file, the plus folder contains those generally called internally.  

PicColo###.hta
---
A range of small coloured instruments :-)
Some preset the settings colors and some act on selections.  

PicColo.hta now allows for mode 3 (the newest for SumatraPDF 3.6.1+) https://github.com/GitHubRulesOK/SumatraPDF-Plus/blob/master/PicColo361.hta  
Works by select an area, press a key, and on pick a colour it is then highlighted etc.
![PicColo361 Image](https://github.com/GitHubRulesOK/SumatraPDF-Plus/blob/master/Plus/PicColo361.png)  
There are many ways to set the color related commands (apart from area highlight selection), so you can use duplicated copies for several different actions.  
To assign to a key and menu add to ExternalViewers a call, like this (using your own folder\filename).  
```
ExternalViewers [
	[
		CommandLine = "C:\...\SumatraPDF\17629\PicColo3.hta"
		Name = PicColo (Pick a &HL colour)
		Filter = *.pdf
		Key = h
	]
	[
		CommandLine = "C:\...\PDF\SumatraPDF\17629\PicColo2.hta"
...
    [
]
```
The earliest PicColo.hta was for SumatraPDF 3.3+. This MODE 1 is more limited as it could only SET the HL colour in the adjoining SumatraPDF-settings.txt file. So it is called via File Menu to use before a batch of highlights as there was no "hot key" then.
```
	[
		CommandLine = "C:\Users\  path to \SumatraPDF\3.3\PicColo1.hta"
		Name = PicColo (Set the &HL colour)
		Filter = *.pdf
	]
```
In 3.6 and later you can use a key to call it and change more than just "HighlightColor" e.g. "UnderlineColor" by edit copies of the HTA to change different keyword values.
```
	[
		CommandLine = "C:\Users\  path to \SumatraPDF\3.5\PicColo2.hta"
		Name = PicColo (Set the &HL colour)
		Filter = *.pdf
        Key = h
	]
```
In 3.4.6 you could use it to change "TextIconColor" and in 3.5 "StrikeOutColor"  or  "SquigglyColor" and could be adapted for 3.6+ for set annotation values such as "FreeTextSize"

Printerinfo is based on [https://github.com JensBejer PrinterInformation](https://github.com/JensBejer/PrinterInformation).
This version is a self compiling cmd file for use on Windows 10+
Typical output
```
PrinterInfo.exe -papers fax
Paper definitions for the printer 'Fax' on 'F28B5B59-DF9B-4':
Paper Name                    Kind   Size in*in   Size mm*mm
Letter                         (1) (8.50x11.00) (215.90x279.40)
Letter Small                   (2) (8.50x11.00) (215.90x279.40)
Legal                          (5) (8.50x14.00) (215.90x355.60)
Statement                      (6) (5.50x8.50) (139.70x215.90)
Executive                      (7) (7.25x10.50) (184.15x266.70)
A4                             (9) (8.27x11.69) (210.06x296.93)
```

