@echo off & set "Title=My %~n0" & set set "Version=2025.10.28.001"
Title %Title% %Version%
goto MAIN
:README NOTES

The first run will write this filename.cs file for compiling which "should" be converted into this filname.exe
Recommened filename for this command is Navigator it should be placed in a SUBfolder of folder containing SumatraPDF.
Once you have the built exe thare is no need to run this source.cmd again but keep it for desired adjustments.

:NOTES END
:MAIN
REM IMPORTANT THESE FOLLOWING LINES ARE CRITICAL TO FUNCTION exporting and compiling "C# Code" to Navigator.exe
cd /d "%~dp0"
if exist config.ini echo Will not overwrite a local config.ini RENAME it first. && pause & exit /b
:: Check for required system tools
set "CSC=C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
if not exist "%CSC%" echo cannot find "%CSC%" && pause & exit /b
curl --version >nul 2>&1 || ( echo ERROR: curl is not available. Please ensure curl.exe is in PATH. && pause & exit /b )
:: Get latest config from online
curl -LO https://github.com/GitHubRulesOK/SumatraPDF-Plus/raw/master/Plus/config.ini

REM IMPORTANT the line number must be equal to the line containing :MORE-CS
set "MOREline#=35"
more +%MOREline#% "%~dpnx0" > "%~dpn0.cs"
echo using System.Reflection;[assembly: AssemblyTitle("%Title%")][assembly: AssemblyFileVersion("%Version%")][assembly: AssemblyProduct("%Username%'s %~n0")] >"%tmp%\%Version%.cs"
"%CSC%" /t:winexe /r:System.Windows.Forms.dll "%~dpn0.cs" "%tmp%\%Version%.cs" >nul
if exist "%~dpn0.exe" (
    echo Built "%~dpn0.cs" and "%~dpn0.exe" use with Config.ini&pause
) else (
    echo Failed to build executable %~dnx0.&pause
)
exit /b

SEE important note the MOREline number above must be equal to the NEXT LINE containing :MORE-CS
:MORE-CS
using System; using System.Collections.Generic; using System.Drawing; using System.IO; using System.Runtime.InteropServices; using System.Windows.Forms; using System.Diagnostics;

class TopicData
{
  public Color? Color;
  public List<string> Entries = new List<string>();
}

class NavigatorForm : Form
{
  private FlowLayoutPanel buttonPanel;
  TreeView treeView;
  Dictionary<string, Color> groupColors = new Dictionary<string, Color>();
  Dictionary<string, string> appExecutables = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
  Dictionary<string, string> globalSettings = new Dictionary<string, string>();
  Dictionary<string, string> tooltipDict = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
  Dictionary<string, Dictionary<string, TopicData>> treeData = new Dictionary<string, Dictionary<string, TopicData>>();
  string theme = "Light"; string startSide = "Left"; int startLevel = 1; int clickMode = 1; int lineHeight = 20; float fontSize = 10f;
  string targetClass = ""; bool clingRight; int clingOffset = 0; int timerInterval = 0;
  RECT rect, lastRect; Timer tracker = new Timer(); ToolTip tip = new ToolTip(); ToolTip nodeTip = new ToolTip(); Color defaultThemeColor = ColorTranslator.FromHtml("#FF00DD");
  Color lightTextColor = Color.Black; Color lightBackColor = ColorTranslator.FromHtml("#FFEEDD"); Color lightButtonColor = ColorTranslator.FromHtml("#FFF8DC");
  Color darkButtonColor = ColorTranslator.FromHtml("#444444"); Color darkBackColor = ColorTranslator.FromHtml("#222222"); Color darkTextColor = Color.White;
  [DllImport("user32.dll")] static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
  [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
  [DllImport("user32.dll")] private static extern IntPtr SendMessage(IntPtr hWnd, int msg, IntPtr wp, IntPtr lp);
  [DllImport("user32.dll")] static extern bool SetProcessDPIAware();
  const int TVM_SETITEMHEIGHT = 0x1100 + 27;
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }

  public NavigatorForm()
  {
    SetProcessDPIAware();
    this.Text = "Navigator"; this.StartPosition = FormStartPosition.Manual; this.Size = new Size(260, 500); // this.Icon = new Icon("navigator.ico");
    var layout = new TableLayoutPanel { Dock = DockStyle.Fill, RowCount = 2, ColumnCount = 1 };
    layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 50)); layout.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
    buttonPanel = new FlowLayoutPanel { Dock = DockStyle.Fill };
    buttonPanel.Controls.Add(MakeButton("🔄", "Reload", (s, e) => ReloadIni()));
    buttonPanel.Controls.Add(MakeButton("➖", "Collapse", (s, e) => treeView.CollapseAll()));
    buttonPanel.Controls.Add(MakeButton("➕", "Expand", (s, e) => treeView.ExpandAll()));
    buttonPanel.Controls.Add(MakeButton("🌓", "Mode", (s, e) => ToggleTheme()));
    buttonPanel.Controls.Add(MakeButton("❓", "Help", (s, e) => OpenHelp()));
    treeView = new TreeView { Dock = DockStyle.Fill, DrawMode = TreeViewDrawMode.OwnerDrawText };
    treeView.DrawNode += TreeView_DrawNode; treeView.MouseDown += TreeView_MouseDown; treeView.MouseMove += TreeView_MouseMove;
    treeView.Indent = 8;
    layout.Controls.Add(buttonPanel, 0, 0); layout.Controls.Add(treeView, 0, 1); this.Controls.Add(layout);
    string exeDir = Path.GetDirectoryName(Application.ExecutablePath);
    string iniPath = Path.Combine(exeDir, "config.ini");
    LoadIni(iniPath); UpdateButtonTooltips(); ApplyTreeViewDirection();
    ApplyTheme(); BuildTree(); SetTreeViewItemHeight(lineHeight); treeView.Font = new Font(treeView.Font.FontFamily, fontSize);
    treeView.NodeMouseClick -= TreeView_NodeMouseClick; treeView.NodeMouseDoubleClick -= TreeView_NodeMouseDoubleClick;
    if (clickMode == 1)
      treeView.NodeMouseClick += TreeView_NodeMouseClick;
    else
      treeView.NodeMouseDoubleClick += TreeView_NodeMouseDoubleClick;
    ExpandToLevel(treeView.Nodes, startLevel);
    StartTracking();
    // ValidateSettings(); // For debugging
  }

  private void SetTreeViewItemHeight(int height)
  {
    SendMessage(treeView.Handle, TVM_SETITEMHEIGHT, (IntPtr)height, IntPtr.Zero);
    // MessageBox.Show("SetTreeViewItemHeight called with: " + height, "Debug", MessageBoxButtons.OK, MessageBoxIcon.Information);
  }

  void ExpandToLevel(TreeNodeCollection nodes, int level)
  {
    foreach (TreeNode node in nodes)
    {
      if (level > 0)
      {
        node.Expand();
        ExpandToLevel(node.Nodes, level - 1);
      }
    }
  }

  Button MakeButton(string icon, string key, EventHandler click)
  {
    var btn = new Button { Text = icon, Width = 40, Height = 40, Tag = key };
    btn.Click += click;
    if (tooltipDict.ContainsKey(key))
      tip.SetToolTip(btn, tooltipDict[key]);
    else
      tip.SetToolTip(btn, key);
    return btn;
  }

  private void UpdateButtonTooltips()
{
    foreach (Control ctrl in buttonPanel.Controls)
    {
        Button btn = ctrl as Button;
        if (btn != null)
        {
            string key = btn.Tag != null ? btn.Tag.ToString() : null;
            if (key != null && tooltipDict.ContainsKey(key))
                tip.SetToolTip(btn, tooltipDict[key]);
            else
                tip.SetToolTip(btn, key ?? btn.Text); // Fallback to key or button text
        }
    }
}

private void ApplyTreeViewDirection()
{
    treeView.RightToLeft = startSide.Equals("Right", StringComparison.OrdinalIgnoreCase)
        ? RightToLeft.Yes
        : RightToLeft.No;
    treeView.RightToLeftLayout = treeView.RightToLeft == RightToLeft.Yes;
}

  void ReloadIni()
  {
    // Stopwatch sw = new Stopwatch(); sw.Start(); // Block for debugging
    // Cache current settings to detect changes
    int oldClickMode = clickMode;
    int oldLineHeight = lineHeight;
    float oldFontSize = fontSize;
    string oldTheme = theme;
    string oldStartSide = startSide;
    int oldStartLevel = startLevel;
    // Temporary data structures for incremental updates
    var newGroupColors = new Dictionary<string, Color>();
    var newAppExecutables = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
    var newTooltipDict = new Dictionary<string, string>();
    var newTreeData = new Dictionary<string, Dictionary<string, TopicData>>();
    // Load new INI data into temporary structures
    string exeDir = Path.GetDirectoryName(Application.ExecutablePath);
    string iniPath = Path.Combine(exeDir, "config.ini");
    LoadIni(iniPath, newGroupColors, newAppExecutables, newTooltipDict, newTreeData);
    // Update only if settings changed
    if (oldClickMode != clickMode || oldLineHeight != lineHeight || oldFontSize != fontSize ||
      oldTheme != theme || oldStartSide != startSide || oldStartLevel != startLevel)
    {
      ApplyTreeViewDirection();
      ApplyTheme();
      SetTreeViewItemHeight(lineHeight);
      treeView.Font = new Font(treeView.Font.FontFamily, fontSize);
      treeView.NodeMouseClick -= TreeView_NodeMouseClick;
      treeView.NodeMouseDoubleClick -= TreeView_NodeMouseDoubleClick;
      if (clickMode == 1)
        treeView.NodeMouseClick += TreeView_NodeMouseClick;
      else
        treeView.NodeMouseDoubleClick += TreeView_NodeMouseDoubleClick;
    }
    // Update TreeView incrementally
    UpdateTreeView(newGroupColors, newTreeData);
    // Replace old data with new
    groupColors = newGroupColors;
    appExecutables = newAppExecutables;
    tooltipDict = newTooltipDict;
    treeData = newTreeData;
    ExpandToLevel(treeView.Nodes, startLevel);
    treeView.Refresh();
    UpdateButtonTooltips();
    // ValidateSettings(); sw.Stop(); // Block for debugging
    // MessageBox.Show(string.Format("ReloadIni took {0} ms", sw.ElapsedMilliseconds), "Debug", MessageBoxButtons.OK, MessageBoxIcon.Information);
  }

  void ToggleTheme()
  {
    bool isDark = theme == "Light";
    theme = isDark ? "Dark" : "Light";
    Color backColor = isDark ? darkBackColor : lightBackColor;
    Color buttonColor = isDark ? darkButtonColor : lightButtonColor;
    Color textColor = isDark ? darkTextColor : lightTextColor;
    this.BackColor = backColor;
    treeView.BackColor = backColor;
    treeView.ForeColor = textColor;
    foreach (Control ctrl in this.Controls)
    {
      TableLayoutPanel layout = ctrl as TableLayoutPanel;
      if (layout != null)
      {
        layout.BackColor = backColor;
        foreach (Control sub in layout.Controls)
        {
          FlowLayoutPanel flow = sub as FlowLayoutPanel;
          if (flow != null)
          {
            flow.BackColor = backColor;
            foreach (Control btn in flow.Controls)
            {
              Button b = btn as Button;
              if (b != null)
              {
                b.BackColor = buttonColor;
                b.ForeColor = textColor;
              }
            }
          }
        }
      }
    }
    defaultThemeColor = backColor;
    treeView.Refresh();
  }

  void ApplyTheme()
  {
    Color backColor, buttonColor, textColor;
    if (theme == "Dark")
    {
      backColor = darkBackColor; buttonColor = darkButtonColor; textColor = darkTextColor;
    }
    else
    {
      backColor = lightBackColor; buttonColor = lightButtonColor; textColor = lightTextColor;
    }
    this.BackColor = backColor; treeView.BackColor = backColor; treeView.ForeColor = textColor; defaultThemeColor = backColor;
    foreach (Control ctrl in this.Controls)
    {
      TableLayoutPanel layout = ctrl as TableLayoutPanel;
      if (layout != null)
      {
        layout.BackColor = backColor;
        foreach (Control sub in layout.Controls)
        {
          FlowLayoutPanel flow = sub as FlowLayoutPanel;
          if (flow != null)
          {
            flow.BackColor = backColor;
            foreach (Control btn in flow.Controls)
            {
              Button b = btn as Button;
              if (b != null)
              {
                b.BackColor = buttonColor; b.ForeColor = textColor;
              }
            }
          }
        }
      }
    }
  }

  void LoadIni(string path)
  {
    LoadIni(path, groupColors, appExecutables, tooltipDict, treeData);
  }

  void LoadIni(string path, Dictionary<string, Color> targetGroupColors, Dictionary<string, string> targetAppExecutables,
    Dictionary<string, string> targetTooltipDict, Dictionary<string, Dictionary<string, TopicData>> targetTreeData)
  {
    // Stopwatch sw = new Stopwatch(); sw.Start(); // Block for debugging
    if (!File.Exists(path))
    {
      MessageBox.Show("INI file missing:\n" + path, "Navigator Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
      return;
    }
    string currentGroup = null, currentTopic = null;
    int untitledCount = 0;
    try
      {
        using (StreamReader reader = new StreamReader(path, System.Text.Encoding.UTF8))
        {
          string line;
          while ((line = reader.ReadLine()) != null)
          {
            line = line.Trim();
            if (line.Length == 0 || line.StartsWith(";")) continue;
            try
            {
              if (line.StartsWith("[") && line.EndsWith("]"))
              {
                currentGroup = line.Substring(1, line.Length - 2).Trim();
                currentTopic = null;
                continue;
              }
              string[] parts = line.Split(new[] { '=' }, 2);
              string key = parts[0].Trim();
              string value = parts.Length == 2 ? parts[1].Trim() : null;
              if (currentGroup == null)
              {
                if (value != null)
                {
                  globalSettings[key] = value;
                  if (key.Equals("Theme", StringComparison.OrdinalIgnoreCase))
                    theme = value;
                  else if (key.Equals("Start Level", StringComparison.OrdinalIgnoreCase))
                  {
                    int level;
                    if (int.TryParse(value, out level))
                      startLevel = level;
                  }
              else if (key.Equals("Start Side", StringComparison.OrdinalIgnoreCase))
                startSide = value;
              else if (key.Equals("Click", StringComparison.OrdinalIgnoreCase))
              {
                int mode;
                if (int.TryParse(value, out mode) && (mode == 1 || mode == 2))
                {
                  clickMode = mode;
                  // MessageBox.Show("Click set to: " + clickMode, "Debug", MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
                else
                  MessageBox.Show("Invalid Click value in INI: Must be 1 or 2", "INI Warning", MessageBoxButtons.OK, MessageBoxIcon.Warning);
              }
              else if (key.Equals("LineHeight", StringComparison.OrdinalIgnoreCase))
              {
                int height;
                if (int.TryParse(value, out height) && height >= 10 && height <= 50)
                {
                  lineHeight = height;
                  // MessageBox.Show("LineHeight set to: " + height, "Debug", MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
                else
                  MessageBox.Show("Invalid LineHeight value in INI: Must be between 10 and 50", "INI Warning", MessageBoxButtons.OK, MessageBoxIcon.Warning);
              }
                  else if (key.Equals("FontSize", StringComparison.OrdinalIgnoreCase))
                  {
                    float size;
                    if (float.TryParse(value, out size) && size >= 6 && size <= 24)
                    {
                      fontSize = size;
                  // MessageBox.Show("FontSize set to: " + size, "Debug", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                    else
                      MessageBox.Show("Invalid FontSize value in INI: Must be between 6 and 24", "INI Warning", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                  }
                }
            continue;
          }
          if (currentGroup.Equals("Tooltips", StringComparison.OrdinalIgnoreCase))
          {
            if (value != null)
              targetTooltipDict[key] = value;
            continue;
          }
          if (currentGroup.Equals("Tracking", StringComparison.OrdinalIgnoreCase))
          {
            if (value == null) continue;
            if (key.Equals("TargetClass", StringComparison.OrdinalIgnoreCase))
              targetClass = value;
            else if (key.Equals("ClingSide", StringComparison.OrdinalIgnoreCase))
              clingRight = value.ToLower() == "right";
            else if (key.Equals("WindowWidth", StringComparison.OrdinalIgnoreCase))
            {
              int temp;
              if (int.TryParse(value, out temp))
                this.Width = temp;
            }
            else if (key.Equals("ClingOffset", StringComparison.OrdinalIgnoreCase))
              int.TryParse(value, out clingOffset);
            else if (key.Equals("TimerMilliSecs", StringComparison.OrdinalIgnoreCase))
              int.TryParse(value, out timerInterval);
            else
              MessageBox.Show("Unknown Tracking key:\n" + line, "INI Warning", MessageBoxButtons.OK, MessageBoxIcon.Information);
            continue;
          }
          if (string.Equals(currentGroup, "Apps", StringComparison.OrdinalIgnoreCase))
          {
            if (value != null)
              targetAppExecutables[key] = value.Trim('"');
            else
              MessageBox.Show("Malformed App entry:\n" + line, "INI Warning", MessageBoxButtons.OK, MessageBoxIcon.Information);
            continue;
          }
          if (value != null)
          {
            if (key.Equals("GroupColor", StringComparison.OrdinalIgnoreCase))
            {
              targetGroupColors[currentGroup] = ColorTranslator.FromHtml(value);
              continue;
            }

            if (line.Contains("=") && !line.TrimStart().StartsWith("App", StringComparison.OrdinalIgnoreCase))
            {
              currentTopic = key;
              string colorHex = value;
              if (!targetTreeData.ContainsKey(currentGroup))
                targetTreeData[currentGroup] = new Dictionary<string, TopicData>();
              targetTreeData[currentGroup][currentTopic] = new TopicData { Color = ColorTranslator.FromHtml(colorHex) };
              continue;
            }
          }
          if (!targetTreeData.ContainsKey(currentGroup))
            targetTreeData[currentGroup] = new Dictionary<string, TopicData>();
          if (string.IsNullOrEmpty(currentTopic))
            currentTopic = "Untitled " + (++untitledCount);
          if (!targetTreeData[currentGroup].ContainsKey(currentTopic))
            targetTreeData[currentGroup][currentTopic] = new TopicData();
          targetTreeData[currentGroup][currentTopic].Entries.Add(line);
            }
            catch (Exception ex)
            {
              MessageBox.Show("INI parsing error:\n" + line + "\n\n" + ex.Message, "Navigator Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
          }
        }
        // sw.Stop(); // For debugging 
        // MessageBox.Show(string.Format("LoadIni took {0} ms", sw.ElapsedMilliseconds), "Debug", MessageBoxButtons.OK, MessageBoxIcon.Information);
      }
         catch (Exception ex)
         {
             MessageBox.Show("Failed to read INI file (possible encoding issue):\n" + path + "\n\n" + ex.Message + 
                             "\nPlease ensure the file is saved in UTF-8 encoding.", 
                             "Navigator Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
         }
     }


  void UpdateTreeView(Dictionary<string, Color> newGroupColors, Dictionary<string, Dictionary<string, TopicData>> newTreeData)
  {
    // Stopwatch sw = new Stopwatch(); sw.Start(); // For debugging 
    // Update TreeView incrementally
    var existingGroups = new Dictionary<string, TreeNode>();
    foreach (TreeNode groupNode in treeView.Nodes)
      existingGroups[groupNode.Text] = groupNode;
    treeView.BeginUpdate(); // Reduces UI flicker
    foreach (var group in newTreeData)
    {
      TreeNode groupNode;
      if (existingGroups.ContainsKey(group.Key))
      {
        groupNode = existingGroups[group.Key];
        groupNode.Nodes.Clear(); // Clear out topics
      }
      else
      {
        groupNode = new TreeNode(group.Key);
        treeView.Nodes.Add(groupNode);
      }
      if (newGroupColors.ContainsKey(group.Key))
        groupNode.BackColor = newGroupColors[group.Key];
      var existingTopics = new Dictionary<string, TreeNode>();
      foreach (TreeNode topicNode in groupNode.Nodes)
        existingTopics[topicNode.Text] = topicNode;
      foreach (var topic in group.Value)
      {
        TreeNode topicNode;
        if (existingTopics.ContainsKey(topic.Key))
        {
          topicNode = existingTopics[topic.Key];
          topicNode.Nodes.Clear(); // Clear out entries
        }
        else
        {
          topicNode = new TreeNode(topic.Key);
          groupNode.Nodes.Add(topicNode);
        }
        foreach (string entry in topic.Value.Entries)
          topicNode.Nodes.Add(new TreeNode(entry));
      }
    }
    // Remove any groups no longer in newTreeData
    foreach (var existing in existingGroups)
    {
      if (!newTreeData.ContainsKey(existing.Key))
        treeView.Nodes.Remove(existing.Value);
    }
    treeView.EndUpdate();
    // sw.Stop(); // For debugging 
    // MessageBox.Show(string.Format("UpdateTreeView took {0} ms", sw.ElapsedMilliseconds), "Debug", MessageBoxButtons.OK, MessageBoxIcon.Information);
  }

  void OpenHelp()
  {
    if (!globalSettings.ContainsKey("Help"))
    {
      MessageBox.Show("No help file defined in INI.", "Navigator", MessageBoxButtons.OK, MessageBoxIcon.Information);
      return;
    }
    string helpFile = globalSettings["Help"];
    string exeDir = Path.GetDirectoryName(Application.ExecutablePath);
    string fullPath = Path.Combine(exeDir, helpFile);

    if (File.Exists(fullPath))
      Process.Start("notepad.exe", fullPath);
    else
      MessageBox.Show("ERROR: Help file not found:\n" + fullPath, "Navigator", MessageBoxButtons.OK, MessageBoxIcon.Error);
  }

  void StartTracking()
  {
    tracker.Interval = timerInterval;
    tracker.Tick += (s, e) => AlignToTarget();
    tracker.Start();
  }

  void AlignToTarget()
  {
    RECT tempRect;
    IntPtr hwnd = FindWindow(targetClass, null);
    if (hwnd == IntPtr.Zero || !GetWindowRect(hwnd, out tempRect)) return;
    if (tempRect.Left != lastRect.Left || tempRect.Top != lastRect.Top ||
      tempRect.Right != lastRect.Right || tempRect.Bottom != lastRect.Bottom)
    {
      int height = tempRect.Bottom - tempRect.Top;
      this.Height = height;
      this.Top = tempRect.Top;
      this.Left = clingRight ? tempRect.Right - clingOffset : tempRect.Left - this.Width + clingOffset;
      lastRect = tempRect; rect = tempRect;
    }
  }

  void BuildTree()
  {
    UpdateTreeView(groupColors, treeData); // Reuse UpdateTreeView for initial build
  }

  void ValidateSettings() // This block is not called unless for debugging ? should it be on load ini ?
  {
    if (string.IsNullOrEmpty(targetClass))
      MessageBox.Show("Warning: TargetClass not defined in INI.", "INI Warning", MessageBoxButtons.OK, MessageBoxIcon.Warning);
    if (timerInterval <= 0)
      MessageBox.Show("Warning: TimerMilliSecs not set or invalid.", "INI Warning", MessageBoxButtons.OK, MessageBoxIcon.Warning);
    if (treeView.Nodes.Count == 0)
      MessageBox.Show("Warning: No tree entries loaded.", "INI Warning", MessageBoxButtons.OK, MessageBoxIcon.Warning);
    if (lineHeight < 10 || lineHeight > 50)
      MessageBox.Show(string.Format("Warning: LineHeight ({0}) is outside valid range (10-50).", lineHeight), "INI Warning", MessageBoxButtons.OK, MessageBoxIcon.Warning);
    if (clickMode != 1 && clickMode != 2)
      MessageBox.Show(string.Format("Warning: Click mode ({0}) is invalid. Must be 1 or 2.", clickMode), "INI Warning", MessageBoxButtons.OK, MessageBoxIcon.Warning);
    if (fontSize < 6 || fontSize > 24)
      MessageBox.Show(string.Format("Warning: FontSize ({0}) is outside valid range (6-24).", fontSize), "INI Warning", MessageBoxButtons.OK, MessageBoxIcon.Warning);
  }

  void TreeView_DrawNode(object sender, DrawTreeNodeEventArgs e)
{
    TreeNode node = e.Node;
    int level = GetNodeLevel(node);
    Color bgColor = Color.White, textColor = Color.Black;
    if (level == 0)
    {
        bgColor = groupColors.ContainsKey(node.Text) ? groupColors[node.Text] : Color.LightGray;
        textColor = GetContrastingTextColor(bgColor);
    }
    else if (level == 1)
    {
        TreeNode groupNode = node.Parent;
        string groupName = groupNode.Text, topicName = node.Text;
        Color groupColor = groupColors.ContainsKey(groupName) ? groupColors[groupName] : Color.LightGray;
        Color topicColor = treeData.ContainsKey(groupName) && treeData[groupName].ContainsKey(topicName) && treeData[groupName][topicName].Color.HasValue
            ? treeData[groupName][topicName].Color.Value : groupColor;
        bgColor = topicColor;
        textColor = GetContrastingTextColor(bgColor);
    }
    else
    {
        bgColor = defaultThemeColor;
        textColor = GetContrastingTextColor(bgColor);
    }
    Rectangle fullBounds = new Rectangle(0, e.Bounds.Top, treeView.Width, e.Bounds.Height);
    using (Brush bgBrush = new SolidBrush(bgColor))
        e.Graphics.FillRectangle(bgBrush, fullBounds);
    // Adjust text alignment based on RightToLeft setting
    TextFormatFlags flags = treeView.RightToLeft == RightToLeft.Yes
        ? TextFormatFlags.VerticalCenter | TextFormatFlags.Right
        : TextFormatFlags.VerticalCenter | TextFormatFlags.Left;
    TextRenderer.DrawText(e.Graphics, node.Text, treeView.Font, e.Bounds, textColor, flags);
}

  void TreeView_MouseDown(object sender, MouseEventArgs e)
  {
    TreeNode node = treeView.GetNodeAt(e.Location);
    if (node != null)
    {
      treeView.SelectedNode = node;
      if (node.Level < 2)
        node.Toggle();
    }
  }

  void TreeView_NodeMouseDoubleClick(object sender, TreeNodeMouseClickEventArgs e)
  {
    if (clickMode == 2)
    {
      // MessageBox.Show("Double-click handler triggered", "Debug", MessageBoxButtons.OK, MessageBoxIcon.Information);
      LaunchEntry(e.Node);
    }
  }

  void TreeView_NodeMouseClick(object sender, TreeNodeMouseClickEventArgs e)
  {
    if (clickMode == 1 && e.Button == MouseButtons.Left)
    {
      // MessageBox.Show("Single-click handler triggered", "Debug", MessageBoxButtons.OK, MessageBoxIcon.Information);
      LaunchEntry(e.Node);
    }
  }

  private void LaunchEntry(TreeNode node)
  {
    // Stopwatch sw = new Stopwatch(); sw.Start(); // For debugging 
    if (node.Level != 2) return;
    string entry = node.Text;
    string appKey, arguments;
    int spaceIndex = entry.IndexOf(' ');
    if (spaceIndex != -1)
    {
      appKey = entry.Substring(0, spaceIndex).Trim();
      arguments = entry.Substring(spaceIndex + 1).Trim();
    }
    else
    {
      appKey = entry.Trim();
      arguments = "";
    }
    if (appExecutables.ContainsKey(appKey))
    {
      string execPath = appExecutables[appKey];
      if (File.Exists(execPath))
      {
        try
        {
          Process.Start(execPath, arguments);
        }
        catch (Exception ex)
        {
          MessageBox.Show("Failed to launch:\n" + ex.Message, "Navigator Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
      }
      else
        MessageBox.Show("Executable not found:\n" + execPath, "Navigator Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
    }
    else
      MessageBox.Show("App key not defined:\n" + appKey, "Navigator Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
    // sw.Stop(); // For debugging 
    // MessageBox.Show(string.Format("LaunchEntry took {0} ms", sw.ElapsedMilliseconds), "Debug", MessageBoxButtons.OK, MessageBoxIcon.Information);
  }

  void TreeView_MouseMove(object sender, MouseEventArgs e)
  {
    TreeNode node = treeView.GetNodeAt(e.Location);
    if (node != null && node.Bounds.Contains(e.Location))
    {
      string tipText = node.Text;
      if (nodeTip.GetToolTip(treeView) != tipText)
        nodeTip.SetToolTip(treeView, tipText);
    }
    else
    {
      nodeTip.SetToolTip(treeView, "");
    }
  }

  int GetNodeLevel(TreeNode node)
  {
    int level = 0;
    while (node.Parent != null) { level++; node = node.Parent; }
    return level;
  }

  Color GetContrastingTextColor(Color bg)
  {
    int brightness = (int)Math.Sqrt(bg.R * bg.R * 0.241 + bg.G * bg.G * 0.691 + bg.B * bg.B * 0.068);
    return brightness < 130 ? Color.White : Color.Black;
  }

  [STAThread]
  static void Main()
  {
    Application.EnableVisualStyles();
    Application.SetCompatibleTextRenderingDefault(false);
    Application.Run(new NavigatorForm());
  }
}





