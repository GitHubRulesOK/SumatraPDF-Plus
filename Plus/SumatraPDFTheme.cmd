@echo off & Title SumatraPDF Theme Switcher Version 2026-08-31-01
goto MAIN

:README.txt
This CMD file compiles embedded C# code to switch SumatraPDF standard 3.6+ Themes.
It allows for portable or standard SumatraPDF.exe using %localappdata%. Adjust use accordingly.
First run compiles the .cs file into .exe. For subsequent runs execute the tool itself.

It is more a Proof of concept as SumatraPDF has many related command line options, however, no
 specific -Theme setting (Still Work In Progress) so to set as fixed this is an example.

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

class SumatraPDFThemeSwitcher
{
    static void Main(string[] args)
    {
        bool silent = false;
        string folderPath = "";
        string themeName = "";

        // Parse arguments
        foreach (string arg in args)
        {
            string lower = arg.ToLower();
            if (lower == "-silent") silent = true;
            else if (lower == "-help" || lower == "/?")
            {
                Console.WriteLine("Usage: SumatraPDFTheme.exe [-silent] \"SettingsFolder\" [ Dark | \"Dark from 3.5\" | Darker | \"Dark background Bright text\" | Light | \"Solarized Light\" ]");
                return;
            }
            else if (folderPath == "") folderPath = CleanPath(arg);
            else if (themeName == "") themeName = CleanQuotes(arg);
        }
        if (folderPath == "" || themeName == "")
        {
            Console.Error.WriteLine("Error: Missing folder path or theme name.");
            return;
        }
        string settingsFile = Path.Combine(folderPath, "SumatraPDF-settings.txt");

        if (!Directory.Exists(folderPath))
        {
            Console.Error.WriteLine("Error: Folder not found: " + folderPath);
            return;
        }
        if (!File.Exists(settingsFile))
        {
            Console.Error.WriteLine("Error: SumatraPDF-settings.txt not found in: " + folderPath);
            return;
        }
        string[] lines = File.ReadAllLines(settingsFile);
        bool found = false;
        for (int i = 0; i < lines.Length; i++)
        {
            if (lines[i].StartsWith("Theme ="))
            {
                lines[i] = "Theme = " + themeName;
                found = true;
                break;
            }
        }
        if (found)
        {
            File.WriteAllLines(settingsFile, lines);
            if (!silent)
            {
                Console.WriteLine("Theme changed to: " + themeName);
            }
        }
        else
        {
            Console.Error.WriteLine("Error: Theme line not found in settings file.");
        }
    }
    static string CleanPath(string raw)
    {
        return string.IsNullOrEmpty(raw) ? "" : raw.Replace("“", "").Replace("”", "").Replace("\"", "").Trim();
    }
    static string CleanQuotes(string raw)
    {
        return string.IsNullOrEmpty(raw) ? "" : raw.Replace("“", "").Replace("”", "").Replace("\"", "").Trim();
    }
}
