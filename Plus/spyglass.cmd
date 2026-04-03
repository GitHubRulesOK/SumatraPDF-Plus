/*
C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc  /target:winexe /platform:x86 "%~0"  
exit /b

On doubleclick, this SpyGlass.CMD file becomes Spyglass.exe

The idea is to adda pointer magnification for use with SumatraPDF External Viewers.
See the example at https://github.com/sumatrapdfreader/sumatrapdf/issues/929#issuecomment-4181081913

It should be run from advanced settings entry pointing to the location of this exe.

I recommend keep the same Hot Key as it acts then as a Toggle On /Off.

ExternalViewers [
	[
		CommandLine = "C:\Users\WDAGUtilityAccount\Desktop\Apps\Programming\c#\microscope\spyglass.exe"
		Name = &Magnifier
		Filter = *.*
		Key = Ctrl + Alt + m
	]
]

*/
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;
using System.Windows.Forms;

class Spyglass : Form
{
    // Global hotkey registration if Esc does not work then use Ctrl + Alt + m
    [DllImport("user32.dll")]
    static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);
    [DllImport("user32.dll")]
    static extern bool UnregisterHotKey(IntPtr hWnd, int id);

    const uint MOD_ALT = 0x1;
    const uint MOD_CONTROL = 0x2;
    const int HOTKEY_ID = 1;
    float zoom = 2.0f;
    int lensSize = 250;
    // Offset so the lens never magnifies itself
    int offsetX = -256; int offsetY = -256;

    public Spyglass()
    {
        FormBorderStyle = FormBorderStyle.None; StartPosition = FormStartPosition.Manual;
        DoubleBuffered = true; TopMost = true; Width = Height = lensSize;
        ShowInTaskbar = true;   // Needed for failback refocus and closure
        SetCircleRegion();
        // Timer updates position + redraw
        var timer = new Timer();
        timer.Interval = 16; // 16 ~= 60 FPS
        timer.Tick += (s, e) =>
        {
            FollowCursor(); Invalidate();
        };
        timer.Start();
    }
    // Register Ctrl + Alt + M
    protected override void OnLoad(EventArgs e)
    {
        base.OnLoad(e); RegisterHotKey(Handle, HOTKEY_ID, MOD_CONTROL | MOD_ALT, (uint)Keys.M);
    }
    protected override void OnFormClosed(FormClosedEventArgs e)
    {
        UnregisterHotKey(Handle, HOTKEY_ID); base.OnFormClosed(e);
    }

    void SetCircleRegion()
    {
        using (GraphicsPath path = new GraphicsPath())
        {
            path.AddEllipse(0, 0, Width, Height); Region = new Region(path);
        }
    }

    void FollowCursor()
    {
        var c = Cursor.Position; Left = c.X + offsetX; Top = c.Y + offsetY;
    }

    protected override void WndProc(ref Message m)
    {
        if (m.Msg == 0x0312 && m.WParam.ToInt32() == HOTKEY_ID)
        {
            Close(); return;
        }
        base.WndProc(ref m);
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
        int w = Width; int h = Height; int srcW = (int)(w / zoom); int srcH = (int)(h / zoom);
        // Always magnify the area under the cursor
        Point cursor = Cursor.Position; int srcX = cursor.X - srcW / 2; int srcY = cursor.Y - srcH / 2;
        using (Bitmap bmp = new Bitmap(srcW, srcH))
        using (Graphics gSrc = Graphics.FromImage(bmp))
        {
            gSrc.CopyFromScreen(srcX, srcY, 0, 0, new Size(srcW, srcH));
            // Clip to circle
            using (GraphicsPath path = new GraphicsPath())
            {
                path.AddEllipse(0, 0, w, h); e.Graphics.SetClip(path);
            }
            e.Graphics.DrawImage(bmp, 0, 0, w, h);
        }
        // Draw border
        using (var pen = new Pen(Color.Black, 2))
            e.Graphics.DrawEllipse(pen, 1, 1, w - 2, h - 2);
    }

    [STAThread]
    static void Main()
    {
        Application.EnableVisualStyles(); Application.Run(new Spyglass());
    }
}
