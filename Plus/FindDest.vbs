'This script is Designed as a "Plus" addin for SumatraPDF to aid with SEARCH entry in outline / bookmarks
'It can be used for "Drag'n'Drop" a PDF on FindDest.VBS or for ExternalViewers expansion in advanced settings
' IMPORTANT In the example CommandLine below ensure the location of the VBS is changed to your own location 
'ExternalViewers [
'	[
'		CommandLine = "C:\Users\user name\AppData\Local\SumatraPDF\plus\FindDest.vbs" "%1"
'		Name = &Search
'		Filter = *.*
'		Key = S
'	]
']
'
'
'Above lines that start with ' are comments that can be deleted in a working copy

Dim sh, file, page, dest
Set sh = CreateObject("WScript.Shell")
file = WScript.Arguments(0)
If WScript.Arguments.Count > 1 Then page = WScript.Arguments(1)
dest = InputBox("Enter destination name", "Go to destination")
sh.Run """C:\Program Files\SumatraPDF\SumatraPDF.exe"" -reuse-instance -named-dest """ & dest & """ """ & file & """"