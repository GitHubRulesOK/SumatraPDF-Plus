/*&cls&echo off
REM IMPORTANT DO NOT remove the c# comment marker above (/*) even though CMD will grumble that it is not a command
C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc /nologo /target:winexe /platform:x86 "%~0"

Echo if no error messages show then this cmd should have built built "%~dpn0.exe"
if exist "%~dpn0.exe" echo "%~dpn0.exe" is now present so needs copy to the SumatraPDF settings folder.
pause

REM IMPORTANT We use exit cmd before the NOTE:s
exit /b

NOTE: On Windows 7, system fonts may be configured above 100%. This can make the compact form appear overcrowded.
      Adjust the compensation factor below if necessary. SEE BELOW  // User-adjustable font scale. 
      Designed to be built as one common Windows 7+ x32/x64 exe that can used with installed or portable SumatraPDF
      via  externalviewers i.e. including versions 3.1 and above that support the command line (Win XP not tested)

After running this SettingsMgr.CMD file in Windows, it generates SettingsMgr.exe.

This manager exe allows you to save the current SumatraPDF settings as a named, dated backup, or
restore a previously saved version, or delete an unwanted backup SumatraPDF-settings.txt.

PURPOSE:
Modern SumatraPDF 3.7 can have multiple tab groups that can be "Hot Swapped" during a session, but if a user wants
very large groups to be changed say per topic then the recommended historic way is using -appdata settings folders.
Note they too can have "subgroups" of saved and or restored tab sets.

With many such sets that can lead to a settings management problem which this file reduces by allow many settings
in user folder with timestamps and descriptions. However note that same as launching multiple -appdata folders, this
manager needs to close and reopen large replacement settings files to ensure as robust a similar system experience.

It is intended to be launched from a SumatraPDF Advanced Settings ExternalViewers entry, but can also
be run directly. Naturally to be run from a settings file it needs to be added to each.

Important configuration:

Edit the example below to use your own Windows account name.
The first quoted parameter is the executable path.
The second quoted parameter is the target folder containing SumatraPDF-settings.txt.

SumatraPDF passes the currently viewed document filename to external viewers. Consequently, the this manager
must use the supplied second parameter for its settings folder, rather than interpreting the first received
argument as that folder. Both paths should be edited to suit your installation.

For an installed copy, the settings folder is usually under your own user profile in AppData\Local\SumatraPDF.

Edit this into your Advance Settings and on first run use this manager to save with a description e.g. With-SettingsMgr 

ExternalViewers [
	[
		CommandLine = "C:\Users\Account Name\AppData\Local\SumatraPDF\SettingsMgr.exe" "C:\Users\Account Name\AppData\Local\SumatraPDF"
		Name = &Settings Manager
		Key = s
		ToolbarSvgIcon = <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="none"><path d="M0 0h24v24H0z"/><path stroke="currentColor" d="M9.5 3.5a2.5 2.5 0 0 1 5 0 2.5 2.5 0 0 0 3.5 2 1 1 0 0 1 2.5 4.5 2.5 2.5 0 0 0 0 4 1 1 0 0 1-2.5 4.5 2.5 2.5 0 0 0-3.5 2 1 1 0 0 1-5 0 2.5 2.5 0 0 0-3.5-2A1 1 0 0 1 3.5 14a2.5 2.5 0 0 0 0-4A1 1 0 0 1 6 5.5a2.5 2.5 0 0 0 3.5-2M9 12a3 3 0 0 1 6 0 3 3 0 0 1-6 0"/></svg>
	]
]

Important do not remove this next line as it marks the start of the executable code
*/
using System; using System.Globalization; using System.Drawing; using System.Drawing.Drawing2D; using System.Windows.Forms;
using System.IO; using System.Diagnostics; using System.Runtime.InteropServices; using System.Text; using System.ComponentModel;

public class SettingsManager : Form
{
    // User-adjustable font scale.
    // 100F = no compensation, normal (100%)        80F  = compensates for Windows 125% fonts
    // 66.6F = compensates for Windows 150% fonts   50F  = compensates for Windows 200% fonts
    const float FontScale = 100F;

    // Automatically close the SumatraPDF instance that launched this manager before Store or Restore.
    static bool CloseParentSumatraBeforeOperation = true;

    // Restart SumatraPDF after a successful Store or Restore.
    const bool RestartSumatraAfterOperation = true;

    // Retain the SumatraPDF executable location once discovered.
    string sumatraExePath = null;
    string folder;
    const string Original = "SumatraPDF-settings.txt";
    const string Prefix = "SumatraPDF-settings-";
    const string Suffix = ".txt";
    const int CornerRadius = 16;

    Button closeButton;
    TextBox descriptionBox;
    ListBox backups;
    Label statusLabel;
    Button restoreButton;
    Button storeButton;
    Button deleteButton;

    // Windows process identification. Used to identify the parent process that launched SettingsMgr.exe.
    const uint TH32CS_SNAPPROCESS = 0x00000002;
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)] struct PROCESSENTRY32
    {
        public uint dwSize; public uint cntUsage; public uint th32ProcessID;
        public IntPtr th32DefaultHeapID; public uint th32ModuleID; public uint cntThreads;
        public uint th32ParentProcessID; public int pcPriClassBase; public uint dwFlags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)] public string szExeFile;
    }
    [DllImport("kernel32.dll", SetLastError = true)] static extern IntPtr CreateToolhelp32Snapshot(uint dwFlags, uint th32ProcessID);
    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)] static extern bool Process32First(IntPtr hSnapshot, ref PROCESSENTRY32 lppe);
    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)] static extern bool Process32Next(IntPtr hSnapshot, ref PROCESSENTRY32 lppe);
    [DllImport("kernel32.dll", SetLastError = true)] static extern bool CloseHandle(IntPtr hObject);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)] 
    static extern bool QueryFullProcessImageName(IntPtr hProcess, int dwFlags, StringBuilder lpExeName, ref int lpdwSize);

    class BackupItem
    {
        public string FileName; public string DisplayName;
        public BackupItem(string fileName)
        {
            FileName = fileName;
            string name = Path.GetFileNameWithoutExtension(fileName);
            if (name.StartsWith(Prefix, StringComparison.OrdinalIgnoreCase))
                name = name.Substring(Prefix.Length);
            DisplayName = name;
        }

        public override string ToString()
        {
            return DisplayName;
        }
    }

    public SettingsManager(string targetFolder)
    {
        folder = Path.GetDirectoryName(Application.ExecutablePath);
        if (!string.IsNullOrWhiteSpace(targetFolder)) folder = Environment.ExpandEnvironmentVariables(targetFolder.Trim().Trim('"'));
        folder = Path.GetFullPath(folder);
        if (!Directory.Exists(folder)) throw new DirectoryNotFoundException("Settings folder does not exist:\n\n" + folder);
        FormBorderStyle = FormBorderStyle.None; StartPosition = FormStartPosition.CenterScreen; this.TopMost = true; 
        BackColor = Color.FromArgb(32, 32, 32); ForeColor = Color.White;
        ClientSize = new Size(350, 300); MinimumSize = new Size(350, 300); MaximumSize = new Size(350, 300);
        DoubleBuffered = true;
        Font = ScaledFont("Segoe UI", 9F);
        CreateUI();
        RefreshBackups();
    }

    Font ScaledFont(string family, float size, FontStyle style = FontStyle.Regular)
    {
        return new Font(family, size * FontScale / 100F, style);
    }

    static bool TryGetParentProcess(out int parentPid, out string parentExe, out string parentPath)
    {
        parentPid = 0; parentExe = null; parentPath = null;
        uint currentPid = (uint)Process.GetCurrentProcess().Id;
        IntPtr snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
        if (snapshot == IntPtr.Zero || snapshot == new IntPtr(-1))return false;
        try
        {
            PROCESSENTRY32 entry = new PROCESSENTRY32();
            entry.dwSize = (uint)Marshal.SizeOf(typeof(PROCESSENTRY32));
            uint ppid = 0;
            if (!Process32First(snapshot, ref entry)) return false;
            do
            {
                if (entry.th32ProcessID == currentPid)
                {
                    ppid = entry.th32ParentProcessID; break;
                }
            }
            while (Process32Next(snapshot, ref entry));
            if (ppid == 0) return false;
            entry = new PROCESSENTRY32();
            entry.dwSize = (uint)Marshal.SizeOf(typeof(PROCESSENTRY32));
            if (!Process32First(snapshot, ref entry)) return false;
            do
            {
                if (entry.th32ProcessID == ppid)
                {
                    parentPid = (int)ppid; parentExe = entry.szExeFile;
                try
                {
                    using (Process parent = Process.GetProcessById(parentPid))
                    {
                        StringBuilder path = new StringBuilder(1024);
                        int size = path.Capacity;
                        if (QueryFullProcessImageName(parent.Handle, 0, path, ref size))
                        {
                            parentPath = path.ToString();
                        }
                        else
                        {
                            throw new Win32Exception(Marshal.GetLastWin32Error());
                        }
                    }
                }
                catch (Exception ex)
                    {
                    MessageBox.Show("Could not obtain parent executable path:\n\n" + ex.GetType().FullName + "\n" + ex.Message,
                    "Parent Process Information", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    }
                    return true;
                }
            } while (Process32Next(snapshot, ref entry));
        return false;
        }
        finally
        {
            CloseHandle(snapshot);
        }
    }

    bool AnySumatraRunning()
    {
        Process[] processes = Process.GetProcessesByName("SumatraPDF");
        try
        {
            return processes.Length > 0;
        }
        finally
        {
            foreach (Process p in processes) p.Dispose();
        }
    }

bool PrepareForFileOperation()
{
    // Optional manual-control mode.
    if (!CloseParentSumatraBeforeOperation)
    {
        if (AnySumatraRunning())
        {
            MessageBox.Show(
                "Automatic closure is disabled.\n\n" + "Close SumatraPDF manually before continuing.",
                "Settings Manager", MessageBoxButtons.OK, MessageBoxIcon.Information);
            return false;
        }
        return true;
    }
    int parentPid; string parentExe; string parentPath;
    bool foundParent = TryGetParentProcess(out parentPid, out parentExe, out parentPath);
    if (foundParent &&
        string.Equals(Path.GetFileName(parentExe),
            "SumatraPDF.exe", StringComparison.OrdinalIgnoreCase) &&
        !string.IsNullOrWhiteSpace(parentPath))
    {
        sumatraExePath = parentPath;
    }
    // If launched directly, never guess which SumatraPDF instance should be closed.
    if (!foundParent || !string.Equals(Path.GetFileName(parentExe), "SumatraPDF.exe", StringComparison.OrdinalIgnoreCase))
    {
        if (AnySumatraRunning())
        {
            MessageBox.Show(
                "A SumatraPDF instance is running, but its relationship\n" + "to this manager cannot be established.\n\n" +
                "Close the relevant SumatraPDF instance manually and try again.",
                "Settings Manager", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return false;
        }
        return true;
    }
    try
    {
        using (Process parent =  Process.GetProcessById(parentPid))
        {
            if (!string.Equals(parent.ProcessName, "SumatraPDF", StringComparison.OrdinalIgnoreCase)) return false;
            // Deliberately NO /T and NO /F.
            ProcessStartInfo psi = new ProcessStartInfo();
            psi.FileName = "taskkill.exe";
            psi.Arguments = "/PID " + parentPid.ToString(CultureInfo.InvariantCulture);
            psi.UseShellExecute = false;
            psi.CreateNoWindow = true;
            psi.WindowStyle = ProcessWindowStyle.Hidden;
            using (Process killer = Process.Start(psi))
            {
                if (killer == null || !killer.WaitForExit(10000))
                {
                    statusLabel.Text = "Could not complete SumatraPDF shutdown.";
                    return false;
                }
                if (killer.ExitCode != 0)
                {
                    statusLabel.Text = "SumatraPDF shutdown request failed.";
                    return false;
                }
            }
            // Wait for SumatraPDF to actually finish.
            if (!parent.WaitForExit(5000))
            {
                MessageBox.Show("SumatraPDF has not finished closing.\n\n" + "No file operation was performed.",
                    "Settings Manager", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return false;
            }
        }
        return true;
    }
    catch (Exception ex)
    {
        ShowError(ex); return false;
    }
}

    void CreateUI()
    {
        Label heading = new Label();
        heading.Text = "Settings Manager";
        heading.ForeColor = Color.White;
        heading.Location = new Point(14, 10);
        heading.AutoSize = true;
        heading.Font = ScaledFont("Segoe UI", 12F, FontStyle.Regular);
        Controls.Add(heading);

        closeButton = new Button();
        closeButton.Text = "X";
        closeButton.ForeColor = Color.Red; closeButton.BackColor = Color.FromArgb(64, 64, 64);
        closeButton.FlatStyle = FlatStyle.Flat; closeButton.FlatAppearance.BorderSize = 0;
        closeButton.Size = new Size(30, 30);
        closeButton.Location = new Point(306, 8);
        closeButton.Click += delegate { Close(); };
        closeButton.MouseEnter += delegate { closeButton.BackColor = Color.FromArgb(96, 96, 96); };
        closeButton.MouseLeave += delegate { closeButton.BackColor = Color.FromArgb(64, 64, 64); };
        Controls.Add(closeButton);

        // Description input.
        Label descriptionLabel = new Label();
        descriptionLabel.Text = "Description:";
        descriptionLabel.ForeColor = Color.White;
        descriptionLabel.Location = new Point(14, 47);
        descriptionLabel.Size = new Size(80, 22);
        Controls.Add(descriptionLabel);
        descriptionBox = new TextBox();
        descriptionBox.Location = new Point(95, 43);
        descriptionBox.Size = new Size(242, 23);
        descriptionBox.MaxLength = 40;
        descriptionBox.BorderStyle = BorderStyle.FixedSingle;
        Controls.Add(descriptionBox);

        // Backup selection list.
        Label listLabel = new Label();
        listLabel.Text = "Select settings to restore:";
        listLabel.ForeColor = Color.White;
        listLabel.Location = new Point(14, 73);
        listLabel.AutoSize = true;
        Controls.Add(listLabel);

        backups = new ListBox();
        backups.Location = new Point(15, 100);
        backups.Size = new Size(320, 120);
        backups.BackColor = Color.FromArgb(42, 42, 42);
        backups.ForeColor = Color.White;
        backups.BorderStyle = BorderStyle.FixedSingle;
        backups.Font = ScaledFont("Segoe UI", 9F);
        backups.IntegralHeight = false;
        backups.ItemHeight = 22;
        backups.DrawMode = DrawMode.OwnerDrawFixed;
        backups.DrawItem += DrawBackupItem;
        backups.DoubleClick += delegate
        {
            RestoreSelected(this, EventArgs.Empty);
        };
        Controls.Add(backups);

        // Status feedback.
        statusLabel = new Label();
        statusLabel.Text = "Ready";
        statusLabel.ForeColor = Color.Lime;
        statusLabel.Location = new Point(14, 230);
        statusLabel.Size = new Size(330, 19);
        statusLabel.AutoEllipsis = true;
        Controls.Add(statusLabel);

        // Action buttons.
        restoreButton = CreateButton("Restore Selected", 15, 255, 105);
        restoreButton.Click += RestoreSelected;
        Controls.Add(restoreButton);
        storeButton = CreateButton("Store Current", 125, 255, 100);
        storeButton.Click += StoreCurrent;
        Controls.Add(storeButton);
        deleteButton = CreateButton("Delete Selected", 230, 255, 105);
        deleteButton.Click += DeleteSelected;
        Controls.Add(deleteButton);
    }

    Button CreateButton(
        string caption, int left, int top, int width)
    {
        Button button = new Button();
        button.Text = caption;
        button.Location = new Point(left, top);
        button.Size = new Size(width, 29);
        button.ForeColor = Color.White;
        button.BackColor = Color.FromArgb(64, 64, 64);
        button.FlatStyle = FlatStyle.Flat;
        button.FlatAppearance.BorderSize = 0;
        button.Cursor = Cursors.Hand;
        button.MouseEnter += delegate
        {
            button.BackColor =  Color.FromArgb(85, 85, 85);
        };
        button.MouseLeave += delegate
        {
            button.BackColor =  Color.FromArgb(64, 64, 64);
        };
        return button;
    }

    void DrawBackupItem(
        object sender, DrawItemEventArgs e)
    {
        if (e.Index < 0) return;
        bool selected = (e.State & DrawItemState.Selected) != 0;
        Color background = selected ? Color.FromArgb(85, 85, 85) : Color.FromArgb(42, 42, 42);
        using (SolidBrush brush = new SolidBrush(background))
        {
            e.Graphics.FillRectangle(brush, e.Bounds);
        }
        BackupItem item = backups.Items[e.Index] as BackupItem;
        if (item != null)
        {
            TextRenderer.DrawText(
                e.Graphics,
                item.DisplayName,
                backups.Font,
                new Rectangle(e.Bounds.X + 5, e.Bounds.Y, e.Bounds.Width - 10, e.Bounds.Height),
                Color.White,
                TextFormatFlags.Left | TextFormatFlags.VerticalCenter | TextFormatFlags.EndEllipsis);
        }
        e.DrawFocusRectangle();
    }

    // Description
    string CleanDescription(string input)
    {
        if (input == null) return "";
        string result = input.Trim();
        foreach (char c in Path.GetInvalidFileNameChars())
            result = result.Replace(c.ToString(), "");
        result = result.Trim().TrimEnd('.');
        if (result.Length > 40) result = result.Substring(0, 40).TrimEnd();
        return result;
    }

    // Timestamp and filename generation.
    string Timestamp()
    {
        return DateTime.Now.ToString("yyyy-MM-dd_HH-mm", CultureInfo.InvariantCulture);
    }

    string MakeBackupName(string reminder)
    {
        string stamp = Timestamp();
        string description = "";
        if (!string.IsNullOrWhiteSpace(reminder)) description = "-" + reminder.Trim();
        string name = Prefix + stamp + description + Suffix;
        string path = Path.Combine(folder, name);
        int n = 1;
        while (File.Exists(path))
        {
            string numberedName = Prefix + stamp + description + "-" + n.ToString("D2") + Suffix;
            path = Path.Combine(folder, numberedName);
            n++;
        }
        return path;
    }

    // Validate dated backup filenames.
    bool IsManagedBackup(string file)
    {
        string name = Path.GetFileName(file);
        if (!name.StartsWith(Prefix, StringComparison.OrdinalIgnoreCase)) return false;
        if (!name.EndsWith(Suffix, StringComparison.OrdinalIgnoreCase)) return false;
        string stem = Path.GetFileNameWithoutExtension(name);
        string remainder = stem.Substring(Prefix.Length);
        if (remainder.Length < 16) return false;
        string datePart = remainder.Substring(0, 16);
        DateTime parsed;
        if (!DateTime.TryParseExact(datePart, "yyyy-MM-dd_HH-mm", CultureInfo.InvariantCulture, DateTimeStyles.None, out parsed))
            return false;
        if (remainder.Length > 16 && remainder[16] != '-') return false;
        return true;
    }

    // Refresh backup list, newest first.
    void RefreshBackups()
    {
        backups.BeginUpdate();
        backups.Items.Clear();
        string[] files = Directory.GetFiles(folder, Prefix + "*" + Suffix);
        Array.Sort(files, StringComparer.OrdinalIgnoreCase);
        Array.Reverse(files);
        foreach (string file in files)
        {
            if (!IsManagedBackup(file)) continue;
            backups.Items.Add(new BackupItem(Path.GetFileName(file)));
        }
        backups.EndUpdate();
        if (backups.Items.Count > 0) backups.SelectedIndex = 0;
        restoreButton.Enabled = backups.Items.Count > 0;
        deleteButton.Enabled = backups.Items.Count > 0;
        if (backups.Items.Count == 0) statusLabel.Text = "No saved settings found.";
        else
            statusLabel.Text = backups.Items.Count + " saved settings found.";
    }

    void DeleteSelected(object sender, EventArgs e)
    {
        BackupItem item = backups.SelectedItem as BackupItem;
        if (item == null) return;
        string selected = Path.Combine(folder, item.FileName);
        DialogResult answer = MessageBox.Show(
            "Permanently delete this saved settings file?\n\n" + item.FileName,
            "Confirm Delete", MessageBoxButtons.YesNo, MessageBoxIcon.Warning);
        if (answer != DialogResult.Yes) return;
        try
        {
            if (!File.Exists(selected))
            {
                statusLabel.Text = "Selected file no longer exists.";
                RefreshBackups();
                return;
            }
            File.Delete(selected);
            RefreshBackups();
            statusLabel.Text = "Backup deleted successfully.";
        }
        catch (Exception ex)
        {
            ShowError(ex);
        }
    }

    // Store current settings.
    void StoreCurrent(object sender, EventArgs e)
    {
        string source = Path.Combine(folder, Original);
        if (!File.Exists(source))
        {
            statusLabel.Text = "Current settings file not found.";
            MessageBox.Show(
                "The current settings file was not found:\n\n" +
                source,
                "Settings Manager",
                MessageBoxButtons.OK,
                MessageBoxIcon.Warning);
            return;
        }
        DialogResult answer = MessageBox.Show(
            "Store the current SumatraPDF settings?\n\n" + "The SumatraPDF instance that launched this manager " +
            "will be closed first so its latest settings can be written to disk.",
            "Confirm Store", MessageBoxButtons.YesNo, MessageBoxIcon.Question);
        if (answer != DialogResult.Yes) return;
        if (!PrepareForFileOperation()) return;
        try
        {
            string reminder = CleanDescription(descriptionBox.Text);
            descriptionBox.Text = reminder;
            string destination = MakeBackupName(reminder);
            File.Copy(source, destination);
            RefreshBackups();
            statusLabel.Text = "Saved: " + Path.GetFileName(destination);
            RestartSumatra();
        }
        catch (Exception ex)
        {
            ShowError(ex);
        }
    }

    // Restore selected settings.
    void RestoreSelected(object sender, EventArgs e)
    {
        BackupItem item = backups.SelectedItem as BackupItem;
        if (item == null) return;
        string selected = Path.Combine(folder, item.FileName);
        string target = Path.Combine(folder, Original);
        if (!File.Exists(selected))
        {
            statusLabel.Text = "Selected file no longer exists.";
            RefreshBackups();
            return;
        }
        DialogResult answer = MessageBox.Show(
            "Restore this settings file?\n\n" + item.FileName +
            "\n\nAny active SumatraPDF instance will be closed first. " +
            "\nSo current settings can be backed up before restore.",
            "Confirm Restore", MessageBoxButtons.YesNo, MessageBoxIcon.Question);
        if (answer != DialogResult.Yes) return;
        // Close SumatraPDF and allow its settings to be written.
        if (!PrepareForFileOperation()) return;
        try
        {
            // Automatically preserve current settings.
            if (File.Exists(target))
            {
                string safetyBackup = MakeBackupName("");
                File.Copy(target, safetyBackup);
            }
            // Restore selected file.
            File.Copy(selected, target, true);
            RefreshBackups();
            statusLabel.Text = "Settings restored successfully.";
            RestartSumatra();
        }
        catch (Exception ex)
        {
            ShowError(ex);
        }
    }

// Restart SumatraPDF using its previously discovered executable path.
void RestartSumatra()
{
    if (!RestartSumatraAfterOperation || string.IsNullOrWhiteSpace(sumatraExePath)) return;
    try
    {
        ProcessStartInfo psi = new ProcessStartInfo();
        psi.FileName = sumatraExePath;
        psi.UseShellExecute = true;
        Process.Start(psi);
        Close();
    }
    catch (Exception ex)
    {
        MessageBox.Show("Settings operation succeeded, but SumatraPDF could not be restarted:\n\n" + ex.Message,
            "Settings Manager", MessageBoxButtons.OK, MessageBoxIcon.Warning);
    }
}

    // Error handling.
    void ShowError(Exception ex)
    {
        statusLabel.Text = "File operation failed.";
        MessageBox.Show(ex.Message, "Settings Manager", MessageBoxButtons.OK, MessageBoxIcon.Error);
    }

    // Rounded window.
    GraphicsPath GetRoundedPath(Rectangle rect, int radius)
    {
        int d = radius * 2;
        GraphicsPath path = new GraphicsPath();
        path.AddArc(rect.X, rect.Y, d, d, 180, 90);
        path.AddArc(rect.Right - d, rect.Y, d, d, 270, 90);
        path.AddArc(rect.Right - d, rect.Bottom - d, d, d, 0, 90);
        path.AddArc(rect.X, rect.Bottom - d, d, d, 90, 90);
        path.CloseFigure();
        return path;
    }

    protected override void OnResize(EventArgs e)
    {
        base.OnResize(e);
        using (GraphicsPath path = GetRoundedPath(new Rectangle(0, 0, Width, Height), CornerRadius))
        {
            Region oldRegion = Region;
            Region = new Region(path);
            if (oldRegion != null) oldRegion.Dispose();
        }
        Invalidate();
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        base.OnPaint(e);
        e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
        using (Pen border = new Pen(Color.FromArgb(55, 55, 55), 1))
        {
            using (GraphicsPath path = GetRoundedPath(new Rectangle(0, 0, Width - 1, Height - 1), CornerRadius))
            {
                e.Graphics.DrawPath(border, path);
            }
        }
    }

    // Drag borderless window.
    protected override void WndProc(ref Message m)
    {
        const int WM_NCHITTEST = 0x84;
        const int HTCAPTION = 2;
        if (m.Msg == WM_NCHITTEST)
        {
            base.WndProc(ref m);
            if ((int)m.Result == 1) m.Result = (IntPtr)HTCAPTION;
            return;
        }
        base.WndProc(ref m);
    }

    // Application entry point.
    [STAThread]
    static void Main(string[] args)
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        string targetFolder = null;
        // Optional fixed storage folder:
        // targetFolder = @"C:\Users\User\AppData\Local\SumatraPDF";
        if (args.Length > 0) targetFolder = args[0];
        try
        {
            Application.Run(new SettingsManager(targetFolder));
        }
        catch (Exception ex)
        {
            MessageBox.Show(ex.Message, "Settings Manager", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }
}
