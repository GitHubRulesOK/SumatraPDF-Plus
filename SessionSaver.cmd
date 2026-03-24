/*
C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc  /target:winexe /platform:x86 "%~0"  
exit /b

After running in windows. This SessionSaver.CMD file becomes SessionSaver.exe
It is one of 2 methods this one saves files with a date for mixed usage the other
is SessionSaverDialog which asks for a Folder to be used for -appdata collections.

The idea is to allow saving the current set of open tabs for edit and reuse.
See the example at https://github.com/sumatrapdfreader/sumatrapdf/issues/43

It should be run from advanced settings entry pointing to same folder as SumatraPDF-settings.txt  

ExternalViewers [
	[
		CommandLine = C:\Users\ path to folder \SumatraPDF\SessionSaver.exe
		Name = Session &Saver
		Key = s
	]
]

*/

using System;
using System.IO;
using System.Text;
using System.Collections.Generic;
using System.Linq;

class SessionSaver
{
    static void Main(string[] args)
    {
        string exeDir = AppDomain.CurrentDomain.BaseDirectory;
        string settingsPath = Path.Combine(exeDir, "SumatraPDF-settings.txt");

        if (!File.Exists(settingsPath))
        {
            Console.WriteLine("SumatraPDF-settings.txt not found in:");
            Console.WriteLine(exeDir);
            return;
        }

        string text = File.ReadAllText(settingsPath, Encoding.UTF8);

        // Extract SessionData block
        string sessionBlock = ExtractBlock(text, "SessionData");
        if (sessionBlock == null)
        {
            Console.WriteLine("No SessionData block found.");
            return;
        }

        // Get all file paths from SessionData (TabStates)
        List<string> sessionFiles = ExtractFilePaths(sessionBlock);
        if (sessionFiles.Count == 0)
        {
            Console.WriteLine("No FilePath entries found in SessionData.");
            return;
        }

        // Extract FileStates block
        string fileStatesBlock = ExtractBlock(text, "FileStates");
        if (fileStatesBlock == null)
        {
            Console.WriteLine("No FileStates block found.");
            return;
        }

        // Extract individual FileStates child blocks
        List<string> allFileStateBlocks = ExtractChildBlocks(fileStatesBlock);

        // Filter FileStates to only those matching session filenames
        List<string> matchingFileStates = FilterFileStates(allFileStateBlocks, sessionFiles);

        // Build output
        string output = BuildSessionFile(matchingFileStates, sessionBlock);

        // Timestamped filename
        string timestamp = DateTime.Now.ToString("yyyy-MM-dd-HH_mm_ss");
        string outFile = Path.Combine(exeDir, "Session-" + timestamp + ".txt");

        File.WriteAllText(outFile, output, Encoding.UTF8);
        Console.WriteLine("Saved session to " + outFile);
    }

    // Extracts a named block like "SessionData [ ... ]" with nested brackets
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
            {
                return text.Substring(nameIndex, i - nameIndex + 1);
            }
        }

        return null;
    }

    // Extracts all FilePath = ... lines from a block
    static List<string> ExtractFilePaths(string block)
    {
        var list = new List<string>();
        using (var reader = new StringReader(block))
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

    // Extracts child [ ... ] blocks inside a parent block (e.g. FileStates)
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
                // Skip the outer "[“ that belongs to "FileStates ["
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
                break; // malformed
        }

        return blocks;
    }

    // Keep only FileStates whose filename matches any SessionData filename
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

    // Build final session file content
    static string BuildSessionFile(List<string> fileStates, string sessionBlock)
    {
        var sb = new StringBuilder();

        sb.AppendLine("FileStates [");
        foreach (string fs in fileStates)
        {
            sb.AppendLine(fs);
        }
        sb.AppendLine("]");
        sb.AppendLine();
        sb.AppendLine(sessionBlock.TrimEnd());
        sb.AppendLine();

        return sb.ToString();
    }
}
