/*&cls&@echo off&Title Place Signature Tool & REM SEE // IMPORTANT NOTE: BELOW about file locations before running this file

cd /d "%~dp0" & echo Compiling "%~dpn0.exe"
set "CSC=%SystemRoot%\Microsoft.NET\Framework\v4.0.30319\csc.exe"
if not exist "%CSC%" echo Compiler not found & pause & exit /b

::Prepare the Icon/BMP/ICO/PNG graphics as a 24 px X 24 px RAW PNG.Base64
>icon.b64 echo iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAACXBIWXMAAA7EAAAOxAGVKw4bAAAA6ElEQVRIie2W4Q2DIBCF3zPu4QodwQk6iJ2nLtIFXKEb1ElefwhEUAQMpn/6EhLx8L7j7iAS6nGlWvfESae9qGfM1HjrpOKRCq6JGYo2IEUhVQBHkCoAkiBNGQJIu/dBiVwdfKBs4aulKKY/4PeAbRfdXt6U73tlQKC9NjySOw927m5TTpIEkpAEjpgdZEDHEbMGdNkAcw4Od7B2aJ/3wOHatQ6LzBGzdRA6DgNZ27MAGtDlpCSlaIpiEaVsW6mHKbS0tIxyhKc+u++BZRi/xbdpWfSRFIW9HMjVhY80wCtywvEp8erfli8qubVNmajTigAAAABJRU5ErkJggg==
::Convert first into an App.ico and keep base64 for internal conversion
>makeico.cs echo using System; using System.IO; class M { static void Main() {
>>makeico.cs echo var p = Convert.FromBase64String(File.ReadAllText("icon.b64")); using (var f = File.Create("app.ico")) { f.Write(new byte[]{0,0,1,0,1,0,24,24,0,0,1,0,32,0},0,14); W(f,p.Length); W(f,22); f.Write(p,0,p.Length); } } static void W(Stream s,int v){s.WriteByte((byte)v);s.WriteByte((byte)(v^>^>8));s.WriteByte((byte)(v^>^>16));s.WriteByte((byte)(v^>^>24)); } }
"%CSC%" /nologo makeico.cs && makeico.exe && del makeico.cs makeico.exe
:: The app.ico AND Title icon.b64 can now be used by main compilation

"%CSC%"  /nologo /target:winexe /win32icon:app.ico /resource:icon.b64 /platform:x86 /out:"%~dpn0.exe" "%~dpnx0"

:: It should now be safe to delete the temporary graphics
del app.ico icon.b64

REM IMPORTANT we must pause and exit here before NOTES
pause & exit /b

NOTES:
 This Hybrid file is a working demonstration of SumatraPDF DDE [Get...] it compiles to an exe that can place a Signature
 using a tools script. It has a dependency on SumatraPDF-Tool NOT MuPDF Mutool since it uses a different Windows signing method.

 The tests have not been extensive so can behave oddly with some PDF file types or odd images thus it is not guaranteed!
 Some guidance messages are still in flux so beware if they conflict with any others !

 Images can be overlaid and will work with some alpha transparency, such as PNG's. Beware trying to view larger files may
 suffer "blocking" or mis-timings so there is an optional 32MB switch lower right but for now, is default ON.

Simply bind the compiled exe to a shortcut in SumatraPDF settings. Like this:
ExternalViewers [
	[
		CommandLine = C:\path to your version\PlaceSig.exe
		Name = Place Signature &Boxes
		Key = b
		ToolbarSvgIcon = <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"><rect width="24" height="24" fill="none"/><rect x="5" y="0" width="15" height="24" fill="#fff" stroke="#000" stroke-width="1"/><rect x="8" y="18" width="9" height="3" fill="#f19"/><path d="M 7 6 L 18 6 M 7 9 L 18 9 M 7 12 L 18 12 M 7 15 L 18 15 M 7 18 L 18 18" stroke="#888"/></svg>
	]
]

For Digital signing you must have a personal PFX file so If not you can copy and paste the following indented block as a SelfCert.CMD file and generate a SelfCert.PFX
    @echo off & setlocal enabledelayedexpansion
    rem === Ask user for values ===
    set /p N=Your Name (default My Name): &if "!N!"=="" set "N=My Name"
    set /p O=Organisation (default None): &if "!O!"=="" set "O=None"
    set /p U=Organisational Unit (default None): &if "!U!"=="" set "U=None"
    set /p E=Email (default my.mail@example.com): &if "!E!"=="" set "E=my.mail@example.com"
    set /p C=Country (default US): &if "!C!"=="" set "C=US"
    set /p P=Password (default password): &if "!P!"=="" set "P=password"
    Echo Please wait for confirmation ...
    powershell -c "$c=New-SelfSignedCertificate -Subject 'CN=!N!, O=!O!, OU=!U!, C=!C!, E=!E!' -CertStoreLocation Cert:\CurrentUser\My -KeyAlgorithm RSA -KeyLength 2048 -KeyExportPolicy Exportable -Provider 'Microsoft RSA SChannel Cryptographic Provider' -NotAfter (Get-Date).AddDays(3653); $pwd=ConvertTo-SecureString '!P!' -AsPlainText -Force; Export-PfxCertificate -Cert $c -FilePath 'MySelfCert.pfx' -Password $pwd"
    pause

Do not remove this next Line as it signals the start of the main program
*/
using System; using System.IO; using System.Runtime.InteropServices; using System.Text; using System.Diagnostics;
using System.Windows.Forms; using System.Drawing; using System.Threading; using System.Reflection;
class Program
{
    			// IMPORTANT NOTE:   ALTER THESE TO YOUR OWN FILE LOCATIONS and choices BEFORE BUILD

    public const string TOOL_PATH   = @"C:\Program Files\SumatraPDF\sumatrapdf-tool.exe";
    public const string PNG_PATH = @"C:\Users\ your path to \your\signature.png";
    public const string PFX_PATH = @"C:\Users\ your path to \MySelfCert.pfx";
    public const string VIEWER_PATH = @"C:\Program Files\SumatraPDF\SumatraPDF.exe";

    public static string LOCATION = "";   // add text between the "" (Optional) The CPU host name or physical location of the signing. Such as "PDF on Planet Earth."
    public static string REASON = "I agree this X is My Mark.";     // (Optional) The reason for PDF eSigning, such as ( I agree … 
    public static string TEMP_PATH = Environment.GetEnvironmentVariable("TMP") ?? Path.GetTempPath();

    public static string PFX_PASSWORD = "password";    // This is a dummy entry DO NOT store your password here

    [STAThread]
    static void Main(string[] args)
    {
    // STARTUP GUARD
    if (!File.Exists(TOOL_PATH))
       { MessageBox.Show("SumatraPDF-tool.exe not found:\n" + TOOL_PATH, "Missing Tool", MessageBoxButtons.OK, MessageBoxIcon.Error); return; }
    // VIEWER_PATH is optional remove this section if you dont want to check it exists but you will need to make other alterations
    if (!File.Exists(VIEWER_PATH))
       { MessageBox.Show("Viewer not found:\n" + VIEWER_PATH, "Missing Viewer", MessageBoxButtons.OK, MessageBoxIcon.Warning); }
    // Continue to launch
    Application.EnableVisualStyles(); Application.SetCompatibleTextRenderingDefault(false); Application.Run(new SignatureForm());
    }
// EndClass
}

public class SignatureForm : Form
{
    public const int WM_NCLBUTTONDOWN = 0xA1; public const int HTCAPTION = 0x2;
    [DllImport("user32.dll")] public static extern bool ReleaseCapture();
    [DllImport("user32.dll")] public static extern int SendMessage(IntPtr hWnd, int Msg, int wParam, int lParam);
    private Panel dragBar; private Label title; private Panel picPanel; private PictureBox picSignature;
    private PictureBox picSignBox; ComboBox cmbAction; private TextBox txtImage; private Button btnGetImg;
    private TextBox txtCert; private Button btnGetCert; private TextBox txtPwd; private CheckBox chkShowPwd;
    private TextBox txtXpt; private TextBox txtYpt; private TextBox txtW; private TextBox txtH; private Label lblMsg;
    private TextBox txtOutput; private Button btnGetOut; private CheckBox chkOpen; private Button btnHelp;
    static bool useDDE = false; private bool armed = false; static bool useImg = false;
    private string inputPdf; private int pageNum;
    private readonly Color DarkBack = Color.FromArgb(30, 30, 30); private readonly Color TextLight = Color.White;
    private Action<object, EventArgs> ddeXYChangedCallback;

    public SignatureForm()
    {
    // READ the external icon.b64 convert and embed it replacing any internal methods
    var asm = Assembly.GetExecutingAssembly(); Image icon; using (var s = asm.GetManifestResourceStream("icon.b64"))
    using (var r = new StreamReader(s)) { byte[] png = Convert.FromBase64String(r.ReadToEnd()); using (var ms = new MemoryStream(png)) icon = Image.FromStream(ms); }
    using (var bmp = new Bitmap(icon)) this.Icon = Icon.FromHandle(bmp.GetHicon());

        this.FormBorderStyle = FormBorderStyle.None; this.TopMost = true; this.StartPosition = FormStartPosition.CenterScreen;
        this.BackColor = Color.FromArgb(30, 30, 30); this.ForeColor = Color.White; // this.Opacity = 0.70;
        this.Size = new Size(460, 400); this.Font = new Font("Segoe UI", 12, FontStyle.Regular);
        // Check DDE probe
        string reply = DdeClient.Request("[GetFileState()]");
        if (reply == null) {
            MessageBox.Show( "SumatraPDF may be active but currently there is\nNO DDE reply channel.\nThis simply means current state of SumatraPDF.exe\n" +
            "does not provide a DDE context yet. You may be able to\nuse DDE after restart exe or making changes.", "No DDE Channel", MessageBoxButtons.OK, MessageBoxIcon.Information
            ); // Continue NOT exit
        }

        // DRAG BAR and ARMING NOTIFICATION AREA
        dragBar = new Panel(); dragBar.Left = 0; dragBar.Top = 0; dragBar.Width = this.Width; dragBar.Height = 28; this.Controls.Add(dragBar);
        PictureBox pic = new PictureBox { Image = icon, Size = new Size(28, 28), Location = new Point(0, 0), BackColor = Color.FromArgb(255, 201, 15), SizeMode = PictureBoxSizeMode.CenterImage };
        pic.MouseDown += (s, e) => { if (e.Button == MouseButtons.Left) { ReleaseCapture(); SendMessage(this.Handle, WM_NCLBUTTONDOWN, HTCAPTION, 0); } }; dragBar.Controls.Add(pic);
        title = new Label(); title.Text = "Place Signature Tool"; title.Left = 30; title.Top = 4; title.Width = 397;
        title.MouseDown += (s, e) => { if (e.Button == MouseButtons.Left) { ReleaseCapture(); SendMessage(this.Handle, WM_NCLBUTTONDOWN, HTCAPTION, 0); } }; dragBar.Controls.Add(title);
        // CLOSE BUTTON
        Label btnX = new Label() { Text = "X", Font = new Font("Segoe UI", 15, FontStyle.Bold), Top = 0, Left = this.Width - 30, Width = 30, Height = 30,
        ForeColor = Color.White, TextAlign = ContentAlignment.TopCenter }; btnX.MouseEnter += (s, e) => btnX.BackColor = Color.FromArgb(200, 50, 50);
        btnX.MouseLeave += (s, e) => btnX.BackColor = Color.FromArgb(30, 30, 30); btnX.Click += (s, e) => Close(); dragBar.Controls.Add(btnX);

        // Pic PANELS
        picPanel = new Panel(); picPanel.Left = 5; picPanel.Top = 30; picPanel.Width = 450; picPanel.Height = 100; this.Controls.Add(picPanel);
        picSignBox = new PictureBox(); picSignBox.Left = 10; picSignBox.Top = 10; picSignBox.Width = 170; picSignBox.Height = 80;
        picSignBox.SizeMode = PictureBoxSizeMode.CenterImage; picPanel.Controls.Add(picSignBox);
        picSignBox.Paint += (s, e) => {
            var g = e.Graphics; g.DrawRectangle(new Pen(Color.White, 2), 1, 1, picSignBox.Width-2 , picSignBox.Height-2); {
            PointF p1 = new PointF(2, 16); PointF p2 = new PointF(43, 16); PointF p3 = new PointF(50, 9); PointF p4 = new PointF(43, 2);
            PointF p5 = new PointF(2, 2); g.FillPolygon(new SolidBrush(Color.DeepPink), new PointF[] { p1, p2, p3, p4, p5 });
            using (var font = new Font("Segoe UI", 10, FontStyle.Regular)) using (var brush = new SolidBrush(Color.White)) g.DrawString("SIGN", font , brush, new PointF(5, 0)); }
        };
        picSignature = new PictureBox(); picSignature.Left = 195; picSignature.Top = 0; picSignature.Width = 250; picSignature.Height = 100;
        picSignature.SizeMode = PictureBoxSizeMode.Zoom; picPanel.Controls.Add(picSignature);
        picSignature.Paint += (s, e) =>
        {
            var g = e.Graphics; int tile = 10; bool toggleRow; for (int yy = 0; yy < picSignature.Height; yy += tile)
            {
                toggleRow = ((yy / tile) % 2 == 0); for (int xx = 0; xx < picSignature.Width; xx += tile)
                {
                    bool toggle = toggleRow ^ ((xx / tile) % 2 == 0); Color c = toggle ? Color.LightGray : Color.White;
                    using (var b = new SolidBrush(c)) g.FillRectangle(b, xx, yy, tile, tile);
                }
            }
            if (picSignature.Image != null) { g.DrawImage(picSignature.Image, new Rectangle(0, 0, picSignature.Width, picSignature.Height)); } // Draw the PNG on top
        };

// ACTION SELECTOR
Label lblAction = new Label(); lblAction.Text = "Action:"; lblAction.Left = 8; lblAction.Top = 137; lblAction.Width = 67;
cmbAction = new ComboBox(); cmbAction.Left = 75; cmbAction.Top = 135; cmbAction.Width = 375; cmbAction.DropDownStyle = ComboBoxStyle.DropDownList;
// Options
cmbAction.Items.Add("Select an Action from drop down");
cmbAction.Items.Add("Click PDF to Text Sign in SignBox (slow)");
cmbAction.Items.Add("Click PDF to Use Image in SignBox (slow)");
cmbAction.Items.Add("Add Image (SET Pos x,y,W,H & click Image)");
cmbAction.Items.Add("Add Image (Click PDF to Place USEs W & H )");
cmbAction.Items.Add("Add Box (Set Pos x,y,W,H below & click SIGN>)");
cmbAction.Items.Add("Add Box (Click PDF to set Pos x,y USEs W & H )");
cmbAction.Items.Add("todo");
cmbAction.Items.Add("todo");
cmbAction.SelectedIndex = 0; this.Controls.Add(lblAction); this.Controls.Add(cmbAction); cmbAction.SelectedIndexChanged += cmbAction_SelectedIndexChanged;

        // PNG INPUT
        int y = 168; // controls after here are relative to this point
        Label lblImg = new Label(); lblImg.Text = "Image:"; lblImg.Left = 8; lblImg.Top = y + 3; lblImg.Width = 67;
        txtImage = new TextBox(); txtImage.Left = 75; txtImage.Top = y; txtImage.Width = 300; btnGetImg = new Button(); btnGetImg.Text = "Browse";
        btnGetImg.Left = 380; btnGetImg.Top = y -1 ; btnGetImg.Width = 70; btnGetImg.Height = 30; btnGetImg.Click += OnBrowseImage;
        this.Controls.Add(lblImg); this.Controls.Add(txtImage); this.Controls.Add(btnGetImg); txtImage.Text = Program.PNG_PATH;
       
        // CERT INPUT
        y += 33; Label lblCert = new Label(); lblCert.Text = "Cert:"; lblCert.Left = 8; lblCert.Top = y + 3; lblCert.Width = 67;
        txtCert = new TextBox(); txtCert.Left = 75; txtCert.Top = y; txtCert.Width = 300; btnGetCert = new Button(); btnGetCert.Text = "Browse";
        btnGetCert.Left = 380; btnGetCert.Top = y - 1; btnGetCert.Width = 70; btnGetCert.Height = 30; btnGetCert.Click += OnBrowseCert;
        this.Controls.Add(lblCert); this.Controls.Add(txtCert); this.Controls.Add(btnGetCert); txtCert.Text = Program.PFX_PATH;

        // PASSWORD INPUT Show default password as example (password) but mask input with *
        y += 33; Label lblPwd = new Label(); lblPwd.Text = "PfxPwd:"; lblPwd.Left = 8; lblPwd.Top = y + 3; lblPwd.Width = 67;
        txtPwd = new TextBox(); txtPwd.Left = 75; txtPwd.Top = y; txtPwd.Width = 300; txtPwd.UseSystemPasswordChar = true;
        chkShowPwd = new CheckBox(); chkShowPwd.Left = 380; chkShowPwd.Top = y + 3; chkShowPwd.Width = 70; chkShowPwd.Text = "Show";
        chkShowPwd.CheckedChanged += (s, e) => { txtPwd.UseSystemPasswordChar = !chkShowPwd.Checked; };
        this.Controls.Add(lblPwd); this.Controls.Add(txtPwd); this.Controls.Add(chkShowPwd); txtPwd.Text = Program.PFX_PASSWORD;

        // POSITION WIDTH HEIGHT
        y += 33; Label lblPos = new Label(); lblPos.Text = "Pos(x,y):"; lblPos.Left = 8; lblPos.Top = y + 3; lblPos.Width = 67;
        txtXpt = new TextBox(); txtXpt.Left = 75; txtXpt.Top = y; txtXpt.Width = 55; txtXpt.Text = "0";
        txtYpt = new TextBox(); txtYpt.Left = 133; txtYpt.Top = y; txtYpt.Width = 55; txtYpt.Text = "0";
        Label lblW = new Label(); lblW.Text = "W (pt's):"; lblW.Left = 190; lblW.Top = y + 3; lblW.Width = 67;
        txtW = new TextBox();  txtW.Left = 258; txtW.Top = y; txtW.Width = 55; txtW.Text = "240";
        Label lblH = new Label(); lblH.Text = "H (pt's):"; lblH.Left = 314; lblH.Top = y + 3; lblH.Width = 67;
        txtH = new TextBox(); txtH.Left = 380; txtH.Top = y; txtH.Width = 55; txtH.Text = "40";
        this.Controls.Add(lblPos); this.Controls.Add(txtXpt); this.Controls.Add(txtYpt);
        this.Controls.Add(lblW); this.Controls.Add(txtW); this.Controls.Add(lblH); this.Controls.Add(txtH);

        y += 35; lblMsg = new Label(); lblMsg.Text = "";
        lblMsg.Left = 8; lblMsg.Top = y + 3; lblMsg.Width = 440; this.Controls.Add(lblMsg);
 
        // OUTPUT PDF
        y += 30; Label lblOut = new Label(); lblOut.Text = "out.PDF:"; lblOut.Left = 8; lblOut.Top = y + 3; lblOut.Width = 67;
        txtOutput = new TextBox(); txtOutput.Left = 75; txtOutput.Top = y; txtOutput.Width = 300;
        btnGetOut = new Button(); btnGetOut.Text = "Browse"; btnGetOut.Left = 380;
        btnGetOut.Top = y - 1; btnGetOut.Width = 70; btnGetOut.Height = 30;
        btnGetOut.Click += OnGetOutput;
        this.Controls.Add(lblOut); this.Controls.Add(txtOutput); this.Controls.Add(btnGetOut);

        y += 32; btnHelp = new Button(); btnHelp.Text = "Help"; btnHelp.Left = 8; btnHelp.Top = y; btnHelp.Width = 100; btnHelp.Height = 30;
        btnHelp.Click += (s, e) => new HelpForm().ShowDialog();

        Label lblMsg2 = new Label(); lblMsg2.Text = "Autoview output if file is < 32 MB";
        lblMsg2.Left = 115; lblMsg2.Top = y + 3; lblMsg2.Width = 245;
        chkOpen = new CheckBox(); chkOpen.Left = 360; chkOpen.Top = y + 3; chkOpen.Width = 92; chkOpen.Text = "Try Open"; chkOpen.Checked = true;   // default ON
        this.Controls.Add(btnHelp); this.Controls.Add(lblMsg2); this.Controls.Add(chkOpen);

        ApplyTheme(this);
        // Colour Exceptions
        lblMsg.BackColor = Color.FromArgb(255, 201, 15); lblMsg.ForeColor = Color.Black;
        this.Deactivate += OnLoseFocus;
    }

// HELPERS
private void ApplyTheme(Control parent) { foreach (Control c in parent.Controls) { c.BackColor = DarkBack; c.ForeColor = TextLight; if (c.HasChildren)  ApplyTheme(c); } }
private void cmbAction_SelectedIndexChanged(object sender, EventArgs e)
{
    int action = cmbAction.SelectedIndex;
    // MessageBox.Show("Action = " + action);
    if (action == 0) return; // SELECT something to run
    switch (action)
    {
        case 1: useDDE = true; useImg = false; useEsign(); break;
        case 2: useDDE = true; useImg = true; useEsign(); break;
        case 3: useDDE = false; useImage(); break;
        case 4: useDDE = true;  useImage(); break;
        case 5: useDDE = false; useSignBox(); break;
        case 6: useDDE = true;  useSignBox(); break;
//        case 7: useDDE = false; use(); break;
//        case 8: useDDE = true;  use(); break;
        // case 7–16 TODO
    }
}
private void ArmMsg(string message) { armed = true; title.BackColor = Color.FromArgb(240, 80, 20); title.ForeColor = Color.Black; title.Text = "ARMED - " + message; }
private void unArm() { armed = false; title.BackColor = Color.FromArgb(30, 30, 30); title.ForeColor = Color.White; title.Text = "Place Signature Tool"; }
private void OnLoseFocus(object sender, EventArgs e)
{
    if (!useDDE) return; if (!armed) return;
    string path; int pageV; int pageP; double x; double y; double ypdf; DdeGetFileInfo(out path, out pageV, out pageP, out x, out y, out ypdf);
    if (pageP <= 0) { MessageBox.Show("Click was outside the page - manual values kept.", "Invalid Click"); return; }
    if (string.IsNullOrEmpty(path)) { MessageBox.Show("Incomplete DDE data.", "Error"); return; }
    txtXpt.Text = x.ToString(); txtYpt.Text = y.ToString();    // Update XY fields
    unArm(); // IMPORTANT
    if (ddeXYChangedCallback != null) ddeXYChangedCallback(this, EventArgs.Empty);
}
private bool DdeGetFileInfo(out string path, out int pageV, out int pageP, out double x, out double y, out double ypdf)
{
    path = ""; pageV = 0; pageP = 0; x = 0; y = 0; ypdf = 0; string reply = DdeClient.Request("[GetFileState()][GetMousePos]");
    if (string.IsNullOrEmpty(reply)) return false; string[] lines = reply.Replace("\0", "").Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
    // MessageBox.Show(reply, "RAW DDE REPLY");
    foreach (string raw in lines)
    {
        string t = raw.Trim();
        if (t.StartsWith("path:")) path = t.Substring(5).Trim();
        if (t.StartsWith("page:"))
        {
            int val;
            if (int.TryParse(t.Substring(5).Trim(), out val))
            {
                if (pageV == 0) pageV = val;  // first page = view page
                else pageP = val;             // second page = position page
            }
        }
        else if (t.StartsWith("x:")) double.TryParse(t.Substring(2).Trim(), out x);
        else if (t.StartsWith("y:")) double.TryParse(t.Substring(2).Trim(), out y);
        else if (t.StartsWith("ypdf:")) double.TryParse(t.Substring(5).Trim(), out ypdf);
    }
    // Only fail if path is missing
    return !string.IsNullOrWhiteSpace(path);
}
private void TryOpenOutputFile(int pageV)
{
    if (!chkOpen.Checked) return;
    // If output does not exist, abort = nothing to open
    string outPath = txtOutput.Text.Trim();
//MessageBox.Show("Opening Page:\n" + pageV +" in "+ outPath, "DEBUG OUTPATH");
    if (!File.Exists(outPath)) return;
    long outSize = new FileInfo(outPath).Length;
    // 30MB guard (below SumatraPDF’s 32MB lock threshold)
    if (outSize < (30L * 1024 * 1024))
    {
        string SumatraPDF = Program.VIEWER_PATH; string args = "-reuse-instance -page " + pageV + " \"" + outPath + "\"";
        RunHiddenCommand(SumatraPDF, args, Path.GetDirectoryName(SumatraPDF));
    }
}
//    private void 
private string RunHiddenCommand(string exePath, string arguments, string workingDir)
    {
        try
        {
            var psi = new System.Diagnostics.ProcessStartInfo();
            psi.FileName = exePath; psi.Arguments = arguments; psi.CreateNoWindow = true; psi.UseShellExecute = false;
            psi.WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden; psi.WorkingDirectory = workingDir;
psi.RedirectStandardOutput = true; psi.RedirectStandardError = true;
// Debugging  MessageBox.Show("PROCESS CALL\nFileName=[" + psi.FileName + "]\nArguments=[" + psi.Arguments + "]\nWorkingDirectory=[" + psi.WorkingDirectory + "]");
            //System.Diagnostics.Process.Start(psi);
var p = System.Diagnostics.Process.Start(psi);
string output = p.StandardOutput.ReadToEnd();
string error = p.StandardError.ReadToEnd();
p.WaitForExit(); return output + error;
        }
        catch (Exception ex)
        {
            MessageBox.Show("Failed to run command:\n" + ex.Message, "Execution Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
return "C# exception: " + ex.Message;
        }
    }

// Sign Box Actions

private void useSignBox()
{
    // DDE should be ALWAYS ON fetch filename and page number
    string path; int pageV; int pageP; double x; double y; double ypdf;
    DdeGetFileInfo(out path, out pageV, out pageP, out x, out y, out ypdf);
    inputPdf = path; pageNum  = pageV;
    if (!path.EndsWith(".pdf", StringComparison.OrdinalIgnoreCase))
    {
        MessageBox.Show( "The current file is not a PDF.\n\nPlease open a PDF file before placing a SignBox.",
        "Invalid File", MessageBoxButtons.OK, MessageBoxIcon.Warning );
        return;
    }
    if (string.IsNullOrWhiteSpace(txtOutput.Text)) { txtOutput.Text = path.Replace(".pdf", "-WithBox.pdf"); }
    string outPath = txtOutput.Text.Trim();
    if (!outPath.EndsWith("-WithBox.pdf", StringComparison.OrdinalIgnoreCase)) txtOutput.Text = outPath.Replace(".pdf", "-WithBox.pdf");
    if (string.Equals(inputPdf, txtOutput.Text, StringComparison.OrdinalIgnoreCase)) { outPath = inputPdf.Replace(".pdf", "-WithBox.pdf"); txtOutput.Text = outPath; }
    lblMsg.Text = "Default = infile-WithBox.PDF you can overwrite / change here.";
    picSignBox.BackColor = Color.Lime;
    if (!useDDE) { ArmMsg("Check X,Y & click on SignBox to place on PDF"); picSignBox.Click += PutSignBox; }
    else { ArmMsg("Check W,H Click on PDF in view to place SignBox"); ddeXYChangedCallback = PutSignBox; }
}
private void PutSignBox(object sender, EventArgs e)
{
// DONT    TryOpenOutputFile(pageNum);  // Try output file on same page BEFORE script and Reset UX
    unArm(); picSignBox.BackColor = this.BackColor; picSignBox.Click -= PutSignBox; // Remove temporary handler
    RunBoxScript();
    TryOpenOutputFile(pageNum);  // Try result file AFTER script
    ddeXYChangedCallback = null; // Clear callback so future blur doesn’t reuse it accidentally
}
private void RunBoxScript()
{
    // Everything is TEXT Read X,Y from txtXpt txtXpt and same later but a calc needs float 
    float x1 = float.Parse(txtXpt.Text); float w  = float.Parse(txtW.Text); float x2 = x1 + w;
    float y1 = float.Parse(txtYpt.Text); float h  = float.Parse(txtH.Text); float y2 = y1 + h;
    string inPdfEsc = inputPdf.Replace("\\", "\\\\"); string outPdf = txtOutput.Text; string outPdfEsc = outPdf.Replace("\\", "\\\\");
    int base0 = pageNum - 1; string sigName = "Sig1=D:" + DateTime.Now.ToString("yyyyMMddHHmmss");
    string scriptFile = Path.Combine(Program.TEMP_PATH, "PlaceBox.js");
    string js =
        "var d = mupdf.Document.openDocument(\"" + inPdfEsc + "\"); var p = d.loadPage(" + base0 + ");\n" +
        "p.createSignature(\"" + sigName + "\").setRect([" + x1 + ", " + y1 + ", " + x2 + ", " + y2 + "]);\n" +
        "p.update(); d.save(\"" + outPdfEsc + "\");\n";
    File.WriteAllText(scriptFile, js);
    RunHiddenCommand(Program.TOOL_PATH, "run \"" + scriptFile + "\"",Path.GetDirectoryName(Program.TOOL_PATH));
}

    private void OnBrowseImage(object sender, EventArgs e)
    {
        using (OpenFileDialog ofd = new OpenFileDialog())
        {
            ofd.Filter = "PNG Image|*.png|All files|*.*";
            if (ofd.ShowDialog() == DialogResult.OK) { txtImage.Text = ofd.FileName; picSignature.Image = Image.FromFile(ofd.FileName); }
        }
    }

private void useImage()
{
    // DDE should be ALWAYS ON fetch filename and page number
if (!File.Exists(txtImage.Text)) {
    MessageBox.Show("Image file not found.");
    return;
}
    string path; int pageV; int pageP; double x; double y; double ypdf;
    DdeGetFileInfo(out path, out pageV, out pageP, out x, out y, out ypdf);
    inputPdf = path; pageNum  = pageV;
    if (!path.EndsWith(".pdf", StringComparison.OrdinalIgnoreCase))
    {
        MessageBox.Show( "The current file is not a PDF.\n\nPlease open a PDF file before placing a Signature.",
        "Invalid File", MessageBoxButtons.OK, MessageBoxIcon.Warning );
        return;
    }
    if (string.IsNullOrWhiteSpace(txtOutput.Text)) { txtOutput.Text = path.Replace(".pdf", "-WithImg.pdf"); }
    string outPath = txtOutput.Text.Trim();
    if (!outPath.EndsWith("-WithImg.pdf", StringComparison.OrdinalIgnoreCase)) txtOutput.Text = outPath.Replace(".pdf", "-WithImg.pdf");
    if (string.Equals(inputPdf, txtOutput.Text, StringComparison.OrdinalIgnoreCase)) { outPath = inputPdf.Replace(".pdf", "-WithImg.pdf"); txtOutput.Text = outPath; }
    lblMsg.Text = "Default = infile-WithImg.PDF you can overwrite / change here.";
    picSignature.Cursor = Cursors.Cross; //Hand SizeAll UpArrow
    if (!useDDE) { ArmMsg("Check x,y,W,H & click on Image to place on PDF"); picSignature.Click += PutImage; }
    else { ArmMsg("Check W & H and click on PDF in view to place Image"); ddeXYChangedCallback = PutImage; }
}
private void PutImage(object sender, EventArgs e)
{
// DONT     TryOpenOutputFile(pageNum);  // Try output file on same page BEFORE script and Reset UX
    unArm(); picSignature.Cursor = Cursors.Default; picSignature.Click -= PutImage; // Remove temporary handler
    RunImageScript();
    TryOpenOutputFile(pageNum);  // Try result file AFTER script
    ddeXYChangedCallback = null; // Clear callback so future blur doesn’t reuse it accidentally
}
private void RunImageScript()
{
    float x = float.Parse(txtXpt.Text); float ydown = float.Parse(txtYpt.Text);
    float w = float.Parse(txtW.Text); float h = float.Parse(txtH.Text);
    string inPdfEsc = inputPdf.Replace("\\", "\\\\"); int base0 = pageNum - 1;
    string imgEsc = txtImage.Text.Replace("\\", "\\\\"); string outPdfEsc = txtOutput.Text.Replace("\\", "\\\\");
    string scriptFile = Path.Combine(Program.TEMP_PATH, "PlaceImage.js");
    string js =
        "var d = mupdf.Document.openDocument(\"" + inPdfEsc + "\"); var p = d.loadPage(" + base0 + ");\n" +
        "var pageObj = p.getObject(); var res = pageObj.get(\"Resources\");\n" +
        "if (!res || !res.isDictionary()) { res = d.newDictionary(); pageObj.put(\"Resources\", res); }\n" +
        "var xobj = res.get(\"XObject\");\n" +
        "if (!xobj || !xobj.isDictionary()) { xobj = d.newDictionary(); res.put(\"XObject\", xobj); }\n" +
        "var img = new mupdf.Image(\"" + imgEsc + "\"); var imgRef = d.addImage(img);\n" +
        "xobj.put(\"Im0\", imgRef);\n" +
        "var bounds = p.getBounds(); var pageHeight = bounds[3];\n" +
        "var Ypdf = pageHeight - (" + ydown + " + " + h + ");\n" +
        "var ops = \"q " + w + " 0 0 " + h + " " + x + " \" + Ypdf + \" cm /Im0 Do Q\";\n" +
        "var stream = d.addStream(ops, null);\n" +
        "var contents = pageObj.get(\"Contents\");\n" +
        "if (!contents || (contents.isNull && contents.isNull())) pageObj.put(\"Contents\", stream);\n" +
        "else if (contents.isArray && contents.isArray()) contents.push(stream);\n" +
        "else { var arr = d.newArray(); arr.push(contents); arr.push(stream); pageObj.put(\"Contents\", arr); }\n" +
        "p.update(); d.save(\"" + outPdfEsc + "\");\n";
    File.WriteAllText(scriptFile, js);
    RunHiddenCommand(Program.TOOL_PATH, "run \"" + scriptFile + "\"", Path.GetDirectoryName(Program.TOOL_PATH));
}

    private void OnBrowseCert(object sender, EventArgs e)
    {
        using (OpenFileDialog ofd = new OpenFileDialog())
        {
            ofd.Filter = "PFX Certificate|*.pfx|All files|*.*"; if (ofd.ShowDialog() == DialogResult.OK) txtCert.Text = ofd.FileName;
        }
    }

private void useEsign()
{
    // DDE should be ALWAYS ON fetch filename and page number
if (useImg) { if (!File.Exists(txtImage.Text)) { MessageBox.Show("Image file not found."); return; } }
if (!File.Exists(txtCert.Text)) { MessageBox.Show("PFX file not found."); return; }
    string path; int pageV; int pageP; double x; double y; double ypdf;
    DdeGetFileInfo(out path, out pageV, out pageP, out x, out y, out ypdf);
    inputPdf = path; pageNum = pageV;
    if (!path.EndsWith(".pdf", StringComparison.OrdinalIgnoreCase))
    {
        MessageBox.Show( "The current file is not a PDF.\n\nPlease open a PDF file before placing a Signature.",
        "Invalid File", MessageBoxButtons.OK, MessageBoxIcon.Warning );
        return;
    }
    if (string.IsNullOrWhiteSpace(txtOutput.Text)) { txtOutput.Text = path.Replace(".pdf", "-Signed.pdf"); }
    string outPath = txtOutput.Text.Trim();
/*
    if (!outPath.EndsWith("-Signed.pdf", StringComparison.OrdinalIgnoreCase)) txtOutput.Text = outPath.Replace(".pdf", "-Signed.pdf");
    if (string.Equals(inputPdf, txtOutput.Text, StringComparison.OrdinalIgnoreCase)) { outPath = inputPdf.Replace(".pdf", "-Signed.pdf"); txtOutput.Text = outPath; }
*/
    if (outPath.EndsWith("-Signed.pdf", StringComparison.OrdinalIgnoreCase)) { outPath = outPath.Substring(0, outPath.Length - "-Signed.pdf".Length) + ".pdf"; }
    txtOutput.Text = outPath.Replace(".pdf", "-Signed.pdf");
    lblMsg.Text = "Default = infile-Signed.PDF you can overwrite / change here.";
    if (!useImg) { ArmMsg("Click on a SignBox in PDF to place with TEXT"); ddeXYChangedCallback = GetBox; }
    else { ArmMsg("Click on a SignBox in PDF to place with Image"); ddeXYChangedCallback = GetBox; }
}
private void GetBox(object sender, EventArgs e)
{
// DONT     TryOpenOutputFile(pageNum);  // Try output file on same page BEFORE script and Reset UX
    unArm(); RunEsignScript();
    ddeXYChangedCallback = null; // Clear callback so future blur doesn’t reuse it accidentally
    TryOpenOutputFile(pageNum);  // Try result file AFTER script
}
private void RunEsignScript()
{
    string scriptFile = Path.Combine(Program.TEMP_PATH , "Esign.js"); string inPdfEsc = inputPdf.Replace("\\", "\\\\");
    string pfxEsc = txtCert.Text.Replace("\\", "\\\\"); string outPdfEsc = txtOutput.Text.Replace("\\", "\\\\");
    string imgObj; if (useImg) { string imgEsc = txtImage.Text.Replace("\\", "\\\\"); imgObj = "new mupdf.Image(\"" + imgEsc + "\")";} else { imgObj = "null"; }
    string Reason = string.IsNullOrWhiteSpace(Program.REASON) ? "null" : "\"" + Program.REASON + "\"";
    string Location = string.IsNullOrWhiteSpace(Program.LOCATION) ? "null" : "\"" + Program.LOCATION + "\"";
    string js =
        "var clickX=\"" + txtXpt.Text + "\";var clickY=\"" + txtYpt.Text + "\"; var d=mupdf.Document.openDocument(\"" + inPdfEsc + "\");\n" +
        "var p=d.loadPage(0); var widgets=p.getWidgets();var sigWidget=null; for(var i=0;i<widgets.length;i++){var w=widgets[i];\n" +
        "if(w.getFieldType()===\"signature\"){var r=w.getRect(); if(clickX>=r[0]&&clickX<=r[2]&&clickY>=r[1]&&clickY<=r[3]){sigWidget=w;break;}}}\n" +
        "if(!sigWidget)throw\"Click is outside any signature box\";\n" +
        "var signer=new PDFPKCS7Signer(\"" + pfxEsc + "\",\"" + txtPwd.Text + "\");\n" +
        "sigWidget.sign(signer,{showLabels:true,showGraphicName:true,showTextName:true,showDate:true}," + imgObj + "," + Reason + "," + Location + ");\n" +
        "d.save(\"" + outPdfEsc + "\");\n";
    File.WriteAllText(scriptFile, js);
    string result = RunHiddenCommand(Program.TOOL_PATH, "run \"" + scriptFile + "\"",Path.GetDirectoryName(Program.TOOL_PATH));
    try { File.Delete(scriptFile); } catch { }
    if (result.Contains("Click is outside any signature box")) { MessageBox.Show("Signature failed: click outside signature box."); return; }
    if (result.Contains("error")) { MessageBox.Show("Signature failed:\n" + result); return; }
}

    private void OnGetOutput(object sender, EventArgs e)
    {
        using (SaveFileDialog sfd = new SaveFileDialog())
        {
            sfd.Filter = "PDF files|*.pdf"; if (sfd.ShowDialog() == DialogResult.OK) txtOutput.Text = sfd.FileName;
        }
    }

    private void OnPut(object sender, EventArgs e)  // Redundant 
    {
        if (!File.Exists(txtImage.Text.Trim()))
        {
            MessageBox.Show("Please select a valid image file.", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error); return;
        }
        double x, y, w, h;
        if (!double.TryParse(txtXpt.Text.Trim(), out x) || !double.TryParse(txtYpt.Text.Trim(), out y) || !double.TryParse(txtW.Text.Trim(), out w) || !double.TryParse(txtH.Text.Trim(), out h))
        {
            MessageBox.Show("Position, Width and  Height, must be numeric.", "Error",
            MessageBoxButtons.OK, MessageBoxIcon.Error); return;
        }
        armed = true;
        ArmMsg("Click on PDF in view to place image");
    }
// End Class
}

public class HelpForm : Form
{
    public HelpForm()
    {
        // Basic form setup
        this.Text = "PDF Signnature Help"; this.Size = new Size(500, 400); this.StartPosition = FormStartPosition.CenterParent;
        this.FormBorderStyle = FormBorderStyle.FixedDialog; this.MaximizeBox = false; this.MinimizeBox = false; this.TopMost = true;
        TextBox helpBox = new TextBox(); helpBox.Multiline = true; helpBox.ReadOnly = true; helpBox.ScrollBars = ScrollBars.Vertical;
        helpBox.Dock = DockStyle.Fill; helpBox.Font = new Font("Segoe UI", 11); 
// when using "quotes in an @"... string always add as doubled ""
helpBox.Text = @"This tool allows you to place a digital signature box or apply image or digital signatures onto a PDF page.

Notes:
• The output filename is changed compared to the input name to avoid file locking. However if output is over 32 MB it will not be automatically opened.

• Any digital signing click must be inside a signature box (which is not always highlighted) but will be below and to the right of any pink ""Sign"" marker. If there are none you will need to use the ""Actions"" to add a ""Sign Box"" by x,y,W,H values or click an x,y position on the PDF.

• Signature boxes should be at least 6 times Width compared to their Height to work well since long text will wrap into more (smaller) lines.

• The box when signed will be divided in the middle with image on the left. So any signature Icon needed should be included to the right of the PNG image signature.

• The temporary script with password is deleted immediately for security, but check the %temp% folder does not have any residual ""Esign.js"".

        "; this.Controls.Add(helpBox); Button btnClose = new Button(); btnClose.Text = "Close"; btnClose.Dock = DockStyle.Bottom;
        btnClose.Height = 35; btnClose.Click += (s, e) => this.Close(); this.Controls.Add(btnClose); btnClose.Focus(); helpBox.TabStop = false;
    }
// EndClass
}

public static class DdeClient
{
    const int APPCLASS_STANDARD = 0x00000000; const int APPCMD_CLIENTONLY = 0x00000010; const int XTYP_REQUEST = 0x20B0; const int CF_UNICODETEXT = 13; const int TIMEOUT = 5000;
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
// EndClass
}