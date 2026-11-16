/*
C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc /nologo /target:winexe /platform:x86 "%~0"
exit /b

After running in windows. This SettingsMgr.CMD file becomes SettingsMgr.exe
It is one of 2 methods this one saves files with a date for mixed usage the other
is SessionSaverDialog which asks for a Folder to be used for -appdata collections.

The idea is to allow saving the current set of open tabs for edit and reuse.
so add a description to save a named (and dated) settings file or restore one you named before.

It should be run from advanced settings entry pointing to same folder as SumatraPDF-settings.txt 
So check this is usually including your user name for an installed copy so edit to suit.

ExternalViewers [
	[
		CommandLine = "C:\Users\WDAGUtilityAccount\AppData\Local\SumatraPDF\SettingsMgr.exe"
		Name = Settings &Manager
		Key = s
        ToolbarSvgIcon = <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="none"><path d="M0 0h24v24H0z"/><path stroke="currentColor" d="M9.5 3.5a2.5 2.5 0 0 1 5 0 2.5 2.5 0 0 0 3.5 2 1 1 0 0 1 2.5 4.5 2.5 2.5 0 0 0 0 4 1 1 0 0 1-2.5 4.5 2.5 2.5 0 0 0-3.5 2 1 1 0 0 1-5 0 2.5 2.5 0 0 0-3.5-2A1 1 0 0 1 3.5 14a2.5 2.5 0 0 0 0-4A1 1 0 0 1 6 5.5a2.5 2.5 0 0 0 3.5-2M9 12a3 3 0 0 1 6 0 3 3 0 0 1-6 0"/></svg>
	]
]

*/

using System;
using System.IO;
using System.Globalization;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;
using System.Collections.Generic;

public class SettingsManager : Form
{
    string folder;

    const string Original = "SumatraPDF-settings.txt";
    const string Prefix = "SumatraPDF-settings-";
    const string Suffix = ".txt";

    const bool ShowExtension = false;
    const int CornerRadius = 16;

    Button closeButton;
    TextBox descriptionBox;
    ListBox backups;
    Label statusLabel;
    Button restoreButton;
    Button storeButton;
    Button deleteButton;

    class BackupItem
    {
        public string FileName;
        public string DisplayName;
        public BackupItem(string fileName)
        {
            FileName = fileName;
            string name = Path.GetFileNameWithoutExtension(fileName);
            if (name.StartsWith(Prefix, StringComparison.OrdinalIgnoreCase))
                name = name.Substring(Prefix.Length);
            // produces warning so simplify
            // DisplayName = ShowExtension ? name + Suffix : name;
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
        if (!string.IsNullOrWhiteSpace(targetFolder))
            folder = Environment.ExpandEnvironmentVariables(targetFolder.Trim().Trim('"'));
        folder = Path.GetFullPath(folder);
        if (!Directory.Exists(folder))
            throw new DirectoryNotFoundException("Settings folder does not exist:\n\n" + folder);
        FormBorderStyle = FormBorderStyle.None;
        StartPosition = FormStartPosition.CenterScreen;
        BackColor = Color.FromArgb(32, 32, 32); ForeColor = Color.White;
        ClientSize = new Size(350, 300); MinimumSize = new Size(350, 300); MaximumSize = new Size(350, 300);
        DoubleBuffered = true;
        Font = new Font("Segoe UI", 9F);
        CreateUI();
        RefreshBackups();
    }

    void CreateUI()
    {
        Label heading = new Label();
        heading.Text = "Settings Manager";
        heading.ForeColor = Color.White;
        heading.Location = new Point(14, 10);
        heading.AutoSize = true;
        heading.Font = new Font("Segoe UI", 12F, FontStyle.Regular);
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
        backups.Font = new Font("Segoe UI", 9F);
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
        if (!DateTime.TryParseExact(
            datePart,
            "yyyy-MM-dd_HH-mm",
            CultureInfo.InvariantCulture,
            DateTimeStyles.None,
            out parsed))
            return false;
        if (remainder.Length > 16 &&
            remainder[16] != '-')
            return false;
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
        "Permanently delete this saved settings file?\n\n" +
        item.FileName,
        "Confirm Delete",
        MessageBoxButtons.YesNo,
        MessageBoxIcon.Warning);
    if (answer != DialogResult.Yes) try
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
        try
        {
            string reminder = CleanDescription(descriptionBox.Text);
            descriptionBox.Text = reminder;
            string destination = MakeBackupName(reminder);
            File.Copy(source, destination);
            RefreshBackups();
            statusLabel.Text = "Saved: " + Path.GetFileName(destination);
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
        DialogResult answer = MessageBox.Show(
            "Restore this settings file?\n\n" +
            item.FileName +
            "\n\nThe current settings will first be backed up.",
            "Confirm Restore",
            MessageBoxButtons.YesNo,
            MessageBoxIcon.Question);
        if (answer != DialogResult.Yes)
            return;
        try
        {
            if (!File.Exists(selected))
            {
                statusLabel.Text = "Selected file no longer exists.";
                RefreshBackups();
                return;
            }
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
        }
        catch (Exception ex)
        {
            ShowError(ex);
        }
    }

    // Error handling.
    void ShowError(Exception ex)
    {
        statusLabel.Text = "File operation failed.";
        MessageBox.Show(
            ex.Message,
            "Settings Manager",
            MessageBoxButtons.OK,
            MessageBoxIcon.Error);
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
            using (GraphicsPath path = GetRoundedPath(
                new Rectangle(0, 0, Width - 1, Height - 1), CornerRadius))
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
            MessageBox.Show(
                ex.Message,
                "Settings Manager",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
        }
    }
}
