@echo off & Title SumatraPDF Invert On Version 2026-08-31-01
goto MAIN

:README.txt
This CMD file compiles embedded C# code to switch SumatraPDF toggle to On (True).
It is set for a standard SumatraPDF.exe using %appdata%. Adjust paths accordingly.
First run compiles the .cs file into .exe. For subsequent runs execute the tool itself.

It is more a Proof of concept as SumatraPDF has many related command line options, however, no
 specific invert on or off (just toggle CmdInvertColors) so to set as fixed this is an example.

:MAIN
cd /d "%~dp0"
set "CSC=%SystemRoot%\Microsoft.NET\Framework\v4.0.30319\csc.exe"
if not exist "%CSC%" echo Compiler not found & pause & exit /b

REM Adjust line number to match :MORE-CS marker
set "MOREline#=25"
more +%MOREline#% "%~dpnx0" > "%temp%\%~n0.cs"

"%CSC%" /target:exe /out:"%~dpn0.exe" "%temp%\%~n0.cs" >nul
if exist "%~dpn0.exe" del "%temp%\%~n0.cs"
exit /b

:MORE-CS
using System;
using System.IO;

class InvertOn {
    static void Main(string[] args) {
        string iniPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "SumatraPDF", "SumatraPDF-settings.txt");
        if (!File.Exists(iniPath)) {
            Console.WriteLine("Settings file not found.");
            return;
        }

        string[] lines = File.ReadAllLines(iniPath);
        for (int i = 0; i < lines.Length; i++) {
            if (lines[i].StartsWith("\tInvertColors = false")) {
                lines[i] = "\tInvertColors = true"; // Example: switch InvertColors = false to true
            }
        }
        File.WriteAllLines(iniPath, lines);
        Console.WriteLine("InvertColors updated to on.");
    }
}
