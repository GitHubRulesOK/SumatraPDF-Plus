/*&cls&@echo off&Title "%~dpnx0" & REM SEE // COLOUR SWATCHES near end of file if you wish to make changes before running this file
REM ALSO you need to define the // ================== // USER CUSTOMISATION // ================== to point to your SumatraPDF.exe

cd /d "%~dp0" & echo Compiling "%~dpn0.exe"
set "CSC=%SystemRoot%\Microsoft.NET\Framework\v4.0.30319\csc.exe"
if not exist "%CSC%" echo Compiler not found & pause & exit /b

::Prepare the Icon/BMP/ICO/PNG graphics as a 24 px X 24 px RAW PNG.Base64
>icon.b64 echo iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAMAAADXqc3KAAAAElBMVEX///8AAAAApTDrAAgAgP//8gDwOARIAAAABHRSTlMAgN3jXzN1igAAAAlwSFlzAAAOxAAADsQBlSsOGwAAAEFJREFUKM/NyzEOgEAQw0Dnsvz/y3QUaC1R4nKiwNca8e5L2ybi50T8vD+Pz0R85seOOeZEHCIOEYcsfi2Z+4J3A7KHAyA8jREsAAAAAElFTkSuQmCC
::Convert first into an App.ico and keep base64 for internal conversion
>makeico.cs echo using System; using System.IO; class M { static void Main() {
>>makeico.cs echo var p = Convert.FromBase64String(File.ReadAllText("icon.b64")); using (var f = File.Create("app.ico")) { f.Write(new byte[]{0,0,1,0,1,0,24,24,0,0,1,0,32,0},0,14); W(f,p.Length); W(f,22); f.Write(p,0,p.Length); } } static void W(Stream s,int v){s.WriteByte((byte)v);s.WriteByte((byte)(v^>^>8));s.WriteByte((byte)(v^>^>16));s.WriteByte((byte)(v^>^>24)); } }
"%CSC%" /nologo makeico.cs && makeico.exe && del makeico.cs makeico.exe
:: The app.ico AND Title icon.b64 can now be used by main compilation

"%CSC%"  /nologo /target:winexe /win32icon:app.ico /resource:icon.b64 /platform:x86 /out:"%~dpn0.exe" "%~dpnx0"
rem not needed here ? /reference:System.dll /reference:System.Drawing.dll /reference:System.Windows.Forms.dll
REM TODO is add the icon as the c# resource like others do

:: It should now be safe to delete the temporary graphics
del app.ico icon.b64

REM IMPORTANT we must pause and exit here before NOTES
pause & exit /b

NOTES:
 This Hybrid file is a working demonstration of SumatraPDF Plugin Floating Toolbar it compiles to an exe that can simply provide an ink colour choice.

 You may use this concept many other ways, but this is simply a demonstration for Windows 7+!

Simply bind the compiled exe to a shortcut in SumatraPDF settings.
Like this: you can change the name for several sets so for example save rename to Brushes1.exe
ExternalViewers [
	[
		CommandLine = "C:\path to your version\Brushes1.exe"
		Name = User Ink Toolbar
		Filter = *.pdf
		Key = b
		ToolbarText = B1
		ToolbarSvgIcon = <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"> STILL TO DO </svg>
	]
]

example Brush.exe - Pick BrushInk Color

   1. Adjust Brush width (1-30)
   2. Status says "Select colour to apply"
   3. Select a colour from swatch
   4. C# sends: SumatraPDF -dde  "[CmdNone][CmdCreateAnnotInk COLOUR Borderwidth WIDTH]"
   5. SumatraPDF receives the Ink command.

*/
using System; using System.Drawing; using System.Runtime.InteropServices; using System.Windows.Forms;
namespace PicColoB
{
    // JavaScript -> C# bridge
    [ComVisible(true)]
    public class ScriptBridge
    {
        private MainForm form;
        public ScriptBridge(MainForm form) { this.form = form; }
        public void pick(string colour, int width) { form.SetInk(colour, width); }
        public void closeWindow()
        {
            form.Close();
        }
    }
    // Main Form
    public class MainForm : Form
    {
// ==================
// USER CUSTOMISATION
// ==================
// Path to the SumatraPDF.exe to control.
//
// Examples:
// My 32bit relative folder : @"x32\SumatraPDF.exe";
// others may be 
// @"C:\Tools\SumatraPDF\SumatraPDF.exe";
// @"D:\Portable\SumatraPDF.exe";
// Set default to 
// @"C:\Program Files\SumatraPDF\SumatraPDF.exe";

private const string SumatraExe = @"C:\Program Files\SumatraPDF\SumatraPDF.exe";

        private WebBrowser browser;
        public MainForm()
        {
            Text = "PicColoB"; TopMost = true; FormBorderStyle = FormBorderStyle.FixedToolWindow;
            MaximizeBox = false; MinimizeBox = false;
            StartPosition = FormStartPosition.CenterScreen;
            // Compact POC window.
            ClientSize = new Size(330, 125);
            browser = new WebBrowser();
            browser.Dock = DockStyle.Fill;
            browser.AllowWebBrowserDrop = false;
            browser.IsWebBrowserContextMenuEnabled = false;
            browser.WebBrowserShortcutsEnabled = true;
            browser.ObjectForScripting = new ScriptBridge(this);
            Controls.Add(browser);
            browser.DocumentText = Html;
        }
        // Brush as Ink
        public void SetInk(string colour, int width)
        {
            if (width < 1) width = 1; if (width > 30) width = 30;
            string exe = SumatraExe;
            if (!System.IO.Path.IsPathRooted(exe)) {exe = System.IO.Path.Combine(Application.StartupPath,exe); }
            // Explicitly terminate/reset the previous command before initiating a new Ink command.
            string command = "[CmdNone][CmdCreateAnnotInk " + colour + " Borderwidth " +  width.ToString() + "]";
            string arguments = " -dde \"" + command + "\"";
            try
            {
                System.Diagnostics.Process.Start(
                    new System.Diagnostics.ProcessStartInfo
                    {
                        FileName = exe,
                        Arguments = arguments,
                        UseShellExecute = false,
                        CreateNoWindow = true,
                        WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden
                    });
                SetStatus( "Color chosen is " + colour + "   width " + width.ToString());
            }
            catch (Exception ex)
            {
                MessageBox.Show("Could not call SumatraPDF:\n\n" + exe + "\n\n" + ex.Message, "PicColoB", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
        // Update status in HTML
        public void SetStatus(string text)
        {
            if (browser.Document == null) return;
            try { browser.Document.InvokeScript("setStatus", new object[] { text }); }
            catch { }
        }
        // Embedded HTML
        private const string Html = @"
<!DOCTYPE html><html><head><meta http-equiv=""X-UA-Compatible"" content=""IE=edge"">
<style>
/* ------------
   BASIC WINDOW
   --------- */
html, body { margin: 0; padding: 0; background: #202020; color: white; font-family: Segoe UI, Arial, sans-serif; overflow: hidden; }
#title {padding-left: 9px; height: 20px; line-height: 20px; background: #303030; font-size: 14px; font-weight: bold; }
#controls {padding-left: 9px; font-size: 14px; height: 36px;}
#widthLabel {vertical-align: top; padding-top: 12px; display: inline-block; width: 80px; color: #cccccc;}
#width {vertical-align: top; width: 200px;}
#widthValue {vertical-align: top; padding-top: 12px; display: inline-block; width: 20px; text-align: right; color: white; font-weight: bold; }
#status {padding-left: 9px; height: 16px; line-height: 16px; background: #111111; color: #d8b86a; font-size: 14px; }
#palette {padding-left: 9px; padding-top: 9px; display: flex; width: 315px; }
.colour {border-radius: 50%; width: 31px; height: 31px; margin-right: 4px; border: 2px solid #555555; box-sizing: border-box; cursor: pointer; }
.colour:hover { border-color: white; }
.colour.selected { border: 3px solid white; outline: 2px solid black; }
</style>

<script>
var brushWidth = 10;
var selectedColour = '#600000ff'; // initially we use blue as a default but you can use any 
var selectedElement = null;
// INITIALISE
function init()
{
    selectedElement = document.getElementById('default');
    if (selectedElement) { selectedElement.className = 'colour selected'; }
    updateWidth(document.getElementById('width').value, true );
}
// WIDTH
function updateWidth(value, initial)
{
    brushWidth = parseInt(value, 10);
    if (isNaN(brushWidth)) brushWidth = 10;
    document.getElementById('widthValue').innerText = brushWidth;
    // Moving the slider DOES NOT invoke SumatraPDF. It changes pending state only.
    if (!initial) { setStatus('Width changed — select colour to apply'); }
}
// COLOUR
function pick(element, hex)
{
    if (selectedElement) { selectedElement.className = 'colour'; }
    selectedElement = element;
    selectedElement.className = 'colour selected';
    selectedColour = hex;
    window.external.pick( selectedColour, brushWidth );
}
// STATE
function setStatus(text) {document.getElementById('status').innerText = text;}
</script>
</head><body onload=""init()"">
<div id=""title""> PicColo - Brush as Ink</div>
<div id=""controls"">
  <span id=""widthLabel"">Brush width</span>
  <input id=""width"" type=""range"" min=""1"" max=""30"" value=""10""
     oninput=""updateWidth(this.value, false)""
     onchange=""updateWidth(this.value, false)"">
  <span id=""widthValue"">10</span>
</div>
<div id=""status"">Select colour to apply</div>
<!-- ===============
     COLOUR SWATCHES Note: #60 is a reasonable alpha but change to desire. Blue (3) is the ""default"" but can be any
                           The visible background: colour does not have to match the applied (this, '#... colour)
     =========== -->
<div id=""palette"">
  <div id=""1"" class=""colour"" onclick=""pick(this, '#60ff0000')"" style=""background:#ff0000""></div>
  <div id=""2"" class=""colour"" onclick=""pick(this, '#6000ff00')"" style=""background:#00ff00""></div>
  <div id=""default""  class=""colour selected"" onclick=""pick(this, '#600000ff')"" style=""background:#0000ff""></div>
  <div id=""4"" class=""colour"" onclick=""pick(this, '#ffffff00')"" style=""background:#ffff00""></div>
  <div id=""5""  class=""colour"" onclick=""pick(this, '#60ff00ff')"" style=""background:#ff00ff""></div>
  <div id=""6"" class=""colour"" onclick=""pick(this, '#6000ffff')"" style=""background:#00ffff""></div>
  <div id=""7"" class=""colour"" onclick=""pick(this, '#80000000')"" style=""background:#808080""></div>
  <div id=""8"" class=""colour"" onclick=""pick(this, '#80808080')"" style=""background:#c0c0c0""></div>
  <div id=""9"" class=""colour"" onclick=""pick(this, '#60ff8000')"" style=""background:#ff8000""></div>
</div>
</body></html>
";
    }
    // Program
    internal static class Program
    {
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles(); Application.SetCompatibleTextRenderingDefault(false); Application.Run(new MainForm());
        }
    }
}
