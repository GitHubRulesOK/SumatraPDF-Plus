/*&cls&@echo off&Title SumatraGET
cd /d "%~dp0" & echo Compiling SumatraHTA.exe and SumatraGET.exe
set "CSC=%SystemRoot%\Microsoft.NET\Framework\v4.0.30319\csc.exe"
if not exist "%CSC%" echo Compiler not found & pause & exit /b
rem the folowing variation is not needed but the pair are easy to generate for comparative testing
"%CSC%" /nologo /target:winexe /platform:x86 /out:"SumatraHTA.exe" "%~dpnx0"
"%CSC%" /nologo /target:exe    /platform:x86 /out:"SumatraGET.exe" "%~dpnx0"
REM IMPORTANT we pause and exit here
pause & exit /b

NOTES:
This Hybrid file is a companion to SumatraDDE.hta's it compiles a pair of support files but only
SumatraHTA.exe was used by Measure.hta. That has now been replaced by a new one exe soloution.

The console version SumatraGET.exe is more for testing / cmd use. and now the prefered output

*/
using System;
using System.Runtime.InteropServices;
using System.Text;

class GetPos
{
    const int APPCLASS_STANDARD = 0x00000000;
    const int APPCMD_CLIENTONLY = 0x00000010;
    const int XTYP_REQUEST = 0x20B0;
    const int XCLASS_DATA  = 0x2000;
    const int CF_TEXT = 1;
    const int TIMEOUT = 5000;
    // ---------------- DDEML ----------------
    delegate IntPtr DdeCallback(int uType, int uFmt, IntPtr hConv, IntPtr hsz1, IntPtr hsz2, IntPtr hData, IntPtr dwData1, IntPtr dwData2);
    [DllImport("user32.dll", CharSet = CharSet.Ansi)]
    static extern int DdeInitializeA(out IntPtr pidInst, DdeCallback pfnCallback, int afCmd, int ulRes);
    [DllImport("user32.dll", CharSet = CharSet.Ansi)]
    static extern IntPtr DdeCreateStringHandleA(IntPtr idInst, string psz, int iCodePage);
    [DllImport("user32.dll")]
    static extern IntPtr DdeConnect(IntPtr idInst, IntPtr hszService, IntPtr hszTopic, IntPtr pCC);
    [DllImport("user32.dll")]
    static extern IntPtr DdeClientTransaction(byte[] pData, int cbData, IntPtr hConv, IntPtr hszItem, int wFmt, int wType, int dwTimeout, out int pdwResult);
    [DllImport("user32.dll")] static extern int DdeGetData(IntPtr hData, byte[] pDst, int cbMax, int cbOff);
    [DllImport("user32.dll")] static extern bool DdeDisconnect(IntPtr hConv);
    [DllImport("user32.dll")] static extern bool DdeFreeStringHandle(IntPtr idInst, IntPtr hsz);
    [DllImport("user32.dll")] static extern bool DdeUninitialize(IntPtr idInst);
    // ---------------------------------------------------------
    static IntPtr DdeCallbackProc(
        int uType, int uFmt, IntPtr hConv,
        IntPtr hsz1, IntPtr hsz2,
        IntPtr hData, IntPtr dwData1, IntPtr dwData2)
    {
        return IntPtr.Zero; // NO need ? to handle any callbacks for a simple client.
    }
    static void Main(string[] args)
    {
        // defaults to [GetMousePos], but any known string is accepted.
        string item = args.Length > 0 ? args[0] : "[GetMousePos]";
        IntPtr inst;
        int ret = DdeInitializeA( out inst, DdeCallbackProc, APPCLASS_STANDARD | APPCMD_CLIENTONLY, 0);
        if (ret != 0) { Console.WriteLine("DdeInitialize failed: " + ret); return; }
        IntPtr hszService = DdeCreateStringHandleA(inst, "SUMATRA", 1004);
        IntPtr hszTopic   = DdeCreateStringHandleA(inst, "control", 1004);
        IntPtr hszItem    = DdeCreateStringHandleA(inst, item, 1004);
        IntPtr hConv = DdeConnect(inst, hszService, hszTopic, IntPtr.Zero);
        if (hConv == IntPtr.Zero)
        {
            Console.WriteLine("DdeConnect failed.");
            DdeFreeStringHandle(inst, hszService);
            DdeFreeStringHandle(inst, hszTopic);
            DdeFreeStringHandle(inst, hszItem);
            DdeUninitialize(inst);
            return;
        }
        int result;
        IntPtr hData = DdeClientTransaction( null, 0, hConv, hszItem, CF_TEXT, XTYP_REQUEST, TIMEOUT, out result);
        if (hData == IntPtr.Zero)
        {
            Console.WriteLine("Request failed.");
            DdeDisconnect(hConv);
            DdeFreeStringHandle(inst, hszService);
            DdeFreeStringHandle(inst, hszTopic);
            DdeFreeStringHandle(inst, hszItem);
            DdeUninitialize(inst);
            return;
        }
        int size = DdeGetData(hData, null, 0, 0);
        byte[] buffer = new byte[size];
        DdeGetData(hData, buffer, size, 0);
        string reply = Encoding.ASCII.GetString(buffer).TrimEnd('\0');
        Console.WriteLine(reply);
        DdeDisconnect(hConv);
        DdeFreeStringHandle(inst, hszService);
        DdeFreeStringHandle(inst, hszTopic);
        DdeFreeStringHandle(inst, hszItem);
        DdeUninitialize(inst);
    }
}
