'This script is Designed as a "Plus" addin for SumatraPDF to aid with SEARCH entry
'It can be used for "Drag'n'Drop" a PDF on Finder.VBS or for ExternalViewers expansion in advanced settings
' IMPORTANT In the example CommandLine below ensure the location of the VBS is changed to your own location 
'ExternalViewers [
'	[
'		CommandLine = "C:\Users\user name\AppData\Local\SumatraPDF\plus\Finder.vbs" "%1"
'		Name = &Search
'		Filter = *.*
'		Key = S
'	]
']
'
'you can also add in pre-release a Menu Shortcut
'
'Shortcuts [
'	[
'		Cmd = CmdFindNextSel
'		Key = s
'		ToolbarText = Find>
'	]
']
'
'Above lines that start with ' are comments that can be deleted in a working copy

Dim objShell,strMessage
Set objArgs = Wscript.Arguments
Set objShell = WScript.CreateObject("WScript.Shell")
strMessage =Inputbox("Enter String","Find Word(s)")
objShell.Run("""C:\Program Files\SumatraPDF\SumatraPDF.exe""" & " -reuse-instance -search " & """" & strMessage & """" & " " & """" & WScript.Arguments(0) & """")
