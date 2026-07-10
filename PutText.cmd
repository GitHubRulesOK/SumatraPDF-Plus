/*&cls&@echo off&Title PutText & REM SEE // IMPORTANT NOTE: BELOW about file locations before running this file

cd /d "%~dp0" & echo Compiling PutText.exe
set "CSC=%SystemRoot%\Microsoft.NET\Framework\v4.0.30319\csc.exe"
if not exist "%CSC%" echo Compiler not found & pause & exit /b

::Prepare the Icon/BMP/ICO/PNG graphics as a 24 px X 24 px RAW PNG.Base64
>icon.b64 echo iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAACXBIWXMAAA7EAAAOxAGVKw4bAAAA50lEQVRIibWVTQvDIAyGX0d2SP/wDh1oYTvsDxdv2cHZOb9WJL5QlDTkyYeoYYJgoggA9nVO8OX5AQCA2XSDiw0r/RhFp1vMDMCXAKCsRGywxYzivlZx9PHeH7YCkDr22pYDW6oCNOfRrWAaoKbhqpggYiEAREtAiMkE+XuKgHMtaw37UgsWHePebN8vTaK1dgEt5dmlwdKEhgFnAw4D0tb1WjIMSGcQgTWfwsYE2dfw0zl3lteVcw5is+uaCXg9dACcHP5jO+vRMbOfTJM/MsvVyL6G/t3ubi5AQ83bVGsm1Qp0Qge9ARS+qUk3M9ZVAAAAAElFTkSuQmCC
::Convert first into an App.ico and keep base64 for internal conversion
>makeico.cs echo using System; using System.IO; class M { static void Main() {
>>makeico.cs echo var p = Convert.FromBase64String(File.ReadAllText("icon.b64")); using (var f = File.Create("app.ico")) { f.Write(new byte[]{0,0,1,0,1,0,24,24,0,0,1,0,32,0},0,14); W(f,p.Length); W(f,22); f.Write(p,0,p.Length); } } static void W(Stream s,int v){s.WriteByte((byte)v);s.WriteByte((byte)(v^>^>8));s.WriteByte((byte)(v^>^>16));s.WriteByte((byte)(v^>^>24)); } }
"%CSC%" /nologo makeico.cs && makeico.exe && del makeico.cs makeico.exe
:: The app.ico AND Title icon.b64 can now be used by main compilation

"%CSC%"  /nologo /target:winexe /win32icon:app.ico /resource:icon.b64 /platform:x86 /out:"%~dpn0.exe" "%~dpnx0"
REM this is the debug console variation > "%CSC%" /nologo /target:exe /win32icon:app.ico /resource:icon.b64 /platform:x86 /out:"%~dpn0-dbg.exe" "%~dpnx0"

:: It should now be safe to delete the temporary graphics
del app.ico icon.b64

REM IMPORTANT we must pause and exit here before NOTES
pause & exit /b

NOTES:
 This Hybrid file is a working demonstration of SumatraPDF DDE [Get...] it compiles to an exe that can place text 
 using a tools script. It has a dependency on https://github.com/GitHubRulesOK/SumatraPDF-Plus/blob/master/Scripts/AddOverlay.js

 You may use this concept many other ways but the one thing you may be suprised at, is how that script applies rotation!
 The tests have not been extensive so can behave oddly with some PDF file types or odd text thus it is not guaranteed!

 Beware trying to view larger files may
 suffer "blocking" or mis-timings so there is an optional switch lower right but for now, is default ON.

Simply bind the compiled exe to a shortcut in SumatraPDF settings. Like this:
ExternalViewers [
	[
		CommandLine = C:\path to your version\PutText.exe
		Name = Put &Text Overlay
		Key = t
		ToolbarSvgIcon = <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"><rect width="24" height="24" fill="#fd1"/><rect x="4.5" y="19.5" width="20" height="4" stroke="#000" stroke-width="1" fill="#f81"/><rect x="6.5" y="19.5" width="20" height="2" stroke="#000" stroke-width="1" fill="#999"/><rect x="1" y="1" width="22" height="18.5" stroke="#000" stroke-width="1" fill="#f81"/><rect x="3" y="3" width="18" height="14.5" stroke="#000" stroke-width="1" fill="#fff"/><text x="4" y="10" font-size="8" font-family="sans-serif" fill="#00f">PUT</text><text x="4" y="16.5" font-size="8" font-family="sans-serif" fill="#00f">Text</text></svg>
	]
]

*/
using System; using System.IO; using System.Runtime.InteropServices; using System.Text;
using System.Windows.Forms; using System.Drawing; using System.Threading; using System.Reflection;

class Program
{
    			// IMPORTANT NOTE: ALTER THESE TO YOUR OWN FILE LOCATIONS BEFORE BUILD

    public const string TOOL_PATH   = @"C:\Program Files\SumatraPDF\sumatrapdf-tool.exe";
    public const string SCRIPT_PATH = @"C:\Users\ your path to \plus\addoverlay.js";
    public const string VIEWER_PATH = @"C:\Program Files\SumatraPDF\SumatraPDF.exe";

    [STAThread]
    static void Main(string[] args)
    {
    // STARTUP GUARD
    if (!File.Exists(TOOL_PATH))
    {
        MessageBox.Show("SumatraPDF/MuPDF tool not found:\n" + TOOL_PATH, "Missing Tool", MessageBoxButtons.OK, MessageBoxIcon.Error); return;
    }
    if (!File.Exists(SCRIPT_PATH))
    {
        MessageBox.Show("Overlay script not found:\n" + SCRIPT_PATH + "\n\nEdit the paths at the top of the CMD file before re-compiling.",
            "Missing Script", MessageBoxButtons.OK, MessageBoxIcon.Error); return;
    }
    // VIEWER_PATH is optional remove this section if you dont want checking it exists
    if (!File.Exists(VIEWER_PATH))
    {   MessageBox.Show("Viewer not found:\n" + VIEWER_PATH, "Missing Viewer", MessageBoxButtons.OK, MessageBoxIcon.Warning); }
    // Continue to launch
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new TextForm());
    }
}

public class TextForm : Form
{
    public const int WM_NCLBUTTONDOWN = 0xA1; public const int HTCAPTION = 0x2;
    [DllImport("user32.dll")] public static extern bool ReleaseCapture();
    [DllImport("user32.dll")] public static extern int SendMessage(IntPtr hWnd, int Msg, int wParam, int lParam);
    private TextBox txtText; private TextBox txtFont; private TextBox txtR; private TextBox txtOutput;
    private CheckBox chkOpen; //private CheckBox chkTopY;
    private Button btnGetOut; private Button btnPut;
    private bool armed = false;
    private Panel dragBar; private Label title;
    private TextBox txtColorR; private TextBox txtColorG; private TextBox txtColorB; private TextBox txtAlpha; private TextBox txtOffsetX; private TextBox txtOffsetY;
    private ComboBox txtFontName;

    public TextForm()
    {
    // READ the external icon.b64 convert and embed it replacing any internal methods
    var asm = Assembly.GetExecutingAssembly(); Image icon; using (var s = asm.GetManifestResourceStream("icon.b64"))
    using (var r = new StreamReader(s)) { byte[] png = Convert.FromBase64String(r.ReadToEnd()); using (var ms = new MemoryStream(png)) icon = Image.FromStream(ms); }
    using (var bmp = new Bitmap(icon)) this.Icon = Icon.FromHandle(bmp.GetHicon());

        this.FormBorderStyle = FormBorderStyle.None; this.TopMost = true; this.StartPosition = FormStartPosition.CenterScreen;
        this.BackColor = Color.FromArgb(30, 30, 30); this.ForeColor = Color.White; // this.Opacity = 0.70;
        this.Size = new Size(460, 260); this.Font = new Font("Segoe UI", 12, FontStyle.Regular);
        // Check DDE probe
        string reply = DdeClient.Request("[GetFileState()]");
        if (reply == null)
        {
            MessageBox.Show(
            "SumatraPDF may be active but currently\n there is no DDE reply channel.\n" +
            "This simply means current state of SumatraPDF\n" +
            "does not provide a DDE context yet. You may be able to use\nDDE after making changes.",
            "No DDE Channel", MessageBoxButtons.OK, MessageBoxIcon.Information
            );
        // Continue NOT exit
        }

        // DRAG BAR and ARMING NOTIFICATION AREA
        dragBar = new Panel(); dragBar.Left = 0; dragBar.Top = 0; dragBar.Width = this.Width; dragBar.Height = 28; dragBar.BackColor = Color.FromArgb(50,50,50);
        this.Controls.Add(dragBar);
        PictureBox pic = new PictureBox { Image = icon, Size = new Size(28, 28), Location = new Point(0, 0), BackColor = Color.FromArgb(255, 201, 15), SizeMode = PictureBoxSizeMode.CenterImage };
        pic.MouseDown += (s, e) => {
        if (e.Button == MouseButtons.Left) { ReleaseCapture(); SendMessage(this.Handle, WM_NCLBUTTONDOWN, HTCAPTION, 0); } };
        dragBar.Controls.Add(pic);
        title = new Label(); title.Text = "Put Text Overlay Tool";
        title.ForeColor = Color.White; title.BackColor = Color.Transparent; title.Left = 30; title.Top = 4; title.Width = 390;
        title.MouseDown += (s, e) => {
        if (e.Button == MouseButtons.Left) { ReleaseCapture(); SendMessage(this.Handle, WM_NCLBUTTONDOWN, HTCAPTION, 0); } };
        dragBar.Controls.Add(title);
        // CLOSE BUTTON
        Label btnX = new Label() {
        Text = "X", Font = new Font("Segoe UI", 15, FontStyle.Bold), Top = 0, Left = this.Width - 30, Width = 30, Height = 30,
        ForeColor = Color.White, BackColor = Color.FromArgb(60,60,60), TextAlign = ContentAlignment.TopCenter};
        btnX.MouseEnter += (s, e) => btnX.BackColor = Color.FromArgb(200, 50, 50); btnX.MouseLeave += (s, e) => btnX.BackColor = Color.FromArgb(50, 50, 50); 
        btnX.Click += (s, e) => Close();
        dragBar.Controls.Add(btnX);

        int y = 30;
        this.StartPosition = FormStartPosition.CenterScreen;
        // TEXT INPUT
        Label lblText = new Label(); lblText.Text = "Text (\\n):"; lblText.Left = 8; lblText.Top = y + 3; lblText.Width = 75;
        this.Controls.Add(lblText); 
        txtText = new TextBox(); txtText.Left = 85; txtText.Top = y; txtText.Width = 365; txtText.Height = 60; txtText.Multiline = true;
        txtText.BackColor = Color.FromArgb(45,45,45); txtText.ForeColor = Color.White;
        this.Controls.Add(txtText);

        y += 70;
        // FONT SIZE
        Label lblFont = new Label(); lblFont.Text = "Font (pt):"; lblFont.Left = 8; lblFont.Top = y + 3; lblFont.Width = 75;
        this.Controls.Add(lblFont); 
        txtFont = new TextBox(); txtFont.Left = 85; txtFont.Top = y; txtFont.Width = 55; txtFont.Text = "12";
        txtFont.BackColor = Color.FromArgb(45,45,45); txtFont.ForeColor = Color.White;
        this.Controls.Add(txtFont);

        txtFontName = new ComboBox(); this.txtFontName.DropDownStyle = ComboBoxStyle.DropDownList;
        txtFontName.Location = new Point(160, y); this.txtFontName.Size = new Size(200, 21);
        txtFontName.Items.AddRange(new object[] {
            "Helvetica", "Helvetica-Bold", "Helvetica-Oblique", "Helvetica-BoldOblique", "Times-Roman", "Times-Bold", "Times-Italic", "Times-BoldItalic",
            "Courier", "Courier-Bold", "Courier-Oblique", "Courier-BoldOblique", "Symbol", "ZapfDingbats" });
        txtFontName.SelectedIndex = 0; // Helvetica
        this.Controls.Add(txtFontName);

        y += 36;
        // Colour R/G/B/A
        Label RGBA = new Label(); RGBA.Text = "RGB+A  0.00 - 1.00:"; RGBA.Left = 8; RGBA.Top = y + 3; RGBA.Width = 150; this.Controls.Add(RGBA);
        txtColorR = new TextBox(); txtColorR.Location = new Point(160, y); txtColorR.Size = new Size(40, 20); txtColorR.Text = "0.00"; this.Controls.Add(txtColorR);
        txtColorG = new TextBox(); txtColorG.Location = new Point(200, y); txtColorG.Size = new Size(40, 20); txtColorG.Text = "0.00"; this.Controls.Add(txtColorG);
        txtColorB = new TextBox(); txtColorB.Location = new Point(240, y); txtColorB.Size = new Size(40, 20); txtColorB.Text = "1.00"; this.Controls.Add(txtColorB);
        txtAlpha = new TextBox(); txtAlpha.Location = new Point(280, y); txtAlpha.Size = new Size(40, 20); txtAlpha.Text = "1.00"; this.Controls.Add(txtAlpha);
        // ROTATION
        Label lblR = new Label(); lblR.Text = "Rot (°):"; lblR.Left = 320; lblR.Top = y + 3; lblR.Width = 60;
        this.Controls.Add(lblR); 
        txtR = new TextBox(); txtR.Left = 380; txtR.Top = y; txtR.Width = 70; txtR.Text = "0";
        txtR.BackColor = Color.FromArgb(45,45,45); txtR.ForeColor = Color.White;
        this.Controls.Add(txtR);

        y += 36;
        // OUTPUT PDF
        Label lblOut = new Label(); lblOut.Text = "Output PDF:"; lblOut.Left = 8; lblOut.Top = y + 3; lblOut.Width = 100;
        this.Controls.Add(lblOut); 
        txtOutput = new TextBox(); txtOutput.Left = 110; txtOutput.Top = y; txtOutput.Width = 265;
        txtOutput.BackColor = Color.FromArgb(45,45,45); txtOutput.ForeColor = Color.White;
        this.Controls.Add(txtOutput); 
        btnGetOut = new Button(); btnGetOut.Text = "Browse"; btnGetOut.Left = 380; btnGetOut.Top = y - 1; btnGetOut.Width = 70; btnGetOut.Height = 30;
        btnGetOut.Click += OnGetOutput;
        this.Controls.Add(btnGetOut);

        y += 36;
        // GETPOS
        btnPut = new Button(); btnPut.Text = "Put Text"; btnPut.Left = 8; btnPut.Top = y; btnPut.Width = 100; btnPut.Height = 30;
        btnPut.Click += OnPut;
        this.Controls.Add(btnPut);
        // Offset X/Y
        Label lblToXY = new Label(); lblToXY.Text = "Move TL by X,Y:"; lblToXY.Left = 120; lblToXY.Top = y + 3; lblToXY.Width = 120; this.Controls.Add(lblToXY);
        txtOffsetX = new TextBox(); txtOffsetX.Location = new Point(240, y); txtOffsetX.Size = new Size(40, 20); txtOffsetX.Text = "-1"; this.Controls.Add(txtOffsetX);
        txtOffsetY = new TextBox(); txtOffsetY.Location = new Point(280, y); txtOffsetY.Size = new Size(40, 20); txtOffsetY.Text = "12";  this.Controls.Add(txtOffsetY);
        chkOpen = new CheckBox(); chkOpen.Left = 360; chkOpen.Top = y + 3; chkOpen.Width = 100; chkOpen.Text = "Try Open"; chkOpen.Checked = true;
        this.Controls.Add(chkOpen);

        this.Deactivate += OnLoseFocus;
    }

    private void OnGetOutput(object sender, EventArgs e)
    {
        using (SaveFileDialog sfd = new SaveFileDialog())
        {
            sfd.Filter = "PDF files|*.pdf"; if (sfd.ShowDialog() == DialogResult.OK)  txtOutput.Text = sfd.FileName;
        }
    }

    private void OnPut(object sender, EventArgs e)
    {
        armed = true;
        dragBar.BackColor = Color.FromArgb(240, 80, 20);
        title.Text = "ARMED - Text will be put @ click on the PDF in view";
    }

    private void OnLoseFocus(object sender, EventArgs e)
    {
        if (!armed)
            return;
        armed = false;
        dragBar.BackColor = Color.FromArgb(50, 50, 50);
        title.Text = "Put Text Overlay Tool";
        PerformDdeAndBuildCommand();
        if (chkOpen.Checked)
        {
            Thread.Sleep(1000);
            string outFile = txtOutput.Text;
            if (File.Exists(outFile))
            {
                long outSize = new FileInfo(outFile).Length;
                if (outSize < (32L * 1024 * 1024))
                {
                    string sumatra = Program.VIEWER_PATH;
                    string args = "-reuse-instance \"" + outFile + "\"";
                    RunHiddenCommand(sumatra, args, Path.GetDirectoryName(sumatra));
                }
            }
        }
    }

    private void PerformDdeAndBuildCommand()
    {
        string reply = DdeClient.Request("[GetFileState()][GetMousePos]");
        if (reply == null)
        {
            MessageBox.Show("DDE failed.", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return;
        }
        string path = ""; string page = ""; string x = ""; string ypdf = "";
        bool firstPageSeen = false;
        foreach (string raw in reply.Split('\n'))
        {
            string line = raw.Trim();
            if (line.StartsWith("path:")) path = line.Substring(5).Trim();
            else if (line.StartsWith("page:"))
            {
                string val = line.Substring(5).Trim();
                if (!firstPageSeen) { firstPageSeen = true; page = val; }
                else { page = val; }
            }
            else if (line.StartsWith("x:")) x = line.Substring(2).Trim();
            else if (line.StartsWith("ypdf:")) ypdf = line.Substring(5).Trim();
        }
        if (page == "0")
        {
            MessageBox.Show(
                "Click may be outside the PDF page.\n\nPlease click only on the visible page area.",
                "Invalid Click", MessageBoxButtons.OK, MessageBoxIcon.Warning
            );
            return;
        }
        if (path == "" || page == "" || x == "" || ypdf == "")
        {
            MessageBox.Show("Incomplete DDE data:\n" + reply, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return;
        }
        // Ensure the active document is a real PDF
        if (!path.EndsWith(".pdf", StringComparison.OrdinalIgnoreCase) || !File.Exists(path))
        {
            MessageBox.Show(
            "The active document is not a valid PDF file.\n\nPlease open a PDF in SumatraPDF before placing overlays.",
            "Invalid Document", MessageBoxButtons.OK, MessageBoxIcon.Warning
            );
            return;
        }
        if (string.IsNullOrWhiteSpace(txtOutput.Text))
        {
            string outPdf = Path.Combine(
                Path.GetDirectoryName(path),
                Path.GetFileNameWithoutExtension(path) + "-overlaid.pdf"
            );
            txtOutput.Text = outPdf;
        }
        string text = txtText.Text;
        string fontStr = txtFont.Text.Trim();
        string fontName = txtFontName.Text.Trim();
        string rStr = txtR.Text.Trim();
        string outPdfFinal = txtOutput.Text.Trim();
        double bw = 0;  // are these correct for overlay.js
        double bh = 2;  // are these correct for overlay.js should it be 1 ?
        double yVal = double.Parse(ypdf);
        ypdf = yVal.ToString();
        string textArg = text  .Replace("\r", "")  .Replace("\n", "\\n")  .Replace("\"", "\\\"");
        string colorR = txtColorR.Text.Trim();string colorG = txtColorG.Text.Trim();string colorB = txtColorB.Text.Trim();
        string toX   = txtOffsetX.Text.Trim();string toY   = txtOffsetY.Text.Trim();string alpha  = txtAlpha.Text.Trim();
        // NOTE: above bw & bh = 0,2 (Compensatory values for JS), may still need adjust 
        string exe = Program.TOOL_PATH;
        string args = string.Format(
            "run \"{0}\" -p={1} -t=\"{2}\" -b=\"{3},{4},{5},{6}\" -s={7} -f=\"{8}\" -c=[{9},{10},{11}] -to={12},{13} -ta={14} -r={15} -o=\"{16}\" \"{17}\"",
            Program.SCRIPT_PATH, page, textArg, x, ypdf, bw, bh, fontStr, fontName, colorR, colorG, colorB, toX, toY, alpha, rStr, outPdfFinal, path 
        );
        // Debugging needs a console otherwise this is in effect hidden
        Console.WriteLine("EXE=[" + exe + "]");
        Console.WriteLine("ARGS=[" + args + "]");
        RunHiddenCommand(exe, args, Path.GetDirectoryName(path));
    }

    private void RunHiddenCommand(string exePath, string arguments, string workingDir)
    {
        try
        {
            var psi = new System.Diagnostics.ProcessStartInfo();
            psi.FileName = exePath;
            psi.Arguments = arguments;
            psi.CreateNoWindow = true;
            psi.UseShellExecute = false;
            psi.WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden;
            psi.WorkingDirectory = workingDir;
            // Debugging needs a console otherwise this is in effect hidden
            Console.WriteLine("=== PROCESS CALL");
            Console.WriteLine("FileName=[" + psi.FileName + "]");
            Console.WriteLine("Arguments=[" + psi.Arguments + "]");
            Console.WriteLine("WorkingDirectory=[" + psi.WorkingDirectory + "]");
            Console.WriteLine("===");
            System.Diagnostics.Process.Start(psi);
        }
        catch (Exception ex)
        {
            MessageBox.Show("Failed to run command:\n" + ex.Message,
            "Execution Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }
// End Class
}

public static class DdeClient
{
    const int APPCLASS_STANDARD = 0x00000000;
    const int APPCMD_CLIENTONLY = 0x00000010;
    const int XTYP_REQUEST = 0x20B0; const int CF_UNICODETEXT = 13; const int TIMEOUT = 5000;
    delegate IntPtr DdeCallback(int uType, int uFmt, IntPtr hConv, IntPtr hsz1, IntPtr hsz2, IntPtr hData, IntPtr dwData1, IntPtr dwData2);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int DdeInitializeW(out IntPtr pidInst, DdeCallback pfnCallback, int afCmd, int ulRes);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern IntPtr DdeCreateStringHandleW(IntPtr idInst, string psz, int iCodePage);
    [DllImport("user32.dll")] static extern IntPtr DdeConnect(IntPtr idInst, IntPtr hszService, IntPtr hszTopic, IntPtr pCC);
    [DllImport("user32.dll")] static extern IntPtr DdeClientTransaction(byte[] pData, int cbData, IntPtr hConv, IntPtr hszItem, int wFmt, int wType, int dwTimeout, out int pdwResult);
    [DllImport("user32.dll")] static extern int DdeGetData(IntPtr hData, byte[] pDst, int cbMax, int cbOff);
    [DllImport("user32.dll")] static extern bool DdeDisconnect(IntPtr hConv);
    [DllImport("user32.dll")] static extern bool DdeFreeStringHandle(IntPtr idInst, IntPtr hsz);
    [DllImport("user32.dll")] static extern bool DdeUninitialize(IntPtr idInst);
    static IntPtr DdeCallbackProc(int uType, int uFmt, IntPtr hConv, IntPtr hsz1, IntPtr hsz2, IntPtr hData, IntPtr dwData1, IntPtr dwData2) { return IntPtr.Zero; }

    public static string Request(string item)
    {
        IntPtr inst;
        if (DdeInitializeW(out inst, DdeCallbackProc, APPCLASS_STANDARD | APPCMD_CLIENTONLY, 0) != 0) return null;
        IntPtr hszService = DdeCreateStringHandleW(inst, "SUMATRA", 1200);
        IntPtr hszTopic   = DdeCreateStringHandleW(inst, "control", 1200);
        IntPtr hszItem    = DdeCreateStringHandleW(inst, item, 1200);
        IntPtr hConv = DdeConnect(inst, hszService, hszTopic, IntPtr.Zero);
        if (hConv == IntPtr.Zero) { Cleanup(inst, hszService, hszTopic, hszItem); return null; }
        int result;
        IntPtr hData = DdeClientTransaction(null, 0, hConv, hszItem, CF_UNICODETEXT, XTYP_REQUEST, TIMEOUT, out result);
        if (hData == IntPtr.Zero) { DdeDisconnect(hConv); Cleanup(inst, hszService, hszTopic, hszItem); return null; }
        int size = DdeGetData(hData, null, 0, 0);
        byte[] buffer = new byte[size];
        DdeGetData(hData, buffer, size, 0);
        string reply = Encoding.Unicode.GetString(buffer).TrimEnd('\0');
        DdeDisconnect(hConv); Cleanup(inst, hszService, hszTopic, hszItem);
        return reply;
    }

    static void Cleanup(IntPtr inst, IntPtr hszService, IntPtr hszTopic, IntPtr hszItem)
    {
        DdeFreeStringHandle(inst, hszService); DdeFreeStringHandle(inst, hszTopic);
        DdeFreeStringHandle(inst, hszItem); DdeUninitialize(inst);
    }
}
