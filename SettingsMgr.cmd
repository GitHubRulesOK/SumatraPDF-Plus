/*
C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc  /target:winexe /platform:x86 "%~0"  
exit /b

After running in windows. This SessionMgr.CMD file becomes SessionMgr.exe
It is one of 3 methods this one saves files with a date for mixed usage the other
is SessionSaverDialog which asks for a Folder to be used for -appdata collections.

The idea is to allow saving the current set of open tabs for edit and reuse.


It should be run from advanced settings entry pointing to same folder as SumatraPDF-settings.txt  

ExternalViewers [
	[
		CommandLine = C:\Users\ path to folder \SumatraPDF\SessionMgr.exe
		Name = Session &Manager
		Key = s
	]
]

*/
using System;
using System.IO;
using System.Globalization;
using System.Drawing;
using System.Windows.Forms;

class FileStamp : Form
{
    string folder;
    const string Original = "SumatraPDF-settings.txt";
    const string Prefix = "SumatraPDF-settings-";
    const string Suffix = ".txt";
// later added Display options
const bool ShowExtension = false;

    ListBox backups;
    Button restoreButton;
    Button storeButton;

    FileStamp(string targetFolder)
    {
        folder = AppDomain.CurrentDomain.BaseDirectory;

// etended to alow for a remote folder on command line
folder = string.IsNullOrWhiteSpace(targetFolder)
    ? AppDomain.CurrentDomain.BaseDirectory
    : Environment.ExpandEnvironmentVariables(targetFolder);

folder = Path.GetFullPath(folder);

if (!Directory.Exists(folder))
{
    throw new DirectoryNotFoundException(
        "The specified folder does not exist:\n\n" + folder);
}

        Text = "SumatraPDF Settings Backup";
        StartPosition = FormStartPosition.CenterScreen;
        ClientSize = new Size(540, 370);
        MinimumSize = new Size(450, 300);
        Font = new Font("Segoe UI", 9F);

        Label heading = new Label();
        heading.Text = "Select a backup to restore:";
        heading.Location = new Point(12, 12);
        heading.AutoSize = true;
        Controls.Add(heading);

        backups = new ListBox();
        backups.Location = new Point(12, 38);
        backups.Size = new Size(516, 245);
        backups.Anchor = AnchorStyles.Top | AnchorStyles.Bottom |
                         AnchorStyles.Left | AnchorStyles.Right;
        backups.Font = new Font("Segoe UI", 10F);
        Controls.Add(backups);

        restoreButton = new Button();
        restoreButton.Text = "Restore Selected";
        restoreButton.Location = new Point(12, 300);
        restoreButton.Size = new Size(135, 32);
        restoreButton.Anchor = AnchorStyles.Bottom | AnchorStyles.Left;
        restoreButton.Click += RestoreSelected;
        Controls.Add(restoreButton);

        storeButton = new Button();
        storeButton.Text = "Store Current Settings";
        storeButton.Location = new Point(155, 300);
        storeButton.Size = new Size(165, 32);
        storeButton.Anchor = AnchorStyles.Bottom | AnchorStyles.Left;
        storeButton.Click += StoreCurrent;
        Controls.Add(storeButton);

        Button closeButton = new Button();
        closeButton.Text = "Close";
        closeButton.Location = new Point(428, 300);
        closeButton.Size = new Size(100, 32);
        closeButton.Anchor = AnchorStyles.Bottom | AnchorStyles.Right;
        closeButton.Click += delegate { Close(); };
        Controls.Add(closeButton);

        backups.DoubleClick += delegate
        {
            RestoreSelected(this, EventArgs.Empty);
        };

        RefreshBackups();
    }

string AskForReminder()
{
    using (Form prompt = new Form())
    {
        prompt.Text = "Describe This Settings Backup";
        prompt.StartPosition = FormStartPosition.CenterParent;
        prompt.ClientSize = new Size(390, 125);
        prompt.FormBorderStyle = FormBorderStyle.FixedDialog;
        prompt.MinimizeBox = false;
        prompt.MaximizeBox = false;
        prompt.ShowInTaskbar = false;

        Label label = new Label();
        label.Text = "Optional reminder (e.g. with comics):";
        label.Location = new Point(12, 12);
        label.AutoSize = true;
        prompt.Controls.Add(label);

        TextBox input = new TextBox();
        input.Location = new Point(12, 36);
        input.Size = new Size(365, 23);
        input.Anchor = AnchorStyles.Top |
                       AnchorStyles.Left |
                       AnchorStyles.Right;
        prompt.Controls.Add(input);

        Button save = new Button();
        save.Text = "Save";
        save.Location = new Point(200, 78);
        save.DialogResult = DialogResult.OK;
        prompt.Controls.Add(save);

        Button cancel = new Button();
        cancel.Text = "Cancel";
        cancel.Location = new Point(285, 78);
        cancel.DialogResult = DialogResult.Cancel;
        prompt.Controls.Add(cancel);

        prompt.AcceptButton = save;
        prompt.CancelButton = cancel;

        if (prompt.ShowDialog(this) != DialogResult.OK)
            return null;

        // Remove characters that are invalid in Windows filenames.
        string reminder = input.Text.Trim();
        foreach (char c in Path.GetInvalidFileNameChars())
            reminder = reminder.Replace(c.ToString(), "");

        // Keep the reminder brief.
        if (reminder.Length > 40)
            reminder = reminder.Substring(0, 40).Trim();

        return reminder;
    }
}

    string Timestamp()
    {
        return DateTime.Now.ToString(
// optionally dont show the seconds most backups would be a minute apart
//          "yyyy-MM-dd_HH-mm-ss",
            "yyyy-MM-dd_HH-mm",
            CultureInfo.InvariantCulture);
    }

string MakeBackupName(string reminder = "")
{
    string stamp = Timestamp();

    // Add the optional reminder to the backup filename.
    string description = "";

    if (!string.IsNullOrWhiteSpace(reminder))
        description = "-" + reminder.Trim();

    string path = Path.Combine(
        folder, Prefix + stamp + description + Suffix);

    int n = 1;

    while (File.Exists(path))
    {
        path = Path.Combine(folder,
            Prefix + stamp + description + "-" +
            n.ToString("D2") + Suffix);
        n++;
    }

    return path;
}

    void RefreshBackups()
    {
        backups.Items.Clear();

        string[] files = Directory.GetFiles(
            folder, Prefix + "*" + Suffix);

        Array.Sort(files, StringComparer.OrdinalIgnoreCase);
        Array.Reverse(files);

        foreach (string file in files)
// optionally dont show the .txt extension
//            backups.Items.Add(Path.GetFileName(file));
{
    string name = Path.GetFileName(file);

    backups.Items.Add(
        ShowExtension ? name : Path.GetFileNameWithoutExtension(name));
}

        if (backups.Items.Count > 0)
            backups.SelectedIndex = 0;

        restoreButton.Enabled = backups.Items.Count > 0;
    }
// added

    void StoreCurrent(object sender, EventArgs e)
    {
        string source = Path.Combine(folder, Original);

        if (!File.Exists(source))
        {
            MessageBox.Show("The current settings file was not found:\n\n"
                + source, "Backup",
                MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return;
        }

        try
        {
string reminder = AskForReminder();
// Cancel means do not create a backup.
if (reminder == null)
    return;
string destination = MakeBackupName(reminder);

            File.Copy(source, destination);

            RefreshBackups();
            MessageBox.Show("Settings backup stored successfully:\n\n"
                + Path.GetFileName(destination),
                "Backup Complete",
                MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
        catch (Exception ex)
        {
            ShowError(ex);
        }
    }

    void RestoreSelected(object sender, EventArgs e)
    {
        if (backups.SelectedItem == null)
            return;
        string selected = Path.Combine( 
folder, backups.SelectedItem.ToString());

// Add extension back if it was set as hidden (false) in the visible ListBox.
if (ShowExtension == false) selected += Suffix;

        string target = Path.Combine(folder, Original);

        DialogResult answer = MessageBox.Show(
            "Restore this backup?\n\n" +
            Path.GetFileName(selected) +
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
                MessageBox.Show("The selected backup no longer exists.",
                    "Restore", MessageBoxButtons.OK,
                    MessageBoxIcon.Warning);
                RefreshBackups();
                return;
            }

            if (File.Exists(target))
                File.Copy(target, MakeBackupName());

            File.Copy(selected, target, true);

            MessageBox.Show("Settings restored successfully.",
                "Restore Complete", MessageBoxButtons.OK,
                MessageBoxIcon.Information);

            RefreshBackups();
        }
        catch (Exception ex)
        {
            ShowError(ex);
        }
    }

    void ShowError(Exception ex)
    {
        MessageBox.Show(ex.Message, "File Operation Failed",
            MessageBoxButtons.OK, MessageBoxIcon.Error);
    }

[STAThread]
static void Main(string[] args)
{
    Application.EnableVisualStyles();
    Application.SetCompatibleTextRenderingDefault(false);

    string targetFolder = args.Length > 0 ? args[0] : null;

    try
    {
        Application.Run(new FileStamp(targetFolder));
    }
    catch (Exception ex)
    {
        MessageBox.Show(
            ex.Message,
            "Settings Backup",
            MessageBoxButtons.OK,
            MessageBoxIcon.Error);
    }
}
}
