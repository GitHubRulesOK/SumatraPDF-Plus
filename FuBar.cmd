/*&cls&@echo off&Title "%~dpnx0" & REM SEE // USER CUSTOMISATION * BELOW if you wish to make changes before running this file

cd /d "%~dp0" & echo Compiling "%~dpn0.exe"
set "CSC=%SystemRoot%\Microsoft.NET\Framework\v4.0.30319\csc.exe"
if not exist "%CSC%" echo Compiler not found & pause & exit /b

::Prepare the Icon/BMP/ICO/PNG graphics as a 24 px X 24 px RAW PNG.Base64
>icon.b64 echo iVBORw0KGgoAAAANSUhEUgAAABgAAAAYCAYAAADgdz34AAAACXBIWXMAAA7EAAAOxAGVKw4bAAAAvElEQVRIiWNU2ujDQEvAgk3wnv+W/+QYprTRh5EoCxgYGBj+/yfNDkZGDLMZGBgYGJhIMoUMMGrBwFvAqLTRh+Fu3OVXDOc+izIY8b5m1F7eSC3DlcrbpkJ8ADWc4dxnUWoZDgMQC2CGG/G+prYFkIwGc/m5z6JKV9qm3vPf8p+cjKa00YfxXmdVNrI4nSJZ5xjcuYyxW3KoZTgikmkI6BNE6ICSSEYXH/pBNGoBQYCzTsZVx5IKsCZTagIA6K8628UfHS8AAAAASUVORK5CYII=
::Convert first into an App.ico and keep base64 for internal conversion
>makeico.cs echo using System; using System.IO; class M { static void Main() {
>>makeico.cs echo var p = Convert.FromBase64String(File.ReadAllText("icon.b64")); using (var f = File.Create("app.ico")) { f.Write(new byte[]{0,0,1,0,1,0,24,24,0,0,1,0,32,0},0,14); W(f,p.Length); W(f,22); f.Write(p,0,p.Length); } } static void W(Stream s,int v){s.WriteByte((byte)v);s.WriteByte((byte)(v^>^>8));s.WriteByte((byte)(v^>^>16));s.WriteByte((byte)(v^>^>24)); } }
"%CSC%" /nologo makeico.cs && makeico.exe && del makeico.cs makeico.exe
:: The app.ico AND Title icon.b64 can now be used by main compilation

"%CSC%"  /nologo /target:winexe /win32icon:app.ico /resource:icon.b64 /platform:x86 /out:"%~dpn0.exe" "%~dpnx0"

REM IMPORTANT we must pause and exit here before NOTES
pause & exit /b

NOTES:
 This Hybrid file is a working demonstration of SumatraPDF Plugin Overlay on canvas it compiles to an exe that can follow the  
 canvas area. It is simply providing a focal bar for reading.

 You may use this concept many other ways, but this is simply a demonstration for Windows 7+!

Simply bind the compiled exe to a shortcut in SumatraPDF settings. Like this:
ExternalViewers [
	[
		CommandLine = C:\path to your version\FuBar.exe
		Name = Focused &User Overlay
		Key = u
		ToolbarSvgIcon = <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"><rect width="24" height="24" fill="none"/><rect x="5" y="0" width="15" height="24" stroke="#000" stroke-width="1" fill="#fff" /><rect x="1" y="8" width="3" height="8" fill="#fd1"/><rect x="4" y="8" width="20" height="3" fill="#888"/><rect x="4" y="13" width="20" height="3" fill="#888"/><rect x="21" y="8" width="3" height="8" fill="#888"/><text x="1" y="12" font-size="6" font-family="sans-serif" fill="#f00">x</text></svg>
	]
]

*/
using System; using System.Drawing; using System.Text; using System.Windows.Forms; using System.Runtime.InteropServices;  using System.IO; using System.Reflection;

class Overlay : Form
{
    // ********************
    // USER CUSTOMISATION *
    // ********************
    // Focused User BAR
    public static int OVERLAY_OPACITY = 50;				// Percent
    public static int BAR_HEIGHT      = 160;				// Pixels
    public static Color BAR_COLOR     = Color.FromArgb(120,120,120);	// Only RGB 0-255
    public static int SLOT_HEIGHT     = 40;				// Pixels
    public static int SLOT_MARGIN     = 20;				// Pixels (slot width = W - SLOT_MARGIN x 2)
    public static Color GRIP_COLOR   = Color.FromArgb(255,200,10);	// Only RGB 0-255

    // Avoid altering these
    public static Color CLOSE_COLOR   = Color.Red;	// X CROSS colour
    public static int CLOSE_SIZE      = 20;		// Pixels
    public static int ANTI_JITTER     = 2;		// Pixels
    public static Color SLOT_COLOR    = Color.Magenta;	// Transparency key colour

    // INTERNAL
    [DllImport("user32.dll")] static extern IntPtr SetWindowsHookEx(int idHook, LowLevelMouseProc lpfn, IntPtr hMod, uint dwThreadId);
    [DllImport("user32.dll")] static extern bool UnhookWindowsHookEx(IntPtr hhk);
    [DllImport("user32.dll")] static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);
    [DllImport("kernel32.dll")] static extern IntPtr GetModuleHandle(string lpModuleName);
    [DllImport("user32.dll", CharSet = CharSet.Auto)] static extern IntPtr FindWindow(string c, string n);
    [DllImport("user32.dll")] static extern bool EnumChildWindows(IntPtr p, EnumChildProc cb, IntPtr l);
    delegate bool EnumChildProc(IntPtr h, IntPtr l);
    [DllImport("user32.dll", CharSet = CharSet.Auto)] static extern int GetClassName(IntPtr h, StringBuilder b, int n);
    [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr h, IntPtr ins, int X, int Y, int W, int H, uint f);
    const int WH_MOUSE_LL = 14; const int WM_LBUTTONDOWN = 0x201; const int WM_LBUTTONUP = 0x202;
    const int WM_MOUSEMOVE = 0x200; const uint SWP = 0x40 | 0x10;
    static readonly IntPtr TOP = new IntPtr(-1);
    [StructLayout(LayoutKind.Sequential)] struct POINT { public int x, y; }
    [StructLayout(LayoutKind.Sequential)] struct MSLLHOOKSTRUCT { public POINT pt; public uint mouseData; public uint flags; public uint time; public IntPtr dwExtraInfo; }
    struct RECT { public int L, T, R, B; }
    delegate IntPtr LowLevelMouseProc(int nCode, IntPtr wParam, IntPtr lParam);
    static LowLevelMouseProc mouseProc;
    static IntPtr mouseHook = IntPtr.Zero;
    Timer poll = new Timer();
    RECT canvas; bool hasCanvas = false; RECT lastOverlay; bool hasOverlay = false;
    int userOffset = -1; bool dragging = false; int dragStartY; int offsetStart;
    Rectangle handleZone;

    // FORM SETUP
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
    // READ the external icon.b64 convert and embed it replacing any internal methods
    var asm = Assembly.GetExecutingAssembly(); Image icon; using (var s = asm.GetManifestResourceStream("icon.b64"))
    using (var r = new StreamReader(s)) { byte[] png = Convert.FromBase64String(r.ReadToEnd()); using (var ms = new MemoryStream(png)) icon = Image.FromStream(ms); }
    using (var bmp = new Bitmap(icon)) this.Icon = Icon.FromHandle(bmp.GetHicon());

        FormBorderStyle = FormBorderStyle.None; ShowInTaskbar = true; TopMost = true;
        BackColor = SLOT_COLOR; TransparencyKey = SLOT_COLOR; Opacity = OVERLAY_OPACITY / 100.0;
        poll.Interval = 500;
        poll.Tick += (s,e)=>UpdateOverlay();
        poll.Start();
        mouseProc = MouseHookCallback;
        mouseHook = SetWindowsHookEx(WH_MOUSE_LL, mouseProc, GetModuleHandle(null), 0);
    }

    protected override void OnFormClosed(FormClosedEventArgs e) {
        if (mouseHook != IntPtr.Zero) UnhookWindowsHookEx(mouseHook); base.OnFormClosed(e);
    }

    // LOOK FOR CHILD CANVAS
    IntPtr FindCanvas() {
        IntPtr f = FindWindow("SUMATRA_PDF_FRAME", null);
        if (f == IntPtr.Zero) f = FindWindow("SumatraPDF", null);
        if (f == IntPtr.Zero) return IntPtr.Zero;
        IntPtr r = IntPtr.Zero;
        EnumChildWindows(f, (c,l)=>{
            var b = new StringBuilder(64);
            GetClassName(c,b,b.Capacity);
            if (b.ToString()=="SUMATRA_PDF_CANVAS") { r=c; return false; }
            return true;
        }, IntPtr.Zero);
        return r;
    }

    // POSITION OVERLAY
    void UpdateOverlay() {
        IntPtr c = FindCanvas(); if (c==IntPtr.Zero) return;
        RECT r; if (!GetWindowRect(c,out r)) return;
        canvas = r; hasCanvas = true; int W = r.R - r.L; int H = r.B - r.T;
        if (userOffset < 0) userOffset = (H/2 - BAR_HEIGHT/2);
        if (userOffset < 0) userOffset = 0;
        if (userOffset > H - BAR_HEIGHT) userOffset = H - BAR_HEIGHT;
        RECT newRect = new RECT { L = r.L, T = r.T + userOffset, R = r.L + W, B = r.T + userOffset + BAR_HEIGHT };
        if (hasOverlay) {
            bool changed =
                Math.Abs(newRect.L - lastOverlay.L) > ANTI_JITTER ||
                Math.Abs(newRect.T - lastOverlay.T) > ANTI_JITTER ||
                Math.Abs(newRect.R - lastOverlay.R) > ANTI_JITTER ||
                Math.Abs(newRect.B - lastOverlay.B) > ANTI_JITTER;
            if (!changed) return;
        }
        SetWindowPos(Handle, TOP, newRect.L, newRect.T, W, BAR_HEIGHT, SWP);
        lastOverlay = newRect; hasOverlay = true;
//        handleZone = new Rectangle( newRect.L, newRect.T + (BAR_HEIGHT/2 - 80), W, 160 );
        Invalidate();
    }

    // MOUSE HOOK
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
        if (!hasCanvas || !hasOverlay) return;
        Point p = new Point(pt.x, pt.y);
        // Recompute slot geometry is this required ?
        int slotW = lastOverlay.R - lastOverlay.L;
        int slotH = lastOverlay.B - lastOverlay.T;
        int slotMid = lastOverlay.T + (slotH / 2);
        int sw = slotW - SLOT_MARGIN * 2;
        int sh = SLOT_HEIGHT;
        int sx = lastOverlay.L + (slotW - sw) / 2;
        int sy = slotMid - sh/2;
        // Close button hit-test
        int barTop = lastOverlay.T;        // top of the bar
        Rectangle closeBox = new Rectangle(lastOverlay.L,barTop,CLOSE_SIZE,CLOSE_SIZE);
        if (msg == WM_LBUTTONDOWN && closeBox.Contains(p)) { Application.Exit(); return; }
        // Drag zone = grip bar only
        handleZone = new Rectangle( lastOverlay.L, lastOverlay.T, 20, BAR_HEIGHT );
        if (msg == WM_LBUTTONDOWN) {
            if (handleZone.Contains(p)) {
                dragging   = true;
                dragStartY = p.Y;
                offsetStart = userOffset;
            }
            return; 
        }
        else if (msg == WM_MOUSEMOVE && dragging) {
            int dy = p.Y - dragStartY;
            userOffset = offsetStart + dy;
            if (userOffset < 0) userOffset = 0;
            int H = canvas.B - canvas.T;
            if (userOffset > H - BAR_HEIGHT) userOffset = H - BAR_HEIGHT;
            IntPtr c = FindCanvas(); if (c==IntPtr.Zero) return;
            RECT r; if (!GetWindowRect(c,out r)) return;
            int W = r.R - r.L;
            int newY = r.T + userOffset;
            SetWindowPos(Handle, TOP, r.L, newY, W, BAR_HEIGHT, SWP);
            lastOverlay.L = r.L;
            lastOverlay.T = newY;
            lastOverlay.R = r.L + W;
            lastOverlay.B = newY + BAR_HEIGHT;
            hasOverlay = true;
        }
        else if (msg == WM_LBUTTONUP) {
            dragging = false;
        }
    }

// DRAWING
protected override void OnPaint(PaintEventArgs e)
{
    var g = e.Graphics;
    int W = Width, H = Height, mid = H / 2;
    // Bar (background)
    Rectangle barRect = new Rectangle(0, mid - (BAR_HEIGHT / 2), W, BAR_HEIGHT);
    using (var band = new SolidBrush(BAR_COLOR))
        g.FillRectangle(band, barRect);
    // Slot (transparent hole)
    int sw = W - SLOT_MARGIN * 2;
    int sh = SLOT_HEIGHT;
    int sx = (W - sw) / 2;
    int sy = mid - sh / 2;
    using (var er = new SolidBrush(SLOT_COLOR))
        g.FillRectangle(er, new Rectangle(sx, sy, sw, sh));
    // LEFT VERTICAL GRIP BAR (20px wide, now YELLOW)
    Rectangle gripRect = new Rectangle(0, barRect.Top, 20, BAR_HEIGHT);
    using (var grip = new SolidBrush(GRIP_COLOR))
        g.FillRectangle(grip, gripRect);
    // CLOSE BUTTON (top-left inside grip bar)
    int cy = barRect.Top + 0;
    using (var pen = new Pen(CLOSE_COLOR, 4))
    {
        g.DrawLine(pen, 0, cy, CLOSE_SIZE, cy + CLOSE_SIZE);
        g.DrawLine(pen, CLOSE_SIZE, cy, 0, cy + CLOSE_SIZE);
    }
}
    
    // MAIN
    [STAThread]
    static void Main() { Application.EnableVisualStyles(); Application.Run(new Overlay()); }
}
