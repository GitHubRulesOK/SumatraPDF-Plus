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

:: It should now be safe to delete the temporary graphics
del app.ico icon.b64

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
    // USER CUSTOMISATION * FOCUSed User BAR
    // ********************

    // WARNING:
    // Values that exceed (or are clamped to) the canvas height may reduce stability in drag behaviour or overlay visibility. Test carefully.

    public static int FOCUS_HEIGHT = 80;				// Pixels This is a START default use right click during runtime
    public static int FOG_HEIGHT   = 240;				// Pixels This is a START default use right click during runtime

    // THESE are FIXED values AT COMPILATION so adjust to your preferences
    // Settings related to visual impairment or DPI affecting the right-click dialog will generally be found at the end of this file
    public static int FOG_OPACITY  = 66;				// Percent
    public static Color FOG_TINT   = Color.FromArgb(120,240,120);	// Only RGB 0-255
    public static Color GRIP_TINT  = Color.FromArgb(255,200,10);	// Only RGB 0-255
    public static int GRIP_SIZE    = 20;		                // Pixels used for "Margin Width"

    // NOTE if or when using msg box for print debugging use this protected format
    // poll.Stop(); MessageBox.Show( "Blah =" + Blah ); poll.Start();
    // Avoid altering these
    public static Color EXIT_TINT  = Color.Red;		// X CROSS colour
    public static int ANTI_SHAKE   = 1;			// Pixels
    public static Color KEY_COLOR  = Color.Magenta;	// KEYHOLE colour (Transparent cutout)

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
    const int WM_MOUSEMOVE = 0x200; const uint SWP = 0x40 | 0x10; const int WM_RBUTTONDOWN = 0x0204;
    static readonly IntPtr TOP = new IntPtr(-1);
    [StructLayout(LayoutKind.Sequential)] struct POINT { public int x, y; }
    [StructLayout(LayoutKind.Sequential)] struct MSLLHOOKSTRUCT { public POINT pt; public uint mouseData; public uint flags; public uint time; public IntPtr dwExtraInfo; }
    struct RECT { public int L, T, R, B; }
    delegate IntPtr LowLevelMouseProc(int nCode, IntPtr wParam, IntPtr lParam);
    static LowLevelMouseProc mouseProc; static IntPtr mouseHook = IntPtr.Zero; static bool debugOnce = false;
    bool retryOnce = false; bool inSettings = false; bool dragging = false;
    Timer poll = new Timer();
    RECT canvas; bool hasCanvas = false; RECT lastOverlay; bool hasOverlay = false;
    private int fogTop; private int slotTop; int userOffset = -1; int dragStartY; int offsetStart; 

    // FORM SETUP
    protected override CreateParams CreateParams {
        get {
            const int WS_EX_LAYERED = 0x80000; const int WS_EX_TRANSPARENT = 0x20;
            var cp = base.CreateParams; cp.ExStyle |= WS_EX_LAYERED | WS_EX_TRANSPARENT;
            return cp;
        }
    }

    public Overlay() {
    // READ the external icon.b64 convert and embed it replacing any internal methods
    var asm = Assembly.GetExecutingAssembly(); Image icon; using (var s = asm.GetManifestResourceStream("icon.b64"))
    using (var r = new StreamReader(s)) { byte[] png = Convert.FromBase64String(r.ReadToEnd()); using (var ms = new MemoryStream(png)) icon = Image.FromStream(ms); }
    using (var bmp = new Bitmap(icon)) this.Icon = Icon.FromHandle(bmp.GetHicon());
        FormBorderStyle = FormBorderStyle.None; ShowInTaskbar = true; TopMost = true;
        BackColor = KEY_COLOR; TransparencyKey = KEY_COLOR; Opacity = FOG_OPACITY / 100.0;
        poll.Interval = 250;
        poll.Tick += (s,e)=>UpdateOverlay();
        //poll.Tick += (s,e) => { if (!needsUpdate) return; { UpdateOverlay(); needsUpdate = false;} };
        poll.Start();
        mouseProc = MouseHookCallback; mouseHook = SetWindowsHookEx(WH_MOUSE_LL, mouseProc, GetModuleHandle(null), 0);
    }

    protected override void OnFormClosed(FormClosedEventArgs e) {
        if (mouseHook != IntPtr.Zero) UnhookWindowsHookEx(mouseHook); base.OnFormClosed(e);
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

    void HandleMouse(int msg, POINT pt)
    {
        RECT r; GetWindowRect(this.Handle, out r);
        Point p = new Point(pt.x - r.L, pt.y - r.T);

    // Debug click this is not part of running code but a sanity check when testing so set it true by default 
    debugOnce = true; // comment this out for debugging
    if (!debugOnce && msg == WM_LBUTTONDOWN)
    {
        debugOnce = true;
        poll.Stop();
        MessageBox.Show(
            "WindowRect = " + r.L + "," + r.T + "," + r.R + "," + r.B +
            "\nMouseScreen = " + pt.x + "," + pt.y +
            "\nMouseLocal = " + p.X + "," + p.Y +
            "\nClientSize = " + this.ClientSize.Width + "," + this.ClientSize.Height
        );
        poll.Start();
    }

    // Close button always early
    Rectangle closeBox = new Rectangle(0, 0, GRIP_SIZE, GRIP_SIZE);
    if (msg == WM_LBUTTONDOWN && closeBox.Contains(p)) { Application.Exit(); return; }

    // No canvas = no drag
    if (!hasCanvas || !hasOverlay) return;
    Rectangle gripZone = new Rectangle(0, 0, GRIP_SIZE, FOG_HEIGHT);

    // RIGHT CLICK: ONLY inside grip zone
    int canvasHeight = canvas.B - canvas.T;
    if (msg == WM_RBUTTONDOWN)
    {
        if (gripZone.Contains(p))
        {
            inSettings = true; poll.Stop();
            using (var dlg = new OverlaySettingsForm(FOCUS_HEIGHT, FOG_HEIGHT, canvasHeight))
            {
                if (dlg.ShowDialog() == DialogResult.OK)
                {
                    FOCUS_HEIGHT = dlg.FocusHeight; FOG_HEIGHT = dlg.FogHeight; UpdateOverlay();
                }
            }
            inSettings = false; poll.Start();
        }
        return;
    }

    // LEFT CLICK: ONLY inside grip zone
    int canvasY = pt.y - canvas.T;
    if (msg == WM_LBUTTONDOWN)
    {
        if (gripZone.Contains(p)) { dragging = true; dragStartY = canvasY; offsetStart = userOffset; }
    }

    // Dragging: ONLY inside grip zone
    if (msg == WM_MOUSEMOVE && dragging)
    {
        int dy = canvasY - dragStartY;
        userOffset = offsetStart + dy;
        if (userOffset < 0) userOffset = 0;
        if (userOffset > (canvas.B - canvas.T) - FOCUS_HEIGHT) userOffset = (canvas.B - canvas.T) - FOCUS_HEIGHT;
        UpdateOverlay();
        return;
    }

    // Stop drag
    if (msg == WM_LBUTTONUP)
        dragging = false;
}


// POSITION OVERLAY
void UpdateOverlay()
{
// Re-check canvas exists per poll
IntPtr frame = FindWindow("SUMATRA_PDF_FRAME", null);
if (frame == IntPtr.Zero) frame = FindWindow("SumatraPDF", null);
IntPtr canvasHandle = IntPtr.Zero;
if (frame != IntPtr.Zero)
{
    EnumChildWindows(frame, (c, l) =>
    {
        var b = new StringBuilder(64); GetClassName(c, b, b.Capacity);
        if (b.ToString() == "SUMATRA_PDF_CANVAS") { canvasHandle = c; return false; }
        return true;
    }, IntPtr.Zero);
}

// If no usable canvas = warn user
if (!inSettings)
{
if (canvasHandle == IntPtr.Zero)
{
    poll.Stop();
    // FIRST FAILURE = show dialog
    if (!retryOnce)
    {
        var choice = MessageBox.Show(
            "SumatraPDF canvas not active.\n\nNO = abort overlay now\nYES = load a document then continue",
            "Canvas Missing", MessageBoxButtons.YesNo, MessageBoxIcon.Warning);
        if (choice == DialogResult.No) { Application.Exit(); return; }
        // User chose YES = allow ONE retry
        retryOnce = true; poll.Start(); return;
    }
    // SECOND FAILURE = abort automatically
    Application.Exit(); return;
    }
}
// Canvas exists = reset retry flag // Canvas exists = validate rect
retryOnce = false;
RECT r; GetWindowRect(canvasHandle, out r); canvas    = r; hasCanvas = true;

    // ----------------
    // GEOMETRY SECTION
    // ----------------
    int canvasTop    = canvas.T; int canvasBottom = canvas.B; int canvasHeight = canvasBottom - canvasTop;
    // TRAVEL RANGE
    slotTop = canvasTop + userOffset;
    float travel = canvasHeight - FOCUS_HEIGHT; float startFlat = FOG_HEIGHT / 2f; float endFlat = travel - FOG_HEIGHT / 2f;
    float t;
    if (userOffset < startFlat) t = 0.5f * (userOffset / startFlat);
    else if (userOffset > endFlat) t = 0.5f + 0.5f * ((userOffset - endFlat) / (travel - endFlat));
    else t = 0.5f;
    float gap = t * (FOG_HEIGHT - FOCUS_HEIGHT);
    fogTop = (int)(slotTop - gap);
    if (fogTop < canvasTop) fogTop = canvasTop;
    if (fogTop > canvasBottom - FOG_HEIGHT) fogTop = canvasBottom - FOG_HEIGHT;
    RECT newRect = new RECT { L = canvas.L, T = fogTop, R = canvas.L + (canvas.R - canvas.L), B = fogTop + FOG_HEIGHT };
    if (hasOverlay)
    {
        bool changed =
            Math.Abs(newRect.R - lastOverlay.R) > ANTI_SHAKE || Math.Abs(newRect.L - lastOverlay.L) > ANTI_SHAKE ||
            Math.Abs(newRect.T - lastOverlay.T) > ANTI_SHAKE || Math.Abs(newRect.B - lastOverlay.B) > ANTI_SHAKE;
        if (!changed)
            return;
    }
    SetWindowPos(Handle, TOP, newRect.L, newRect.T, newRect.R - newRect.L, FOG_HEIGHT, SWP);
    lastOverlay = newRect; hasOverlay  = true;
    Invalidate();
}


// DRAWING
protected override void OnPaint(PaintEventArgs e)
{
    var g = e.Graphics; int W = Width;

    // FOG is always drawn at Y=0 inside the overlay window
    Rectangle fogRect = new Rectangle(0, 0, W, FOG_HEIGHT);
    using (var band = new SolidBrush(FOG_TINT)) g.FillRectangle(band, fogRect);

    // FOCUS relative to fog
    int sy = slotTop - fogTop; int sx = GRIP_SIZE; int sw = W - GRIP_SIZE * 2; int sh = FOCUS_HEIGHT;
    using (var er = new SolidBrush(KEY_COLOR)) g.FillRectangle(er, new Rectangle(sx, sy, sw, sh));

    // Grip bar
    Rectangle gripRect = new Rectangle(0, 0, GRIP_SIZE, FOG_HEIGHT);
    using (var grip = new SolidBrush(GRIP_TINT)) g.FillRectangle(grip, gripRect);
    using (var pen = new Pen(EXIT_TINT, 4))
    {
        g.DrawLine(pen, 0, 0, GRIP_SIZE, GRIP_SIZE); g.DrawLine(pen, GRIP_SIZE, 0, 0, GRIP_SIZE);
    }
}

public class OverlaySettingsForm : Form
{
    public int FocusHeight { get; private set; } TrackBar tbFocus;
    public int FogHeight   { get; private set; } TrackBar tbSideFog;
    public OverlaySettingsForm(int currentFocus, int currentTotalFog, int canvasHeight)
    {
        this.AutoScaleMode = AutoScaleMode.Dpi;
        this.Font = new Font("Segoe UI", 14f, FontStyle.Bold);
        Text = "Overlay Settings"; BackColor = Color.Black; Width = 750; Height = 250;
        FormBorderStyle = FormBorderStyle.FixedDialog; StartPosition = FormStartPosition.CenterScreen;
        TopMost = true; ShowInTaskbar = true; MaximizeBox = false; MinimizeBox = false;

        // Compute temporary side fog from total fog height
        int tempSideFog = (currentTotalFog - currentFocus) / 2; if (tempSideFog < 10) tempSideFog = 10;

        // Focus label & slider
        Label lblFocus = new Label(); lblFocus.Text = "Aperture Height 20-500 (viewing slot in pixels) = " + currentFocus + " px";;
        lblFocus.Dock = DockStyle.Top; lblFocus.TextAlign = ContentAlignment.MiddleCenter; lblFocus.ForeColor = Color.White;
        tbFocus = new TrackBar(); tbFocus.Maximum = 500; tbFocus.Minimum = 20;   // SAFE MINIMUM
        tbFocus.Value = (currentFocus < 20 ? 20 : currentFocus); tbFocus.TickFrequency = 50; tbFocus.Dock = DockStyle.Top;
        tbFocus.TickStyle = TickStyle.TopLeft; lblFocus.Height = 24;
        tbFocus.Scroll += delegate
        {
            lblFocus.Text = "Aperture Height 20-500 (viewing slot in pixels) = " + tbFocus.Value + " px";
        };
        // Side fog label & slider
        Label lblFog = new Label(); lblFog.Text = "Side Masks 10 - 500 (shaded top + bottom in pixels) = " + tempSideFog + " px";
        lblFog.Dock = DockStyle.Top; lblFog.TextAlign = ContentAlignment.MiddleCenter; lblFog.ForeColor = Color.White;
        tbSideFog = new TrackBar(); tbSideFog.Maximum = 500; tbSideFog.Minimum = 10;   // SAFE MINIMUM
        tbSideFog.Value = tempSideFog; tbSideFog.TickFrequency = 50; tbSideFog.Dock = DockStyle.Top;
        tbSideFog.TickStyle = TickStyle.TopLeft; lblFog.Height = 24;
        tbSideFog.Scroll += delegate
        {
            lblFog.Text = "Side Masks 10 - 500 (shaded top + bottom in pixels) = " + tbSideFog.Value.ToString() + " px";
        };

        // Cancel button
        Button cancel = new Button(); cancel.Text = "Cancel"; cancel.Height = 40; cancel.BackColor = Color.DarkRed; cancel.ForeColor = Color.White;
        cancel.Dock = DockStyle.Bottom; cancel.Click += delegate
        {
            DialogResult = DialogResult.Cancel; Close();
        };
        // OK button
        Button ok = new Button(); ok.Text = "OK"; ok.Height = 40; ok.BackColor = Color.DarkGreen; ok.ForeColor = Color.White;
        ok.Dock = DockStyle.Bottom; ok.Click += delegate
        {
            int focus = tbFocus.Value; int sideFog = tbSideFog.Value;
// Clamp focus first
            int maxFocus = canvasHeight - (2 * 10);   // 10 = minimum side fog
            if (focus > maxFocus) focus = maxFocus;
// Clamp side fog next
            int maxSideFog = (canvasHeight - focus) / 2;
            if (sideFog > maxSideFog) sideFog = maxSideFog;
// Compute total fog height
            int totalFog = focus + sideFog + sideFog;
// Final clamp
            if (totalFog > canvasHeight) totalFog = canvasHeight;
            FocusHeight = focus; FogHeight   = totalFog;
            DialogResult = DialogResult.OK;
        Close();
        };

        // Add stacked in reverse order
        Controls.Add(ok); Controls.Add(cancel);
        Controls.Add(tbSideFog); Controls.Add(lblFog);
        Controls.Add(tbFocus); Controls.Add(lblFocus);
    }
}
    
    // MAIN
    [STAThread]
    static void Main() { Application.EnableVisualStyles(); Application.Run(new Overlay()); }
}
