Option Explicit

Function StartsWith(s, prefix)
    If Len(s) < Len(prefix) Then
        StartsWith = False
    Else
        StartsWith = (Left(s, Len(prefix)) = prefix)
    End If
End Function

Dim fso
Set fso = CreateObject("Scripting.FileSystemObject")
Dim inStream, outStream
Dim inputFile, outputFile
Dim text, rawLines, lines()
Dim i, j, k, startIdx, endIdx
Dim blockHasFilePath, blockFilePath, deleteBlock

inputFile  = "SumatraPDF-settings-backup.txt"
outputFile = "SumatraPDF-settings.txt"

' If a previous backup exists, delete it
If fso.FileExists(inputFile) Then fso.DeleteFile inputFile, True

' Rename outputFile → backup
If fso.FileExists(outputFile) Then
    fso.MoveFile outputFile, inputFile
End If

' Read file as UTF-8
Set inStream = CreateObject("ADODB.Stream")
inStream.Type = 2
inStream.Charset = "utf-8"
inStream.Open
inStream.LoadFromFile inputFile
text = inStream.ReadText(-1)
inStream.Close

' Split into lines keeping CRLF
rawLines = Split(text, vbCrLf)
ReDim lines(UBound(rawLines))
For i = 0 To UBound(rawLines)
    lines(i) = rawLines(i)
Next

Dim deleteFlags()
ReDim deleteFlags(UBound(lines))

i = 0
Do While i <= UBound(lines)

    ' Block start: exactly one tab then "["
    If StartsWith(lines(i), vbTab & "[") Then

        startIdx = i
        blockHasFilePath = False
        blockFilePath = ""
        deleteBlock = False

        ' Scan forward until matching end: exactly one tab then "]"
        For j = i + 1 To UBound(lines)

            ' FilePath line: exactly two tabs then "FilePath ="
            If StartsWith(lines(j), vbTab & vbTab & "FilePath =") Then
                blockHasFilePath = True
                blockFilePath = Trim(Mid(lines(j), Len(vbTab & vbTab & "FilePath =") + 1))
            End If

            ' End of this block: exactly one tab then "]"
            If StartsWith(lines(j), vbTab & "]") Then
                endIdx = j
                Exit For
            End If
        Next

        ' Delete only if FilePath exists in block and file is missing
        If blockHasFilePath Then
            If blockFilePath <> "" And Not fso.FileExists(blockFilePath) Then
                deleteBlock = True
            End If
        End If

        If deleteBlock Then
            For k = startIdx To endIdx
                deleteFlags(k) = True
            Next
        End If

        i = endIdx + 1
    Else
        i = i + 1
    End If
Loop

' Write output exactly as read
Set outStream = CreateObject("ADODB.Stream")
outStream.Type = 2
outStream.Charset = "utf-8"
outStream.Open

For i = 0 To UBound(lines)
    If Not deleteFlags(i) Then
        outStream.WriteText lines(i), 1
    End If
Next

outStream.SaveToFile outputFile, 2
outStream.Close
