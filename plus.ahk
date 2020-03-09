;v+2020-03-09T00,0 beta; Please do not edit this line, it for version checking.
; lines starting with ; are comments
; This file is plus.ahk An AutoHotKey script to add extra functionality to
; Sumatra PDF viewer. This file should be placed in a subfolder (\plus) below
; SumatraPDF-settings.txt. Normally that subfolder would be.
; C:\Users\ YourUserName \AppData\Local\SumatraPDF\plus
;
; This app requires either, to be compiled with AutoHotKey and renamed plus.exe
; or a copy of AutoHotkeyU32(orU64).exe be renamed plus.exe in the same folder.
;
; Terms & Conditions
; As supplied this file and its associated .ini have been written and tested so
; as not to harm or affect safe usage of your computer.
; However, by its very nature you are encouraged to alter settings here to your
; preferences, thus change with caution to protect yourself from your actions.
;
; CAUTION you edit this control file at your own risk.
; Be aware it is possible to harm your PC by using unexpected commands.
; Always first test your changes on a sacrificial machine.

; The next line is for debugging command line usage. Note passing arguments via
; ahk command line can be a problem, so only add options that do not use quotes
; such as -restrict
;msgbox %0% first = %1%
;
; NOTE if you want SumatraPDF to be given commands via plus then the command
; needed is plus.exe plus.ahk then others possibly "quoted" for SumatraPDF such
; as "file path\name.pdf"
; If you want plus.exe to be auto running at the same time as SumatraPDF.exe
; then remove the ; at start of next line, save this file & 1st launch plus.exe
;run SumatraPdf.exe
;
; If the above command does not work e.g. with portable copy, then include path
;

; Plus Functions list
;--------------------
;   +  CTRL [& SHIFT] 4 = Web Lookup / Search
;   +  CTRL [& SHIFT] 5 = Translate / Including Text to Speech
;   +  (part done) Reassign some hotkeys
;   +  Reassign Double Click from single to multi word selection (Click & Drag)
;   +  Reassign Single Click temporarily from Left to Right (Click & Drag Page)
;      Caution This will block above multi-word selection, Right click to stop
;              TO DO perhaps improve above to only work whilst mouse held down
;              however, that might be tricky for tablet usage.
;   -  (Work in Progress not included) Modify toolbar icon actions per forum
;   -  (Work in Progress not included) Add extra toolbar icons
;   -  (Work in Progress not included) OCR with TTS
; More ?
;
; Avoid making changes here. ALL/MOST user configuration values are in plus.ini
;++++++++++++++++++++++++++
#NoEnv  
SendMode Input  
SetWorkingDir %A_ScriptDir%  
#SingleInstance force
#Persistent
; If a script's Hotkeys, Clicks, or Sends are noticeably slower
; then uncomment next line, however avoid for now as should not be needed
;Process, Priority, , High
;
; Get ini values for RunCmd/Web lookups for any selected text from SumatraPDF
; should work with DoubleClick one word or default CTRL+ Left mouse button phrase/paragraph
;
; Lets currently FALLBACK on fail to Iexplorer & duckduckgo search OR webster dictionary
; THESE ARE American DEFAULT fallback VALUES DO NOT CHANGE HERE, change them in plus.ini
IniRead, RunKey1, plus.ini, RunAppS, RunKey1 , ^4
IniRead, RunCmd1, plus.ini, RunAppS, RunCmd1 , C:\Program Files\Internet Explorer\iexplore.exe
IniRead, RunArg1, plus.ini, RunAppS, RunArg1 , https://duckduckgo.com/?q=
IniRead, RunKey2, plus.ini, RunAppS, RunKey2 , ^+4
IniRead, RunCmd2, plus.ini, RunAppS, RunCmd2 , C:\Program Files\Internet Explorer\iexplore.exe
IniRead, RunArg2, plus.ini, RunAppS, RunArg2 , https://www.merriam-webster.com/dictionary/
IniRead, RunKey3, plus.ini, RunAppS, RunKey3 , ^5
IniRead, RunCmd3, plus.ini, RunAppS, RunCmd3 , C:\Program Files\Internet Explorer\iexplore.exe
IniRead, RunArg3, plus.ini, RunAppS, RunArg3 , https://www.merriam-webster.com/dictionary/
IniRead, RunKey4, plus.ini, RunAppS, RunKey4 , ^+5
IniRead, RunCmd4, plus.ini, RunAppS, RunCmd4 , C:\Program Files\Internet Explorer\iexplore.exe
IniRead, RunArg4, plus.ini, RunAppS, RunArg4 , https://duckduckgo.com/?q=

IniRead, ModWinS, plus.ini, ToggleS, ModWinS , false ; failsafe for a bad entry is false
IniRead, ModSlct, plus.ini, ToggleS, ModSlct , false ; failsafe is Double Click one word
IniRead, ModLeft, plus.ini, ToggleS, ModLeft , false ; failsafe for swap Left to Right

; Try to confine actions to SumatraPDF note this does not always confine mouse
;Hotkey, "IfWinActive", "ahk_exe SumatraPDF.exe"
Hotkey, IfWinActive, ahk_class SUMATRA_PDF_FRAME

Hotkey %RunKey1%, RunArg1 , on ; redirect user assigned RunKey and RunArg to get clipboard
Hotkey %RunKey2%, RunArg2 , on ;
Hotkey %RunKey3%, RunArg3 , on ;
Hotkey %RunKey4%, RunArg4 , on ;
;
Hotkey, IfWinActive

;ListHotkeys

; Throw in an extra return just for good measure
return

; ModWinS = Pass through Window & s key and Hook to test / pass web: clipboard
~#s:: ; note lowercase only
if ModWinS = true ; note if false or clip empty then return
{
  gosub GetClip
  if Clip =
    {
    ; msgbox No Clip ; for debugging only, default No Clip action is let pass
    return
    }
  else
    {
    Sleep, 1000 ; critical delay needs to be long enough to activate Win search 
    SendInput, Web: %Clip% ; avoid adding {enter} user may wish to abort cliped
    }
}
return


~LButton:: ; ModSlct = Modify Single Click a word and alter to allow multiword selection
IfWinActive, ahk_class SUMATRA_PDF_FRAME 
{
  if ModSlct = true ; note initially false by default, change to = true in plus.ini 
     {
     ; msgbox ModSlct1 %ModSlct% ; for debugging only
     Click down
     }
  ;else
     ; msgbox ModSlct2 %ModSlct% ; for debugging only
  if ModLeft = true ; note initially false by default, change to = true in plus.ini 
     {
     ; msgbox ModLeft1 %ModLeft% ; for debugging only
     Click {esc}
     Click down Right ; hold right key down (needs another right click to release)
     }
  else
     {
     ; msgbox ModLeft2 %ModLeft% ; for debugging only
     return
     }
}
return ; outside SumatraPDF
msgbox Left Button Error, I should never be here
return

; lets hook Alt + i to get current filename details (reserved for future use)
!i::
SendInput, ^d
Sleep, 50 ; critical delay needs to be big enough to activate properties window
IfWinActive, ahk_class SUMATRA_PDF_PROPERTIES
  {
  ;msgbox Alt I
  gosub GetClip
  sendinput {esc}
  msgbox %Clip%
  }
return


RunArg1:
RunArg2:
RunArg3:
RunArg4:
RunArgL = %A_ThisLabel%
gosub GetClip
if RunArgL = RunArg1
   Run "%RunCmd1%" "%RunArg1%%Clip%"
if RunArgL = RunArg2
   Run "%RunCmd2%" "%RunArg2%%Clip%"
if RunArgL = RunArg3
   Run "%RunCmd3%" "%RunArg3%%Clip%"
if RunArgL = RunArg4
   Run "%RunCmd4%" "%RunArg4%%Clip%"
return


GetClip:
ClipSaved := ClipboardAll ; Save current clipboard
Clipboard := ""  ; and clear
SendInput ^c     ; copy selected object this can be text or an area with text
ClipWait, 2.0             ; seconds NOTE can be a tricky value to define per PC
Clip=%Clipboard%          ; Store current selection from Clipboard to Clip
Clipboard := ClipSaved    ; Restore original Clipboard (NOT ClipboardAll).
ClipSaved := ""           ; Free memory in case the saved Clip was very large
Return
