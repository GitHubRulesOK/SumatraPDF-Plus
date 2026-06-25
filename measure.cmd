/*&cls&@echo off&Title SumatraPDF+ Measure Tool

cd /d "%~dp0" & echo Compiling "%~dpn0.exe"
set "CSC=%SystemRoot%\Microsoft.NET\Framework\v4.0.30319\csc.exe"
if not exist "%CSC%" echo Compiler not found & pause & exit /b
"%CSC%" /nologo /target:winexe /platform:x86 /out:"%~dpn0.exe" "%~dpnx0"

REM IMPORTANT we pause and exit here
pause & exit /b

NOTES:
This CMD file is a working demonstration of SumatraPDF DDE [GetMousePos] which returns points.
On running the cmd in Windows 7+ it compiles an exe that can be used to measure page data. 
Simply bind the exe to a shortcut in SumatraPDF settings. Like this:

ExternalViewers [
	[
		CommandLine = "C:\Users\ your chosen folder \measure.exe"
		Name = &Measure Tool
		Filter = *.*
		Key = m
                ToolbarSvgIcon = <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" stroke-width="1" fill="#FFEE00" stroke-linecap="round" stroke-linejoin="round"><rect x="0" y="0" width="24" height="24" stroke="none"/><path d="M0 18h24 M0 18L17 1 M0.5 18v6 M8 18v3 M16 18v6 M23.5 18v3" stroke="blue"/><path d="M0 18 L21 18 A21 21 0 0 0 15 3 Z" fill="red" fill-opacity="0.4" stroke="green"/><text fill="black" stroke-width="0.25" font-size="8" font-family="sans-serif" x="7" y="16">45°</text></svg>
	]
]

You can edit this file in MS Notepad and re-run with changes, but not while the current one is active !
For example rather than cartographic degrees orientation, if you wanted mariners bearings you can edit.
"\r\nDist: " + dist_u.ToFixed(3) + " " + unit + "  Deg.: " + angleDeg.ToFixed(3) + "°" +
to 
"\r\nDist: " + dist_u.ToFixed(3) + " " + unit + "  Deg.: " + bearing.ToFixed(3) + "°" +

*/
using System; using System.Collections.Generic; using System.Drawing; using System.Runtime.InteropServices; using System.Text; using System.Windows.Forms; using System.IO;

class MeasureForm : Form
{
    // window dragging
    [DllImport("user32.dll")] private static extern bool ReleaseCapture();
    [DllImport("user32.dll")] private static extern int SendMessage(IntPtr hWnd, int Msg, int wParam, int lParam);
    private const int WM_NCLBUTTONDOWN = 0xA1; private const int HTCAPTION = 0x2;

    // DDE
    private delegate IntPtr DdeCallback( int uType, int uFmt, IntPtr hConv, IntPtr hsz1, IntPtr hsz2, IntPtr hData, IntPtr dwData1, IntPtr dwData2);
    private static readonly DdeCallback ddeCallback = DdeCallbackProc;
    [DllImport("user32.dll", CharSet = CharSet.Unicode, EntryPoint = "DdeInitializeW")]
    private static extern int DdeInitializeW(out IntPtr pidInst, DdeCallback pfnCallback, int afCmd, int ulRes);
    [DllImport("user32.dll", CharSet = CharSet.Unicode, EntryPoint = "DdeCreateStringHandleW")]
    private static extern IntPtr DdeCreateStringHandleW(IntPtr idInst, string psz, int iCodePage);
    [DllImport("user32.dll")] private static extern IntPtr DdeConnect(IntPtr idInst, IntPtr hszService, IntPtr hszTopic, IntPtr pCC);
    [DllImport("user32.dll")]
    private static extern IntPtr DdeClientTransaction( byte[] pData, int cbData, IntPtr hConv, IntPtr hszItem, int wFmt, int wType, int dwTimeout, out int pdwResult);
    [DllImport("user32.dll")] private static extern int DdeGetData(IntPtr hData, byte[] pDst, int cbMax, int cbOff);
    [DllImport("user32.dll")] private static extern bool DdeDisconnect(IntPtr hConv);
    [DllImport("user32.dll")] private static extern bool DdeFreeStringHandle(IntPtr idInst, IntPtr hsz);
    [DllImport("user32.dll")] private static extern bool DdeUninitialize(IntPtr idInst);
    private static IntPtr DdeCallbackProc( int uType, int uFmt, IntPtr hConv, IntPtr hsz1, IntPtr hsz2, IntPtr hData, IntPtr dwData1, IntPtr dwData2) { return IntPtr.Zero; }

    // mouse hook
    private const int WH_MOUSE_LL = 14; private const int WM_LBUTTONDOWN = 0x0201;
    private delegate IntPtr LowLevelMouseProc(int nCode, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelMouseProc lpfn, IntPtr hMod, uint dwThreadId);
    [DllImport("user32.dll")] private static extern bool UnhookWindowsHookEx(IntPtr hhk);
    [DllImport("user32.dll")] private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);
    [DllImport("kernel32.dll")] private static extern IntPtr GetModuleHandle(string lpModuleName);
    private IntPtr hookId = IntPtr.Zero; private LowLevelMouseProc hookCallback;

    // UX
    private TextBox ratioBox; private TextBox unitBox; private TextBox outputLabel;
    private Button calibrateButton; private Button ptButton, pxButton, mmButton, cmButton, inButton; private Button armButton;
    private CheckBox ypdfCheck;

    // states
    private bool calibrationMode = false; private bool armed = false; private int clickIndex = 0;
    private struct Pt { public double x; public double y; }
    private List<Pt> points = new List<Pt>();
    public MeasureForm()
    {
        this.FormBorderStyle = FormBorderStyle.None; this.TopMost = true;
        this.BackColor = Color.FromArgb(34, 34, 34); this.ForeColor = Color.White; // this.Opacity = 0.70;
        this.Size = new Size(260, 260); this.StartPosition = FormStartPosition.CenterScreen;

        this.Font = new Font("Segoe UI", 12, FontStyle.Regular);
        // top bar
        Panel bar = new Panel { Height = 28, Dock = DockStyle.Top, BackColor = Color.FromArgb(50, 50, 50) };
        Controls.Add(bar);
        string b64 = "iVBORw0KGgoAAAANSUhEUgAAABwAAAAcCAMAAABF0y+mAAAAe1BMVEU9SsrFenMAAP/4+PgAAACCprerkmj9mZr/yQ8/SMwYixiVxpUjjyNOjDZlr2W83bweih7ClHgsiyPHlXWq1KosiB6LilpQo0sJhQk/ijDS6NLs9Ozq9OpdjjxxjUhxjUbG3sYPgRIeixqdzp2PyI8AAP1lPzw8JyNCLSpOv0WrAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAArElEQVQoU5XSVw7DIBAEUHDAm03vvff7nzBLDbYBK/NB0dMgkGDdTNifKDGNEsskBtZAidddCqlX3g5xJAM4r6OoDWC5iKA1mPc6DXQGMOzX8WcwndRQmQBB4YLPxhXURkg9GlejEG1PNYGaMAjQmO5xNcBm71HfRbzeH+Fwe3Ho76mP5Wp1vFsM3uBzehhkDJFF047mNfX5qbEwG8TqXOQQQ3RB//naMJMsfgGbDxdi6sc/EAAAAABJRU5ErkJggg=="; // base64 PNG
        byte[] bytes = Convert.FromBase64String(b64);
        MemoryStream ms = new MemoryStream(bytes); Image icon = Image.FromStream(ms);
        PictureBox pic = new PictureBox { Image = icon, Size = new Size(28, 28), Location = new Point(2, 2), BackColor = Color.Transparent };
        bar.Controls.Add(pic);
        Label title = new Label { Text = "Chart-o-graphic Measure", Left = 32, Top = 6, ForeColor = Color.White }; title.Width = 200; 
        bar.Controls.Add(title);
        foreach (Control c in bar.Controls)
        {
          c.MouseDown += (s, e) =>
          {
          if (e.Button == MouseButtons.Left) { ReleaseCapture(); SendMessage(Handle, WM_NCLBUTTONDOWN, HTCAPTION, 0); }
          };
        }
        Label close = new Label { Text = "X", Width = 28, Height = 28, Dock = DockStyle.Right, TextAlign = ContentAlignment.MiddleCenter, ForeColor = Color.White };
        close.MouseEnter += (s, e) => close.BackColor = Color.FromArgb(200, 50, 50); close.MouseLeave += (s, e) => close.BackColor = Color.FromArgb(50, 50, 50);
        close.Click += (s, e) => Close();
        bar.Controls.Add(close);

        int margin = 6;
        int offsetY = 30;
        // ratio row
        Label ratioLabel = new Label();
        ratioLabel.Text = "Ratio:";
        ratioLabel.Location = new Point(10, margin + offsetY);
        ratioLabel.AutoSize = true;
        this.Controls.Add(ratioLabel);
        ratioBox = new TextBox();
        ratioBox.Text = "72";
        ratioBox.Location = new Point(60, margin + offsetY);
        ratioBox.Width = 95;
        this.Controls.Add(ratioBox);
        calibrateButton = new Button();
        calibrateButton.Text = "Calibrate";
        calibrateButton.Location = new Point(160, margin + offsetY - 1);
        calibrateButton.Width = 85;
        calibrateButton.Height = 30;
        calibrateButton.Click += CalibrateClick;
        this.Controls.Add(calibrateButton);
        // unit row
        Label unitLabel = new Label();
        unitLabel.Text = "Unit:";
        unitLabel.Location = new Point(10, 42 + offsetY);
        unitLabel.AutoSize = true;
        this.Controls.Add(unitLabel);
        unitBox = new TextBox();
        unitBox.Text = "pt";
        unitBox.Location = new Point(60, 40 + offsetY);
        unitBox.Width = 52;
        this.Controls.Add(unitBox);
        inButton = MakeUnitButton("in", 115, 40 + offsetY);
        inButton.Height = 30;
        ptButton = MakeUnitButton("pt", 160, 40 + offsetY);
        ptButton.Height = 30;
        mmButton = MakeUnitButton("mm", 200, 40 + offsetY);
        mmButton.Font = new Font("Segoe UI", 11f);
        mmButton.Width = 45;
        mmButton.Height = 30;
        // get points row
        armButton = new Button();
        armButton.Text = "Get point(s)";
        armButton.Location = new Point(8, 74 + offsetY);
        armButton.Width = 100;
        armButton.Height = 30;
        armButton.Click += ArmGetPos;
        this.Controls.Add(armButton);
        ypdfCheck = new CheckBox();
        ypdfCheck.Text = "Y^";
        ypdfCheck.Checked = true;
        ypdfCheck.ForeColor = Color.White;
        ypdfCheck.BackColor = Color.FromArgb(34, 34, 34);
        ypdfCheck.Location = new Point(112, 78 + offsetY);
        ypdfCheck.AutoSize = true;
        this.Controls.Add(ypdfCheck);
        pxButton = MakeUnitButton("px", 160, 74 + offsetY);
        pxButton.Height = 30;
        cmButton = MakeUnitButton("cm", 200, 74 + offsetY);
        cmButton.Width = 45;
        cmButton.Height = 30;
        // output
        outputLabel = new TextBox();
        outputLabel.Location = new Point(10, 110 + offsetY);
        outputLabel.Width = 235;
        outputLabel.Height = 110;
        outputLabel.Multiline = true;
        outputLabel.ShortcutsEnabled = true;
        outputLabel.TabStop = true;
        outputLabel.Cursor = Cursors.IBeam;
        outputLabel.BorderStyle = BorderStyle.FixedSingle;
        outputLabel.BackColor = Color.FromArgb(20, 20, 20);
        outputLabel.ForeColor = Color.White;
        outputLabel.Font = new Font("Segoe UI", 12f);
        this.Controls.Add(outputLabel);
        outputLabel.Click += (s, e) =>
        {
            if (calibrationMode && !armed) { armed = true; outputLabel.Text =  "Click 1st calibration point."; }
        };
        SetUnit("pt"); // default for user but in theory all ratios are based on 1:1 inches
        ShowStartupText(); // default to the text used for get points
    }
    //end of form builder
    // add button helper.. Hmm should it default different x,y,w,h may be better
    private Button MakeUnitButton(string text, int x, int y)
    {
        Button b = new Button(); b.Text = text; b.Location = new Point(x, y); b.Width = 40; b.Height = 26;
        b.Click += (s, e) => SetUnit(text); this.Controls.Add(b); return b;
    }

    private void ShowStartupText()
    {
        outputLabel.Text =
            "To start use \"Get point(s)\" THEN\r\nClick document for 1st location" +
            "\r\n To change units or ratio enter" +
            "\r\n values above or click a units" +
            "\r\n button, & Get point(s) again.";
    }

    // unit + ratio
    private void SetUnit(string u)
    {
        unitBox.Text = u;
        if (u == "px") ratioBox.Text = "96";
        if (u == "pt") ratioBox.Text = "72";
        if (u == "mm") ratioBox.Text = "25.4";
        if (u == "cm") ratioBox.Text = "2.54";
        if (u == "in") ratioBox.Text = "1";
    }

    private double ConvertPt(double pt)
    {
        double ratio;
        if (!double.TryParse(ratioBox.Text, out ratio) || ratio == 0.000) ratio = 72.000;
        return pt * (ratio / 72.000);
    }

    private void ArmGetPos(object sender, EventArgs e)
    {
        calibrationMode = false;
        armed = true;
        clickIndex = 0;
        points.Clear();
        ShowStartupText();
        if (hookId != IntPtr.Zero) { UnhookWindowsHookEx(hookId); hookId = IntPtr.Zero; }
        hookCallback = MouseHookCallback;
        hookId = SetWindowsHookEx(WH_MOUSE_LL, hookCallback, GetModuleHandle(null), 0);
    }

    private void CalibrateClick(object sender, EventArgs e)
    {
        calibrationMode = true;
        armed = false;
        clickIndex = 0;
        points.Clear();
        outputLabel.Text =
            "Calibrate: Step 1\r\n" +
            "Change Unit: to known units.\r\n" +
            "Enter known length in ratio.\r\n" +
            "When done, click HERE to begin.";
        if (hookId != IntPtr.Zero) { UnhookWindowsHookEx(hookId); hookId = IntPtr.Zero; }
        hookCallback = MouseHookCallback;
        hookId = SetWindowsHookEx(WH_MOUSE_LL, hookCallback, GetModuleHandle(null), 0);
    }

    private IntPtr MouseHookCallback(int nCode, IntPtr wParam, IntPtr lParam)
    {
        if (nCode >= 0 && wParam == (IntPtr)WM_LBUTTONDOWN)
        {
            if (!armed) return CallNextHookEx(hookId, nCode, wParam, lParam);
            armed = false;
            string reply = DdeRequest("[GetMousePos]");
            if (string.IsNullOrEmpty(reply)) return CallNextHookEx(hookId, nCode, wParam, lParam);
            string[] lines = reply.Replace("\0", "").Split(new[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
            if (lines.Length < 3) return CallNextHookEx(hookId, nCode, wParam, lParam);
            double x = 0.000; double y = 0.000; double ypdf = 0.000;
            foreach (string line in lines)
            {
                string t = line.Trim();
                if (t.StartsWith("x:")) double.TryParse(t.Substring(2).Trim(), out x);
                else if (t.StartsWith("y:")) double.TryParse(t.Substring(2).Trim(), out y);
                else if (t.StartsWith("ypdf:")) double.TryParse(t.Substring(5).Trim(), out ypdf);
            }
            double yUse = ypdfCheck.Checked ? ypdf : y;
            Pt p = new Pt { x = x, y = yUse };
            points.Add(p);
            string unit = unitBox.Text;
            // calibration mode
            if (calibrationMode)
            {
                if (clickIndex == 0)
                {
                    string ratioText = ratioBox.Text;
                    outputLabel.Text =
                        "Now click  2nd" +
                        "\r\npoint at " + ratioText + " " + unit + " from" +
                        "\r\nthe first point. To reset click" +
                        "\r\ncalibrate button again.";
                    clickIndex = 1;
                    armed = true;
                    return CallNextHookEx(hookId, nCode, wParam, lParam);
                }
                if (clickIndex == 1 && points.Count >= 2)
                {
                    double dx = points[1].x - points[0].x;
                    double dy = points[1].y - points[0].y;
                    double raw = Math.Sqrt(dx * dx + dy * dy);
                    double guess;
                    if (double.TryParse(ratioBox.Text, out guess) && guess > 0)
                    {
                        double newRatio = (guess * 72.000) / raw;
                        ratioBox.Text = newRatio.ToFixed(6);
                        outputLabel.Text =
                            "Calibration complete.\r\n" +
                            "Measured: " + raw.ToFixed(4) + " units\r\n" +
                            "User says: " + guess.ToFixed(4) + " " + unit + "\r\n" +
                            "Scale: " + newRatio.ToFixed(6) + " " + unit + " per inch";
                    }
                    else
                    {
                        outputLabel.Text =
                            "No valid number entered.\r\nCalibration cancelled.";
                    }
                    calibrationMode = false;
                    clickIndex = 0;
                    points.Clear();
                    return CallNextHookEx(hookId, nCode, wParam, lParam);
                }
            }
            // normal mode
            if (clickIndex == 0)
            {
                double x1u = ConvertPt(p.x);
                double y1u = ConvertPt(p.y);
                outputLabel.Text =
                    "x1: " + x1u.ToFixed(4) + "  y1: " + y1u.ToFixed(4) +
                    "\r\n\r\n For distance, angle or area\r\n click on document at\r\n second point.";
                clickIndex = 1;
                armed = true;
            }
            else if (clickIndex == 1 && points.Count >= 2)
            {
                Pt p1 = points[0]; Pt p2 = points[1];
                double x1u = ConvertPt(p1.x); double y1u = ConvertPt(p1.y);
                double x2u = ConvertPt(p2.x); double y2u = ConvertPt(p2.y);
                double dx = p2.x - p1.x; double dy = p2.y - p1.y;
                double dist = Math.Sqrt(dx * dx + dy * dy);
                double dx_u = ConvertPt(dx); double dy_u = ConvertPt(dy);
                double dist_u = ConvertPt(dist);
                double angleRad = Math.Atan2(dy, dx);
                double angleDeg = angleRad * (180.0 / Math.PI); if (angleDeg < 0) angleDeg += 360.0;
                double bearing = 90.0 - angleDeg; if (bearing < 0) bearing += 360.0;
                double area_u = Math.Abs(dx_u * dy_u);
                outputLabel.Text =
                    "x1: " + x1u.ToFixed(4) + "   y1: " + y1u.ToFixed(4) +
                    "\r\nx2: " + x2u.ToFixed(4) + "   y2: " + y2u.ToFixed(4) +
                    "\r\ndx: " + dx_u.ToFixed(4) + "   dy: " + dy_u.ToFixed(4) +
                    "\r\nDist: " + dist_u.ToFixed(3) + " " + unit + "  Deg.: " + angleDeg.ToFixed(3) + "°" +
                    "\r\nArea: " + area_u.ToFixed(4) + " " + unit + "²";
                clickIndex = 0; points.Clear();
            }
        }
        return CallNextHookEx(hookId, nCode, wParam, lParam);
    }

    // DDE
    private string DdeRequest(string item)
    {
        const int APPCLASS_STANDARD = 0x00000000;
        const int APPCMD_CLIENTONLY = 0x00000010;
        const int XTYP_REQUEST = 0x20B0;
        const int CF_UNICODETEXT = 13;
        const int TIMEOUT = 5000;
        IntPtr inst;
        int ret = DdeInitializeW(out inst, ddeCallback, APPCLASS_STANDARD | APPCMD_CLIENTONLY, 0);
        if (ret != 0) return null;
        IntPtr hszService = DdeCreateStringHandleW(inst, "SUMATRA", 1200);
        IntPtr hszTopic = DdeCreateStringHandleW(inst, "control", 1200);
        IntPtr hszItem = DdeCreateStringHandleW(inst, item, 1200);
        IntPtr hConv = DdeConnect(inst, hszService, hszTopic, IntPtr.Zero);
        if (hConv == IntPtr.Zero)
        {
            DdeFreeStringHandle(inst, hszService);
            DdeFreeStringHandle(inst, hszTopic);
            DdeFreeStringHandle(inst, hszItem);
            DdeUninitialize(inst);
            return null;
        }
        int result;
        IntPtr hData = DdeClientTransaction(
            null, 0, hConv, hszItem,
            CF_UNICODETEXT, XTYP_REQUEST,
            TIMEOUT, out result);
        if (hData == IntPtr.Zero)
        {
            DdeDisconnect(hConv);
            DdeFreeStringHandle(inst, hszService);
            DdeFreeStringHandle(inst, hszTopic);
            DdeFreeStringHandle(inst, hszItem);
            DdeUninitialize(inst);
            return null;
        }
        int size = DdeGetData(hData, null, 0, 0);
        byte[] buffer = new byte[size];
        DdeGetData(hData, buffer, size, 0);
        string reply = Encoding.Unicode.GetString(buffer);
        reply = reply.TrimEnd('\0');
        DdeDisconnect(hConv);
        DdeFreeStringHandle(inst, hszService);
        DdeFreeStringHandle(inst, hszTopic);
        DdeFreeStringHandle(inst, hszItem);
        DdeUninitialize(inst);
        return reply;
    }
}

static class DoubleFormatExtensions
{
    public static string ToFixed(this double value, int decimals)
    {
        return value.ToString("F" + decimals);
    }
}

class Program
{
    [STAThread]
    static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new MeasureForm());
    }
}
