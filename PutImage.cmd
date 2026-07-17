/*&cls&@echo off&Title PutImage & REM SEE // IMPORTANT NOTE: BELOW about file locations before running this file


cd /d "%~dp0" & echo Compiling PutImage.exe
set "CSC=%SystemRoot%\Microsoft.NET\Framework\v4.0.30319\csc.exe"
if not exist "%CSC%" echo Compiler not found & pause & exit /b

::Prepare the Icon/BMP/ICO/PNG graphics as a 24 px X 24 px RAW PNG.Base64
>icon.b64 echo iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAACXBIWXMAAA7EAAAOxAGVKw4bAAABhElEQVRIibWVMU/CUBDHf6ctFBJXN10c3IwsDsaPwVRHBwcWdwbj4M5CooODGpkc/QIOEDdIHIxRo9HPIFiCPodXKi3vFTDllru2l//v7l7zTgoOijmaA9Ctzke8eBwCAOQoW3F1qL0Tf2uZlkj6d1s+sJCWl1sQEEG1QLXAy4k5sVGyahgBBVcLB00tPLTebQhNij8/wcXGdICcI1y+WgsiaIKXl0h8+a5D/eaTtda9sZMYIO8KjTcdX3+AbJshahAGfpulfljYQD+nAq4SladBhh28bK0D8FBandyByUyQ4IdIrH7yqP35ewSdCZCE5HfQv2s4jsrBZswnxzQVYBTS/1axSuu1Tsz/q4NRCCJaxG+D3453MOmQp4bsmquNwCMWvypmgJRF/q6OmhirHwOUV+yinhsGChDwHMAVWIRKQOz+sQI4862ALzt73PYa44CCA+w3TOmzm2MI57V0ZN4rU1RiiRRdUd2qXne9U/uZTGupv2khgzOxArI6E+OIspHW9gtrPHnP3FjSVQAAAABJRU5ErkJggg==
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
 This Hybrid file is a working demonstration of SumatraPDF DDE [Get...] it compiles to an exe that can place an image 
 using a tools script. It has a dependency on https://github.com/GitHubRulesOK/SumatraPDF-Plus/blob/master/Scripts/AddOverlay.js

 You may use this concept many other ways but the one thing you may be suprised at, is how that script applies rotation!
 The tests have not been extensive so can behave oddly with some PDF file types or odd images thus it is not guaranteed!

 Images can be overlaid and will work with some alpha transparency, such as PNG's. Beware trying to view largeer files may
 suffer "blocking" or mis-timings so there is an optional switch lower right but for now, is default ON.

Simply bind the compiled exe to a shortcut in SumatraPDF settings. Like this:
ExternalViewers [
	[
		CommandLine = C:\path to your version\PutImage.exe
		Name = &Put Image Overlay
		Key = p
		ToolbarSvgIcon = <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"><rect width="24" height="24" fill="none"/><rect x="4.5" y="19.5" width="20" height="4" stroke="#000" stroke-width="1" fill="#f81"/><rect x="6.5" y="19.5" width="20" height="2" stroke="#000" stroke-width="1" fill="#999"/><rect x="1" y="1" width="22" height="18.5" stroke="#000" stroke-width="1" fill="#f81"/><rect x="3" y="3" width="18" height="14.5" stroke="#000" stroke-width="1" fill="#0ff"/><circle cx="10" cy="8" r="4" fill="#fd1" stroke="#000" stroke-width="1"/><polygon points="3 17.5, 3 10, 7 6, 15.5 17.5" fill="#9e0" stroke="#000" stroke-width="1"/><path d="M17.5 8V17.5" stroke="#630" stroke-width="1"/><path d="M15.5 10L17.5 8L19.5 10" stroke="#080" stroke-width="1"/><path d="M15.5 13L17.5 11L19.5 13" stroke="#080" stroke-width="1"/><path d="M15.5 16L17.5 14L19.5 16" stroke="#080" stroke-width="1"/></svg>
	]
]

*/
using System; using System.IO; using System.Runtime.InteropServices; using System.Text;
using System.Windows.Forms; using System.Drawing; using System.Threading; using System.Reflection;

class Program
{
    			// IMPORTANT ALTER THESE TO YOUR OWN FILE LOCATIONS BEFORE BUILD

    public const string TOOL_PATH   = @"C:\Program Files\SumatraPDF\sumatrapdf-tool.exe";
    public const string SCRIPT_PATH = @"C:\Users\WDAGUtilityAccount\Downloads\addoverlay.js";
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
        Application.Run(new ImageForm());
    }
}

public class ImageForm : Form
{
    public const int WM_NCLBUTTONDOWN = 0xA1; public const int HTCAPTION = 0x2;
    [DllImport("user32.dll")] public static extern bool ReleaseCapture();
    [DllImport("user32.dll")] public static extern int SendMessage(IntPtr hWnd, int Msg, int wParam, int lParam);
    private TextBox txtImage;  private TextBox txtW; private TextBox txtH; private TextBox txtR; private TextBox txtOutput; 
    private CheckBox chkTopY; private CheckBox chkOpen;
    private Button btnGetImg; private Button btnGetOut; private Button btnPut;
    private bool armed = false;
    private Panel dragBar; private Label title;

    public ImageForm()
    {
    // READ the external icon.b64 convert and embed it replacing any internal methods
    var asm = Assembly.GetExecutingAssembly(); Image icon; using (var s = asm.GetManifestResourceStream("icon.b64"))
    using (var r = new StreamReader(s)) { byte[] png = Convert.FromBase64String(r.ReadToEnd()); using (var ms = new MemoryStream(png)) icon = Image.FromStream(ms); }
    using (var bmp = new Bitmap(icon)) this.Icon = Icon.FromHandle(bmp.GetHicon());

        this.FormBorderStyle = FormBorderStyle.None; this.TopMost = true; this.StartPosition = FormStartPosition.CenterScreen;
        this.BackColor = Color.FromArgb(30, 30, 30); this.ForeColor = Color.White; // this.Opacity = 0.70;
        this.Size = new Size(460, 225); this.Font = new Font("Segoe UI", 12, FontStyle.Regular);
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
        title = new Label(); title.Text = "Put Image Overlay Tool";
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
        // IMAGE INPUT
        Label lblImg = new Label(); lblImg.Text = "Image:"; lblImg.Left = 8; lblImg.Top = y + 3; lblImg.Width = 65;
        txtImage = new TextBox(); txtImage.Left = 75; txtImage.Top = y; txtImage.Width = 300;
        txtImage.BackColor = Color.FromArgb(45,45,45); txtImage.ForeColor = Color.White;
        btnGetImg = new Button(); btnGetImg.Text = "Browse"; btnGetImg.Left = 380;
        btnGetImg.Top = y - 1; btnGetImg.Width = 70; btnGetImg.Height = 30;
        btnGetImg.Click += OnBrowseImage;
        this.Controls.Add(lblImg); this.Controls.Add(txtImage); this.Controls.Add(btnGetImg);

        y += 36;
        // WIDTH
        Label lblW = new Label(); lblW.Text = "W (pt's):"; lblW.Left = 8; lblW.Top = y + 3; lblW.Width = 67;
        txtW = new TextBox();  txtW.Left = 75; txtW.Top = y; txtW.Width = 75;
        txtW.BackColor = Color.FromArgb(45,45,45); txtW.ForeColor = Color.White;
        // HEIGHT
        Label lblH = new Label(); lblH.Text = "H (pt's):"; lblH.Left = 165; lblH.Top = y + 3; lblH.Width = 65;
        txtH = new TextBox(); txtH.Left = 230; txtH.Top = y; txtH.Width = 75;
        txtH.BackColor = Color.FromArgb(45,45,45); txtH.ForeColor = Color.White;
        // ROTATION
        Label lblR = new Label(); lblR.Text = "Rot (°):"; lblR.Left = 315; lblR.Top = y + 3; lblR.Width = 65;
        txtR = new TextBox(); txtR.Left = 380; txtR.Top = y; txtR.Width = 70; txtR.Text = "0";
        txtR.BackColor = Color.FromArgb(45,45,45); txtR.ForeColor = Color.White;
        this.Controls.Add(lblW); this.Controls.Add(txtW); this.Controls.Add(lblH); this.Controls.Add(txtH); this.Controls.Add(lblR); this.Controls.Add(txtR);

        y += 28;
        // TOP-LEFT ANCHOR CHECKBOX
        chkTopY = new CheckBox(); chkTopY.Left = 12; chkTopY.Top = y + 3; chkTopY.Width = 500;
        chkTopY.Text = "Put image @ Top‑Left (Not PDF=y up, but image downward)";
        chkTopY.Checked = true;   // DEFAULT ON
        y += 36;
        Label lblMsg = new Label(); lblMsg.Text = "Default = infile-overlaid.PDF. You can change or overwrite one.";
        lblMsg.Left = 8; lblMsg.Top = y + 3; lblMsg.Width = 500;
        lblMsg.BackColor = Color.FromArgb(45,45,45); lblMsg.ForeColor = Color.White;
        this.Controls.Add(chkTopY); this.Controls.Add(lblMsg);

        y += 30;
        // OUTPUT PDF
        Label lblOut = new Label(); lblOut.Text = "Output PDF:"; lblOut.Left = 8; lblOut.Top = y + 3; lblOut.Width = 65;
        txtOutput = new TextBox(); txtOutput.Left = 75; txtOutput.Top = y; txtOutput.Width = 300;
        txtOutput.BackColor = Color.FromArgb(45,45,45); txtOutput.ForeColor = Color.White;
        btnGetOut = new Button(); btnGetOut.Text = "Browse"; btnGetOut.Left = 380;
        btnGetOut.Top = y - 1; btnGetOut.Width = 70; btnGetOut.Height = 30;
        btnGetOut.Click += OnGetOutput;
        this.Controls.Add(lblOut); this.Controls.Add(txtOutput); this.Controls.Add(btnGetOut);

        y += 30;
        // GETPOS
        btnPut = new Button(); btnPut.Text = "Put Image"; btnPut.Left = 8; btnPut.Top = y; btnPut.Width = 100; btnPut.Height = 30;
        btnPut.Click += OnPut;
        Label lblMsg2 = new Label(); lblMsg2.Text = "Autoview output if file is < 32 MB";
        lblMsg2.Left = 115; lblMsg2.Top = y + 3; lblMsg2.Width = 245;
        lblMsg2.BackColor = Color.FromArgb(45,45,45); lblMsg2.ForeColor = Color.White;
        chkOpen = new CheckBox(); chkOpen.Left = 360; chkOpen.Top = y + 3; chkOpen.Width = 100; chkOpen.Text = "Try Open"; chkOpen.Checked = true;   // default ON
        this.Controls.Add(btnPut); this.Controls.Add(lblMsg2); this.Controls.Add(chkOpen);

        this.Deactivate += OnLoseFocus;
    }

    private void OnBrowseImage(object sender, EventArgs e)
    {
        using (OpenFileDialog ofd = new OpenFileDialog())
        {
            ofd.Filter = "Image files|*.png;*.jpg;*.jpeg;*.bmp;*.gif|All files|*.*";
            if (ofd.ShowDialog() == DialogResult.OK)
                txtImage.Text = ofd.FileName;
        }
    }

    private void OnGetOutput(object sender, EventArgs e)
    {
        using (SaveFileDialog sfd = new SaveFileDialog())
        {
            sfd.Filter = "PDF files|*.pdf"; if (sfd.ShowDialog() == DialogResult.OK) txtOutput.Text = sfd.FileName;
        }
    }

    private void OnPut(object sender, EventArgs e)
    {
        if (!File.Exists(txtImage.Text.Trim()))
        {
            MessageBox.Show("Please select a valid image file.", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error); return;
        }
        double w, h, r;
        if (!double.TryParse(txtW.Text.Trim(), out w) || !double.TryParse(txtH.Text.Trim(), out h) || !double.TryParse(txtR.Text.Trim(), out r))
        {
            MessageBox.Show("Width, height, and rotation must be numeric.", "Error",
            MessageBoxButtons.OK, MessageBoxIcon.Error); return;
        }
        armed = true;
        dragBar.BackColor = Color.FromArgb(240, 80, 20);   // amber-ish
        title.Text = "ARMED - Image will be put @ click on the PDF in view";
    }

    private void OnLoseFocus(object sender, EventArgs e)
    {
        if (!armed)
            return;
        armed = false;
        dragBar.BackColor = Color.FromArgb(50, 50, 50);   // original colour
        title.Text = "Put Image Overlay Tool";
        PerformDdeAndBuildCommand();
        // Attempt user option
        if (chkOpen.Checked)
        {
          // Give script time to finish writing so set a 1 second delay
          Thread.Sleep(1000);
          string outFile = txtOutput.Text;
          if (File.Exists(outFile)) // Only open if under 32 MB (SumatraPDF safe size)
          {
            long outSize = new FileInfo(outFile).Length;    
            if (outSize < (32L * 1024 * 1024)) // TODO check if the 32 MB is needed but bigger files will likely take longer
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
            MessageBox.Show("DDE failed.", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error); return;
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
            MessageBox.Show("Incomplete DDE data:\n" + reply, "Error", MessageBoxButtons.OK, MessageBoxIcon.Error); return;
        }
        // Auto-seed output if empty
        if (string.IsNullOrWhiteSpace(txtOutput.Text))
        {
            string outPdf = Path.Combine( Path.GetDirectoryName(path), Path.GetFileNameWithoutExtension(path) + "-overlaid.pdf" );
            txtOutput.Text = outPdf;
        }
        string img = txtImage.Text.Trim();
        string wStr = txtW.Text.Trim(); string hStr = txtH.Text.Trim(); string rStr = txtR.Text.Trim();
        string outPdfFinal = txtOutput.Text.Trim();
        // TOP-LEFT ANCHOR COMPENSATE (shift overlay down by its own height)
        double yVal = double.Parse(ypdf); double hVal = double.Parse(hStr);
        if (chkTopY.Checked) { yVal = yVal - hVal; }
        ypdf = yVal.ToString(); // replace ypdf with compensated value
        string exe = Program.TOOL_PATH;
        string args = string.Format(
            "run \"{0}\" -p={1} -img=\"{2}\" -b=\"{3},{4},{5},{6}\" -r={7} -o=\"{8}\" \"{9}\"",
            Program.SCRIPT_PATH, page, img, x, ypdf, wStr, hStr, rStr, outPdfFinal, path
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
    const int APPCLASS_STANDARD = 0x00000000; const int APPCMD_CLIENTONLY = 0x00000010;
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
        IntPtr hszService = DdeCreateStringHandleW(inst, "SUMATRA", 1200); IntPtr hszTopic   = DdeCreateStringHandleW(inst, "control", 1200);
        IntPtr hszItem    = DdeCreateStringHandleW(inst, item, 1200); IntPtr hConv = DdeConnect(inst, hszService, hszTopic, IntPtr.Zero);
        if (hConv == IntPtr.Zero) { Cleanup(inst, hszService, hszTopic, hszItem); return null; }
        int result;
        IntPtr hData = DdeClientTransaction(null, 0, hConv, hszItem, CF_UNICODETEXT, XTYP_REQUEST, TIMEOUT, out result);
        if (hData == IntPtr.Zero) { DdeDisconnect(hConv); Cleanup(inst, hszService, hszTopic, hszItem); return null; }
        int size = DdeGetData(hData, null, 0, 0); byte[] buffer = new byte[size]; DdeGetData(hData, buffer, size, 0);
        string reply = Encoding.Unicode.GetString(buffer).TrimEnd('\0'); DdeDisconnect(hConv); Cleanup(inst, hszService, hszTopic, hszItem);
        return reply;
    }
    static void Cleanup(IntPtr inst, IntPtr hszService, IntPtr hszTopic, IntPtr hszItem)
    {
        DdeFreeStringHandle(inst, hszService); DdeFreeStringHandle(inst, hszTopic); DdeFreeStringHandle(inst, hszItem); DdeUninitialize(inst);
    }
}
