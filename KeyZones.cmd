/*&cls&@echo off&Title "%~dpnx0" & REM SEE // USER CUSTOMISATION * BELOW if you wish to make changes before running this file

cd /d "%~dp0" & echo Compiling "%~dpn0.exe"
set "CSC=%SystemRoot%\Microsoft.NET\Framework\v4.0.30319\csc.exe"
if not exist "%CSC%" echo Compiler not found & pause & exit /b

::Prepare the Icon/BMP/ICO/PNG graphics as a 24 px X 24 px RAW PNG.Base64
>icon.b64 echo iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAACXBIWXMAAA7EAAAOxAGVKw4bAAAAqElEQVRIiWNU2ujDQEvAgi5wz3/Lf0oMVNrow4jXAgYGBob/p97vJsdwRjNBV3QxrBYwMDAwMJgKYCjGC05/wOooJpIMIQPQ3ALcQcTAwMDIyIhPGg7+/8edLvBagE8jsYCFgYGB4e75BrhJjAxbKDIQ2SxlwwbGoR9Eo6mIIBgmQaRs2IBsElw1OUGEZtZwCSJyNBILBjCIcNRQVLEAW91KLmCkdbMFAOxQOQrYL9gMAAAAAElFTkSuQmCC
::Convert first into an App.ico and keep base64 for internal conversion
>makeico.cs echo using System; using System.IO; class M { static void Main() {
>>makeico.cs echo var p = Convert.FromBase64String(File.ReadAllText("icon.b64")); using (var f = File.Create("app.ico")) { f.Write(new byte[]{0,0,1,0,1,0,24,24,0,0,1,0,32,0},0,14); W(f,p.Length); W(f,22); f.Write(p,0,p.Length); } } static void W(Stream s,int v){s.WriteByte((byte)v);s.WriteByte((byte)(v^>^>8));s.WriteByte((byte)(v^>^>16));s.WriteByte((byte)(v^>^>24)); } }
"%CSC%" /nologo makeico.cs && makeico.exe && del makeico.cs makeico.exe
:: The app.ico AND Title icon.b64 can now be used by main compilation

"%CSC%"  /nologo /target:winexe /win32icon:app.ico /resource:icon.b64 /platform:x86 /out:"%~dpn0.exe" "%~dpnx0"

REM IMPORTANT we must pause and exit here before NOTES
pause & exit /b

NOTES:
 This Hybrid file is a working demonstration of SumatraPDF Plugin Overlay "On canvas" it compiles to an exe that can
 follow the canvas area. It is simply providing two click zones right and left "On Canvas" Key stroke actions.

 You may use this concept many other ways, but this is simply a demonstration for Windows 7+!

Simply bind the compiled exe to run shortcuts in SumatraPDF settings. Like this: where a b and c d are the keys you wish to action
These are single or multiple combinations, just like sendkeys.

ExternalViewers [
	[
		CommandLine = C:\path to your version\KeyZones.exe L="a,b" R="c,d"
		Name = Hot &Zones Overlay
		Key = z
		ToolbarSvgIcon = <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"><rect width="24" height="24" fill="none"/><rect x="5" y="0" width="15" height="24" fill="#fff" stroke="#000" stroke-width="1"/><rect x="1" y="8" width="3" height="8" fill="#f88"/><path d="M 7 6 L 18 6 M 7 9 L 18 9 M 7 12 L 18 12 M 7 15 L 18 15 M 7 18 L 18 18" stroke="#888"/><rect x="21" y="8" width="3" height="8" fill="#f88"/></svg>
	]
]

*/
using System;
using System.Drawing;
using System.Text;
using System.Windows.Forms;
using System.Runtime.InteropServices;
using System.IO;
using System.Reflection;

class Overlay : Form
{
    // ********************
    // USER CUSTOMISATION *
    // ********************

    public static int OVERLAY_OPACITY  = 25;
    public static int HOTZONE_HEIGHT   = 240;
    public static int HOTZONE_WIDTH    = 50;
    public static Color HOTZONE_COLOR  = Color.FromArgb(120,255,120);

    public static Color CLOSE_COLOR    = Color.Red;
    public static int CLOSE_SIZE       = 20;
    public static int ANTI_JITTER      = 2;
    public static Color TRANSPARENT_KEY = Color.Magenta;

    public static string LEFT_HOTKEY  = "p";   // default, can be overridden by L="..."
    public static string RIGHT_HOTKEY = "n";   // default, can be overridden by R="..."

    // ============================
    // INTERNAL
    // ============================

    [DllImport("user32.dll")] static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
    const uint WM_KEYDOWN = 0x0100;
    const uint WM_KEYUP   = 0x0101;

    [DllImport("user32.dll")] static extern IntPtr SetWindowsHookEx(int idHook, LowLevelMouseProc lpfn, IntPtr hMod, uint dwThreadId);
    [DllImport("user32.dll")] static extern bool UnhookWindowsHookEx(IntPtr hhk);
    [DllImport("user32.dll")] static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);
    [DllImport("kernel32.dll")] static extern IntPtr GetModuleHandle(string lpModuleName);

    [DllImport("user32.dll", CharSet = CharSet.Auto)] static extern IntPtr FindWindow(string c, string n);
    [DllImport("user32.dll")] static extern IntPtr FindWindowEx(IntPtr parent, IntPtr childAfter, string className, string windowName);

    [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr h, IntPtr ins, int X, int Y, int W, int H, uint f);

    const int WH_MOUSE_LL = 14;
    const int WM_LBUTTONDOWN = 0x201;
    const uint SWP = 0x40 | 0x10;
    static readonly IntPtr TOP = new IntPtr(-1);

    [StructLayout(LayoutKind.Sequential)] struct POINT { public int x, y; }
    [StructLayout(LayoutKind.Sequential)] struct MSLLHOOKSTRUCT { public POINT pt; public uint mouseData; public uint flags; public uint time; public IntPtr dwExtraInfo; }
    struct RECT { public int L, T, R, B; }

    delegate IntPtr LowLevelMouseProc(int nCode, IntPtr wParam, IntPtr lParam);
    static LowLevelMouseProc mouseProc;
    static IntPtr mouseHook = IntPtr.Zero;

    Timer poll = new Timer();
    RECT lastOverlay;
    bool hasOverlay = false;

    Rectangle leftBarZone;
    Rectangle rightBarZone;

    // ============================
    // KEY PARSER (CSC-SAFE)
    // ============================

    static void ParseKey(string key, out int vk, out bool ctrl, out bool alt, out bool shift)
    {
        string lower = key.ToLower();

        ctrl  = lower.Contains("ctrl+");
        alt   = lower.Contains("alt+");
        shift = lower.Contains("shift+");

        string k = lower;
        k = k.Replace("ctrl+", "");
        k = k.Replace("alt+", "");
        k = k.Replace("shift+", "");
        k = k.Trim();

        vk = 0;

        if (k == "left") vk = 0x25;
        else if (k == "up") vk = 0x26;
        else if (k == "right") vk = 0x27;
        else if (k == "down") vk = 0x28;

        else if (k == "pgup") vk = 0x21;
        else if (k == "pgdn") vk = 0x22;
        else if (k == "home") vk = 0x24;
        else if (k == "end") vk = 0x23;
        else if (k == "tab") vk = 0x09;
        else if (k == "esc") vk = 0x1B;

        else if (k.StartsWith("f"))
        {
            int fn;
            if (int.TryParse(k.Substring(1), out fn))
            {
                if (fn >= 1 && fn <= 12)
                    vk = 0x70 + (fn - 1);
            }
        }
        else if (k.Length == 1)
        {
            vk = Char.ToUpper(k[0]);
        }
    }

    // ============================
    // FORM SETUP
    // ============================

    protected override CreateParams CreateParams {
        get {
            const int WS_EX_LAYERED = 0x80000;
            const int WS_EX_TRANSPARENT = 0x20;
            var cp = base.CreateParams;
            cp.ExStyle |= WS_EX_LAYERED | WS_EX_TRANSPARENT;
            return cp;
        }
    }

    public Overlay() {

        // Load icon from embedded base64
        var asm = Assembly.GetExecutingAssembly();
        Image icon;
        using (var s = asm.GetManifestResourceStream("icon.b64"))
        using (var r = new StreamReader(s)) {
            byte[] png = Convert.FromBase64String(r.ReadToEnd());
            using (var ms = new MemoryStream(png)) icon = Image.FromStream(ms);
        }
        using (var bmp = new Bitmap(icon)) this.Icon = Icon.FromHandle(bmp.GetHicon());

        FormBorderStyle = FormBorderStyle.None;
        ShowInTaskbar = true;
        TopMost = true;

        BackColor = TRANSPARENT_KEY;
        TransparencyKey = TRANSPARENT_KEY;
        Opacity = OVERLAY_OPACITY / 100.0;

        poll.Interval = 500;
        poll.Tick += (s,e)=>UpdateOverlay();
        poll.Start();

        mouseProc = MouseHookCallback;
        mouseHook = SetWindowsHookEx(WH_MOUSE_LL, mouseProc, GetModuleHandle(null), 0);
    }

    protected override void OnFormClosed(FormClosedEventArgs e) {
        if (mouseHook != IntPtr.Zero) UnhookWindowsHookEx(mouseHook);
        base.OnFormClosed(e);
    }

    // ============================
    // FIND SUMATRA CANVAS
    // ============================

    IntPtr FindCanvas() {
        IntPtr frame = FindWindow("SUMATRA_PDF_FRAME", null);
        if (frame == IntPtr.Zero)
            frame = FindWindow("SumatraPDF", null);
        if (frame == IntPtr.Zero)
            return IntPtr.Zero;

        return FindWindowEx(frame, IntPtr.Zero, "SUMATRA_PDF_CANVAS", null);
    }

    // ============================
    // SEND HOTKEY (SEQUENCES)
    // ============================

    void SendHotKey(string key)
    {
        IntPtr f = FindWindow("SUMATRA_PDF_FRAME", null);
        if (f == IntPtr.Zero)
            f = FindWindow("SumatraPDF", null);
        if (f == IntPtr.Zero)
            return;

        string[] parts = key.Split(',');

        foreach (string part in parts)
        {
            int vk;
            bool ctrl, alt, shift;

            ParseKey(part.Trim(), out vk, out ctrl, out alt, out shift);

            if (vk == 0) continue;

            if (ctrl)  PostMessage(f, WM_KEYDOWN, (IntPtr)0x11, IntPtr.Zero);
            if (alt)   PostMessage(f, WM_KEYDOWN, (IntPtr)0x12, IntPtr.Zero);
            if (shift) PostMessage(f, WM_KEYDOWN, (IntPtr)0x10, IntPtr.Zero);

            PostMessage(f, WM_KEYDOWN, (IntPtr)vk, IntPtr.Zero);
            PostMessage(f, WM_KEYUP,   (IntPtr)vk, IntPtr.Zero);

            if (shift) PostMessage(f, WM_KEYUP, (IntPtr)0x10, IntPtr.Zero);
            if (alt)   PostMessage(f, WM_KEYUP, (IntPtr)0x12, IntPtr.Zero);
            if (ctrl)  PostMessage(f, WM_KEYUP, (IntPtr)0x11, IntPtr.Zero);
        }
    }

    // ============================
    // POSITION OVERLAY
    // ============================

    void UpdateOverlay() {
        IntPtr c = FindCanvas();

        if (c == IntPtr.Zero) {
            poll.Stop();
            MessageBox.Show(
                "No SumatraPDF document is open.\n\n" +
                "Please open a document first, then restart the overlay.",
                "Overlay Disabled",
                MessageBoxButtons.OK,
                MessageBoxIcon.Warning);
            Application.Exit();
            return;
        }

        RECT r;
        if (!GetWindowRect(c, out r)) return;

        int W = r.R - r.L;
        int H = r.B - r.T;

        int autoY = r.T + (H / 2 - HOTZONE_HEIGHT / 2);

        RECT newRect = new RECT {
            L = r.L,
            T = autoY,
            R = r.L + W,
            B = autoY + HOTZONE_HEIGHT
        };

        if (hasOverlay) {
            bool changed =
                Math.Abs(newRect.L - lastOverlay.L) > ANTI_JITTER ||
                Math.Abs(newRect.T - lastOverlay.T) > ANTI_JITTER;

            if (!changed) return;
        }

        SetWindowPos(Handle, TOP, newRect.L, newRect.T, W, HOTZONE_HEIGHT, SWP);

        lastOverlay = newRect;
        hasOverlay = true;

        Invalidate();
    }

    // ============================
    // MOUSE HOOK
    // ============================

    static IntPtr MouseHookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
        if (nCode >= 0) {
            int msg = wParam.ToInt32();
            MSLLHOOKSTRUCT data = (MSLLHOOKSTRUCT)Marshal.PtrToStructure(lParam, typeof(MSLLHOOKSTRUCT));
            Overlay self = Application.OpenForms.Count > 0 ? Application.OpenForms[0] as Overlay : null;
            if (self != null) self.HandleMouse(msg, data.pt);
        }
        return CallNextHookEx(mouseHook, nCode, wParam, lParam);
    }

    void HandleMouse(int msg, POINT pt) {
        if (!hasOverlay) return;

        Point p = new Point(pt.x, pt.y);

        Rectangle closeBox = new Rectangle(lastOverlay.L, lastOverlay.T, CLOSE_SIZE, CLOSE_SIZE);
        if (msg == WM_LBUTTONDOWN && closeBox.Contains(p)) {
            Application.Exit();
            return;
        }

        if (msg == WM_LBUTTONDOWN && leftBarZone.Contains(p)) {
            SendHotKey(LEFT_HOTKEY);
            return;
        }

        if (msg == WM_LBUTTONDOWN && rightBarZone.Contains(p)) {
            SendHotKey(RIGHT_HOTKEY);
            return;
        }
    }

    // ============================
    // DRAW OVERLAY
    // ============================

    protected override void OnPaint(PaintEventArgs e)
    {
        var g = e.Graphics;
        int W = Width, H = Height, mid = H / 2;

        int barH = HOTZONE_HEIGHT;
        int barY = mid - (barH / 2);

        leftBarZone = new Rectangle(
            lastOverlay.L,
            lastOverlay.T + barY,
            HOTZONE_WIDTH,
            barH);

        rightBarZone = new Rectangle(
            lastOverlay.R - HOTZONE_WIDTH,
            lastOverlay.T + barY,
            HOTZONE_WIDTH,
            barH);

        Rectangle leftBar  = new Rectangle(0, barY, HOTZONE_WIDTH, barH);
        Rectangle rightBar = new Rectangle(W - HOTZONE_WIDTH, barY, HOTZONE_WIDTH, barH);

        using (var band = new SolidBrush(HOTZONE_COLOR))
        {
            g.FillRectangle(band, leftBar);
            g.FillRectangle(band, rightBar);
        }

        using (var pen = new Pen(CLOSE_COLOR, 4))
        {
            g.DrawLine(pen, 0, 0, CLOSE_SIZE, CLOSE_SIZE);
            g.DrawLine(pen, CLOSE_SIZE, 0, 0, CLOSE_SIZE);
        }
    }

    // ============================
    // MAIN
    // ============================

    [STAThread]
    static void Main(string[] args)
    {
        // Defaults already set; allow overrides via args: L="..." R="..."
        foreach (var a in args)
        {
            if (a.StartsWith("L=", StringComparison.OrdinalIgnoreCase))
                LEFT_HOTKEY = a.Substring(2).Trim('"');

            if (a.StartsWith("R=", StringComparison.OrdinalIgnoreCase))
                RIGHT_HOTKEY = a.Substring(2).Trim('"');
        }

        Application.EnableVisualStyles();
        Application.Run(new Overlay());
    }
}
