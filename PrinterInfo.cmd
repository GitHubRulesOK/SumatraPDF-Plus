@echo off &Title PrinterInfo C# Compile file, Version 2025-11-20-03
goto MAIN
:README NOTES
Open Sourced from https://github.com/JensBejer/PrinterInformation/blob/main/PrinterInformation.
License Boost Software License - Version 1.0 - August 17th, 2003

This CMD file is designed to produce a Windows.net Native CSharp script for providing some basic printer information
The primary reason is to allow finding printer name and paperkind for use with SumatraPDF.

The first run will write this filename.cs file for compiling which "should" be converted into this filname.exe
Recommened filename for this command is PrinterInfo
Once you have the PrinterInfo.exe there is no need to run this source.cmd again but keep for adjustments.

Example use > PrinterInfo.cmd generates PrinterInfo.exe then run that same name again should show usage help.
:NOTES END
:MAIN
REM IMPORTANT THESE FOLLOWING LINES ARE CRITICAL TO FUNCTION exporting and compiling "C# Code" to PrinterInfo.exe
cd /d "%~dp0"
set "CSC=C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
if not exist "%csc%" echo cannot find "%csc%" & pause & exit /b

REM IMPORTANT the line number must be equal to the line containing :MORE-CS
set "MOREline#=32"
more +%moreLine#% "%~dpnx0" >"%~dpn0.cs"
"%csc%" "%~dpn0.cs" >nul
if exist "%~dpn0.exe" echo built "%~dpn0.cs"&echo   and "%~dpn0.exe"
@color 9F&timeout -1|set /p="Hello %userprofile:~9%, you may press any key to proceed..."&color
"%~dpn0.exe"
exit /b

SEE important note the MOREline number above must be equal to the NEXT LINE containing :MORE-CS
:MORE-CS
using System;
using System.Diagnostics;
using System.Drawing.Printing;
using System.Reflection;

namespace PrinterInformation
{
    class PrinterInformation
    {
        static void Main(string[] args)
        {
            if (args.Length == 0)
            {
                ShowHelp();
                return;
            }

            string command = args[0].Trim();

            if (command.Equals("-help", StringComparison.OrdinalIgnoreCase))
            {
                ShowHelp();
            }
            else if (command.Equals("-printers", StringComparison.OrdinalIgnoreCase))
            {
                ListPrinters();
            }
            else if (args.Length == 2 && command.StartsWith("-", StringComparison.Ordinal))
            {
                string printerName;
                if (TryGetPrinterName(args[1], out printerName))
                {
                    HandlePrinterCommand(command, printerName);
                }
                else
                {
                    Console.WriteLine(string.Format("The printer '{0}' is not available on '{1}'",
                        args[1], Environment.MachineName));
                }
            }
            else
            {
                ShowHelp();
            }

#if DEBUG
            Console.WriteLine("\nPress any key to continue...");
            Console.ReadKey();
#endif
        }

        private static void ListPrinters()
        {
            Console.WriteLine(string.Format("Printers on '{0}':", Environment.MachineName));
            if (PrinterSettings.InstalledPrinters.Count == 0)
            {
                Console.WriteLine("No printers found on this machine.");
                return;
            }

            foreach (string printer in PrinterSettings.InstalledPrinters)
            {
                Console.WriteLine(printer);
            }
        }

        private static bool TryGetPrinterName(string input, out string printerName)
        {
            foreach (string printer in PrinterSettings.InstalledPrinters)
            {
                if (printer.Equals(input, StringComparison.OrdinalIgnoreCase))
                {
                    printerName = printer;
                    return true;
                }
            }
            printerName = null;
            return false;
        }

        private static void HandlePrinterCommand(string command, string printerName)
        {
            try
            {
                PrintDocument pd = new PrintDocument();
                pd.PrinterSettings.PrinterName = printerName;

                if (!pd.PrinterSettings.IsValid)
                {
                    Console.WriteLine(string.Format("The printer settings for the printer '{0}' are not valid on '{1}'",
                        printerName, Environment.MachineName));
                    return;
                }

                if (command.Equals("-papers", StringComparison.OrdinalIgnoreCase))
                {
                    Console.WriteLine(string.Format("Paper definitions for the printer '{0}' on '{1}':",
                        printerName, Environment.MachineName));
                    Console.WriteLine("Paper Name                     Kind   Size in*in   Size mm*mm");

                    foreach (PaperSize papersize in pd.PrinterSettings.PaperSizes)
                    {
                        Console.WriteLine(string.Format("{0,-30} ({1}) ({2:N2} x {3:N2}) ({4:N2} x {5:N2})",
                            papersize.PaperName,
                            papersize.RawKind,
                            (double)papersize.Width / 100.0,
                            (double)papersize.Height / 100.0,
                            (double)papersize.Width * 25.4 / 100.0,
                            (double)papersize.Height * 25.4 / 100.0));
                    }
                }
                else if (command.Equals("-bins", StringComparison.OrdinalIgnoreCase))
                {
                    Console.WriteLine(string.Format("Paper source (bin) definitions for the printer '{0}' on '{1}':",
                        printerName, Environment.MachineName));
                    Console.WriteLine("Paper Source Name         Kind");

                    foreach (PaperSource papersource in pd.PrinterSettings.PaperSources)
                    {
                        Console.WriteLine(string.Format("{0,-30} ({1})", papersource.SourceName, papersource.RawKind));
                    }
                }
                else
                {
                    Console.WriteLine(string.Format("Unknown printer command: {0}", command));
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine(string.Format("Error accessing printer '{0}': {1}", printerName, ex.Message));
            }
        }

        static void ShowHelp()
        {
            Version appVersion = Assembly.GetExecutingAssembly().GetName().Version;
            string appName = Process.GetCurrentProcess().ProcessName;

            Console.WriteLine(string.Format("{0} Version {1}, {2}",
                appName, appVersion, DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff")));

            Console.WriteLine(string.Format("\nShow printer information for '{0}':\n", Environment.MachineName));
            Console.WriteLine(string.Format(" {0} -Help                  To get this help text.", appName));
            Console.WriteLine(string.Format(" {0} -Printers              To list all printer names.", appName));
            Console.WriteLine(string.Format(" {0} -Papers <PrinterName>  To list all paper definitions for the printer <PrinterName>.", appName));
            Console.WriteLine(string.Format(" {0} -Bins <PrinterName>    To list all paper source (bin) definitions for the printer <PrinterName>.", appName));
        }
    }
}
