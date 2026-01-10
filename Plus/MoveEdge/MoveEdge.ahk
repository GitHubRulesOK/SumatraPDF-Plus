#SingleInstance Force
; Show usage if no args
if (A_Args.Length = 0) {
 MsgBox "Usage:`n" A_ScriptName " `[options -x -y -w -h`] URL"
 ExitApp
}
params := Map(), url := A_Args[A_Args.Length]
i := 1
while i < A_Args.Length {
 if RegExMatch(A_Args[i], "^-([xywh])$", &m) {
  params[m[1]] := Integer(A_Args[i+1])
  i += 2
 } else i++
}
x:=params.Has("x")?params["x"]:0, y:=params.Has("y")?params["y"]:0, w:=params.Has("w")?params["w"]:800, h:=params.Has("h")?params["h"]:600
before := WinGetList("ahk_exe msedge.exe")
Run('msedge.exe --app="' url '"')
newHwnd := 0
Loop {
 Sleep(50)
 after := WinGetList("ahk_exe msedge.exe")
 for hwnd in after
  if !IsIn(before, hwnd) {
   newHwnd := hwnd
   break
  }
 if newHwnd
 break
}
WinMove(x, y, w, h, newHwnd)
IsIn(list, v) {
 for x in list
  if x = v
  return true
 return false
}