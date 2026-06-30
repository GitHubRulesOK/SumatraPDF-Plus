/*
C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc /nologo /target:winexe /platform:x86 "%~0"
pause
exit /b
*/
using System; using System.Drawing; using System.Text; using System.Windows.Forms; using System.Runtime.InteropServices;

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
    public static int CLOSE_SIZE      = 20;				// Pixels
    public static Color ARROW_COLOR   = Color.FromArgb(255,200,10);	// Only RGB 0-255
    public static int ARROW_SIZE      = 40;				// half-height of arrow

    // Avoid altering these
    public static Color CLOSE_COLOR   = Color.Red;	// X CROSS colour
    public static Color SLOT_COLOR    = Color.Magenta;	// Transparency key colour
    public static int ANTI_JITTER     = 2;		// Pixels

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
        handleZone = new Rectangle( newRect.L, newRect.T + (BAR_HEIGHT/2 - 80), W, 160 );
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
        // Recompute slot geometry
        int slotW = lastOverlay.R - lastOverlay.L;
        int slotH = lastOverlay.B - lastOverlay.T;
        int slotMid = lastOverlay.T + (slotH / 2);
        int sw = slotW - SLOT_MARGIN * 2;
        int sh = SLOT_HEIGHT;
        int sx = lastOverlay.L + (slotW - sw) / 2;
        int sy = slotMid - sh/2;
        // Close button hit-test
        Rectangle closeBox = new Rectangle(sx + sw - (CLOSE_SIZE + 5), sy + 5, CLOSE_SIZE, CLOSE_SIZE);
        if (msg == WM_LBUTTONDOWN && closeBox.Contains(p)) { Application.Exit(); return; }
        // Drag zone refresh
        RECT o;
        GetWindowRect(this.Handle, out o);
        handleZone = new Rectangle( o.L, o.T + (BAR_HEIGHT/2 - 80), o.R - o.L, 160 );
        if (msg == WM_LBUTTONDOWN) {
            if (handleZone.Contains(p)) {
                dragging   = true;
                dragStartY = p.Y;
                offsetStart = userOffset;
            }
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
    protected override void OnPaint(PaintEventArgs e) {
        var g = e.Graphics;
        int W = Width, H = Height, mid = H/2;
        g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
        // Bar (background)
        using (var band = new SolidBrush(BAR_COLOR))
            g.FillRectangle(band, new Rectangle(0, mid-(BAR_HEIGHT/2), W, BAR_HEIGHT));
        // Slot
        int sw = W - SLOT_MARGIN * 2; int sh = SLOT_HEIGHT; int sx = (W - sw) / 2; int sy = mid - sh/2;
        using (var er = new SolidBrush(SLOT_COLOR))
            g.FillRectangle(er, new Rectangle(sx, sy, sw, sh));
        // Arrows
        using (var o = new Pen(Color.Black,6))
        using (var f = new SolidBrush(ARROW_COLOR)) {
            Point[] L = { new Point(16,mid), new Point(0,mid-ARROW_SIZE), new Point(0,mid+ARROW_SIZE) };
            Point[] R = { new Point(W-16,mid), new Point(W,mid-ARROW_SIZE), new Point(W,mid+ARROW_SIZE) };
            g.DrawPolygon(o,L); g.FillPolygon(f,L);
            g.DrawPolygon(o,R); g.FillPolygon(f,R);
        }
        // Close button
        int cx = sx + sw - (CLOSE_SIZE + 5); int cy = sy + 5;
        using (var pen = new Pen(CLOSE_COLOR, 4)) {
            g.DrawLine(pen, cx, cy, cx+CLOSE_SIZE, cy+CLOSE_SIZE); g.DrawLine(pen, cx+CLOSE_SIZE, cy, cx, cy+CLOSE_SIZE);
        }
    }
    
    // MAIN
    [STAThread]
    static void Main() { Application.EnableVisualStyles(); Application.Run(new Overlay()); }
}
