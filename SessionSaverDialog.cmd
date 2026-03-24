/*
C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc  /target:winexe /platform:x86 "%~0"
exit /b

After running in windows. This SessionSaverDialog.CMD file becomes SessionSaverDialog.exe
It is one of 2 methods this one asks for a Folder to be used for -appdata collections,
the other SessionSaver.cmd/.exe saves files with a date for mixed usage.

The idea is to allow saving the current set of open tabs for edit and reuse.
See the example at https://github.com/sumatrapdfreader/sumatrapdf/issues/43

It should be run from advanced settings entry pointing to same folder as SumatraPDF-settings.txt  

ExternalViewers [
	[
		CommandLine = C:\Users\ path to folder \SumatraPDF\SessionSaverDialog.exe
		Name = Session &Saver Dialog
		Key = s
	]
]

*/
using System;
using System.IO;
using System.Text;
using System.Collections.Generic;
using System.Linq;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;

public class SaveSessionDialog : Form
{
  private int _cornerRadius = 16;
  private TextBox sessionNameBox;
  private TextBox basePathBox;
  private Label finalPathLabel;
  private Label savedLabel;
  private Button browseBtn;
  private Button saveBtn;
  private Button closeBtn;

  public SaveSessionDialog()
  {
    this.FormBorderStyle = FormBorderStyle.None;
    this.StartPosition = FormStartPosition.CenterScreen;
    this.BackColor = Color.FromArgb(32, 32, 32);
    this.DoubleBuffered = true;
    this.Width = 300; this.Height = 200;
    CreateCloseButton();
    CreateUI();
  }

  private void CreateUI()
  {
    Label nameLabel = new Label();
    nameLabel.Text = "Session NEW FOLDER name:";
    nameLabel.ForeColor = Color.White;
    nameLabel.Left = 15; nameLabel.Top = 15; nameLabel.Width = 175;
    this.Controls.Add(nameLabel);
    sessionNameBox = new TextBox();
    sessionNameBox.Left = 15; sessionNameBox.Top = 37; sessionNameBox.Width = 240;
    sessionNameBox.TextChanged += UpdateFinalPath;
    this.Controls.Add(sessionNameBox);

    Label baseLabel = new Label();
    baseLabel.Text = "Choose base folder (Do not add \"new\"):";
    baseLabel.ForeColor = Color.White;
    baseLabel.Left = 15; baseLabel.Top = 70; baseLabel.Width = 210;
    this.Controls.Add(baseLabel);
    basePathBox = new TextBox();
    basePathBox.Left = 15; basePathBox.Top = 93; basePathBox.Width = 200;
    basePathBox.TextChanged += UpdateFinalPath;
    this.Controls.Add(basePathBox);
    browseBtn = new Button();
    browseBtn.Text = "Browse…";
    browseBtn.Left = 220; browseBtn.Top = 92; browseBtn.Width = 70;
    browseBtn.Click += BrowseClicked;
    browseBtn.ForeColor = Color.White;
    this.Controls.Add(browseBtn);

    finalPathLabel = new Label();
    finalPathLabel.ForeColor = Color.Yellow;
    finalPathLabel.Left = 15; finalPathLabel.Top = 125; finalPathLabel.Width = 275;
    finalPathLabel.Height = 40;
    this.Controls.Add(finalPathLabel);

    saveBtn = new Button();
    saveBtn.Text = "Save Session";
    saveBtn.Left = 15; saveBtn.Top = 165; saveBtn.Width = 100;
    saveBtn.Click += SaveClicked;
    saveBtn.ForeColor = Color.White;
    this.Controls.Add(saveBtn);

    savedLabel = new Label();
    savedLabel.Text = "";
    savedLabel.ForeColor = Color.Lime;
    savedLabel.Left = 120; savedLabel.Top = 170; savedLabel.Width = 80;
    this.Controls.Add(savedLabel);
  }

private void BrowseClicked(object sender, EventArgs e)
{
  FolderBrowserDialog dlg = new FolderBrowserDialog();
  // Option A: Start at EXE folder
  dlg.SelectedPath = Application.StartupPath;
  // Option B: Start at a preset library folder
  // dlg.SelectedPath = @"C:\Users\ name \Desktop\Data";
  if (dlg.ShowDialog() == DialogResult.OK)
  {
    basePathBox.Text = dlg.SelectedPath;
  }
}

private void UpdateFinalPath(object sender, EventArgs e)
{
  string name = sessionNameBox.Text.Trim();
  string basePath = basePathBox.Text.Trim();
  finalPathLabel.Text = "";
  // Validate session name even if base path is empty
  if (ContainsIllegalFileNameChars(name))
  {
    finalPathLabel.Text = "Invalid folder name.";
    return;
  }
  // Only skip preview if base path is empty
  if (basePath.Length == 0) return;
  if (ContainsIllegalFileNameChars(name))
  {
    finalPathLabel.Text = "Invalid folder name.";
    return;
  }
  if (ContainsIllegalPathChars(basePath))
  {
    finalPathLabel.Text = "Invalid base folder.";
    return;
  }
  if (!Directory.Exists(basePath))
  {
    finalPathLabel.Text = "Base folder not found.";
    return;
  }
  try
  {
    finalPathLabel.Text = Path.Combine(basePath, name);
  }
  catch
  {
    finalPathLabel.Text = "";
  }
}

private void SaveClicked(object sender, EventArgs e)
{
  string name = sessionNameBox.Text.Trim();
  string basePath = basePathBox.Text.Trim();
  if (name.Length == 0 || basePath.Length == 0)
  {
    savedLabel.Text = "Missing name or folder.";
    return;
  }
  if (ContainsIllegalPathChars(name))
  {
    savedLabel.Text = "Illegal characters in folder name.";
    return;
  }
  string finalFolder = Path.Combine(basePath, name);
  try
  {
    Directory.CreateDirectory(finalFolder);
    string output = SessionSaver.BuildSessionFromCurrentFolder();
    string outFile = Path.Combine(finalFolder, "SumatraPDF-settings.txt");
    File.WriteAllText(outFile, output, Encoding.UTF8);
    savedLabel.Text = "Saved!";
    // this.Close();  // optional auto-close
  }
  catch (Exception ex)
  {
    savedLabel.Text = "Error: " + ex.Message;
  }
}

private bool ContainsIllegalPathChars(string input)
{
  return input.IndexOfAny(Path.GetInvalidPathChars()) >= 0;
}

private bool ContainsIllegalFileNameChars(string input)
{
  return input.IndexOfAny(Path.GetInvalidFileNameChars()) >= 0;
}

  private void CreateCloseButton()
  {
    closeBtn = new Button();
    closeBtn.Text = "X";
    closeBtn.ForeColor = Color.Red;
    closeBtn.BackColor = Color.FromArgb(64, 64, 64);
    closeBtn.FlatStyle = FlatStyle.Flat;
    closeBtn.FlatAppearance.BorderSize = 0;
    closeBtn.Width = 30; closeBtn.Height = 30;
    closeBtn.Left = this.Width - closeBtn.Width - 20;
    closeBtn.Top = 10;
    closeBtn.Click += delegate { this.Close(); };
    closeBtn.MouseEnter += delegate { closeBtn.BackColor = Color.FromArgb(96, 96, 96); };
    closeBtn.MouseLeave += delegate { closeBtn.BackColor = Color.FromArgb(64, 64, 64); };
    this.Controls.Add(closeBtn);
  }

  protected override void OnResize(EventArgs e)
  {
    base.OnResize(e);
    if (closeBtn != null)
      closeBtn.Left = this.Width - closeBtn.Width - 8;
    this.Invalidate();
  }

  protected override void OnPaint(PaintEventArgs e)
  {
    base.OnPaint(e);
    using (GraphicsPath path = GetRoundedPath(new Rectangle(0, 0, Width, Height), _cornerRadius))
    {
      this.Region = new Region(path);
      e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
    }
  }

  private GraphicsPath GetRoundedPath(Rectangle rect, int radius)
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

  protected override void WndProc(ref Message m)
  {
    const int WM_NCHITTEST = 0x84;
    const int HTCAPTION = 2;
    if (m.Msg == WM_NCHITTEST)
    {
      m.Result = (IntPtr)HTCAPTION;
      return;
    }
    base.WndProc(ref m);
  }

  [STAThread]
  public static void Main()
  {
    Application.EnableVisualStyles();
    Application.Run(new SaveSessionDialog());
  }
}

// SESSION SAVER LOGIC - ORIGINAL CODE
public static class SessionSaver
{
  public static string BuildSessionFromCurrentFolder()
  {
    string exeDir = AppDomain.CurrentDomain.BaseDirectory;
    string settingsPath = Path.Combine(exeDir, "SumatraPDF-settings.txt");
    if (!File.Exists(settingsPath))
      throw new Exception("SumatraPDF-settings.txt not found in:\n" + exeDir);
    string text = File.ReadAllText(settingsPath, Encoding.UTF8);
    string sessionBlock = ExtractBlock(text, "SessionData");
    if (sessionBlock == null)
      throw new Exception("No SessionData block found.");
    List<string> sessionFiles = ExtractFilePaths(sessionBlock);
    if (sessionFiles.Count == 0)
      throw new Exception("No FilePath entries found in SessionData.");
    string fileStatesBlock = ExtractBlock(text, "FileStates");
    if (fileStatesBlock == null)
      throw new Exception("No FileStates block found.");
    List<string> allFileStateBlocks = ExtractChildBlocks(fileStatesBlock);
    List<string> matchingFileStates = FilterFileStates(allFileStateBlocks, sessionFiles);
    return BuildSessionFile(matchingFileStates, sessionBlock);
  }

  static string ExtractBlock(string text, string blockName)
  {
    int nameIndex = text.IndexOf(blockName, StringComparison.Ordinal);
    if (nameIndex < 0)
      return null;
    int firstBracket = text.IndexOf('[', nameIndex);
    if (firstBracket < 0)
      return null;
    int depth = 0;
    int i = firstBracket;
    for (; i < text.Length; i++)
    {
      char c = text[i];
      if (c == '[') depth++;
      else if (c == ']') depth--;
      if (depth == 0)
        return text.Substring(nameIndex, i - nameIndex + 1);
    }
    return null;
  }

  static List<string> ExtractFilePaths(string block)
  {
    var list = new List<string>();
    using (var reader = StringReaderFactory(block))
    {
      string line;
      while ((line = reader.ReadLine()) != null)
      {
        int idx = line.IndexOf("FilePath", StringComparison.Ordinal);
        if (idx < 0) continue;
        int eq = line.IndexOf('=', idx);
        if (eq < 0) continue;
        string path = line.Substring(eq + 1).Trim();
        if (path.Length > 0)
          list.Add(path);
      }
    }
    return list;
  }

  static StringReader StringReaderFactory(string s)
  {
    return new StringReader(s);
  }

  static List<string> ExtractChildBlocks(string parentBlock)
  {
    var blocks = new List<string>();
    int i = 0;
    bool skippedOuter = false;
    while (i < parentBlock.Length)
    {
      int start = parentBlock.IndexOf('[', i);
      if (start < 0) break;
      if (!skippedOuter)
      {
        skippedOuter = true;
        i = start + 1;
        continue;
      }
      int depth = 0;
      int j = start;
      for (; j < parentBlock.Length; j++)
      {
        char c = parentBlock[j];
        if (c == '[') depth++;
        else if (c == ']') depth--;
        if (depth == 0)
        {
          blocks.Add(parentBlock.Substring(start, j - start + 1));
          i = j + 1;
          break;
        }
      }
      if (depth != 0)
        break;
    }
    return blocks;
  }

  static List<string> FilterFileStates(List<string> blocks, List<string> sessionFiles)
  {
    var result = new List<string>();
    foreach (string block in blocks)
    {
      var paths = ExtractFilePaths(block);
      if (paths.Count == 0) continue;
      string filePath = paths[0];
      string baseName = Path.GetFileName(filePath);
      bool match = sessionFiles.Any(sf =>
        string.Equals(Path.GetFileName(sf), baseName, StringComparison.OrdinalIgnoreCase));
      if (match)
        result.Add(block);
    }
    return result;
  }

  static string BuildSessionFile(List<string> fileStates, string sessionBlock)
  {
    var sb = new StringBuilder();
    sb.AppendLine("FileStates [");
    foreach (string fs in fileStates)
      sb.AppendLine(fs);
    sb.AppendLine("]");
    sb.AppendLine();
    sb.AppendLine(sessionBlock.TrimEnd());
    sb.AppendLine();
    return sb.ToString();
  }
}
