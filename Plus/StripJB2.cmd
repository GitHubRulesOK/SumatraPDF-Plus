/*&@cls
C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe /nologo /platform:x86  "%~f0"
@REM important we exit the cmd
@exit /b
*/
using System; using System.IO; using System.Text;

class StripJB2
{
    static readonly byte[] Magic = new byte[] { 0x97, 0x4A, 0x42, 0x32, 0x0D, 0x0A, 0x1A, 0x0A, 0x01, 0x00, 0x00, 0x00, 0x01 };
    static int Main(string[] args)
    {
        if (args.Length != 1) { Console.WriteLine("Usage: StripJB2 <pdf-file>"); return 1; }
        string input = args[0]; string output = Path.Combine( Path.GetDirectoryName(input), Path.GetFileNameWithoutExtension(input) + "_stripped-JB2.pdf" );
        byte[] pdf;
        try { pdf = File.ReadAllBytes(input); }
        catch (Exception ex) { Console.WriteLine("Error reading file: " + ex.Message); return 1; }
        byte[] needle = Encoding.ASCII.GetBytes("/JBIG2Decode"); byte[] streamTok = Encoding.ASCII.GetBytes("stream");
        int pos = 0; int fixedCount = 0;
        while ((pos = IndexOf(pdf, needle, pos)) != -1)
        {
            int streamPos = IndexOf(pdf, streamTok, pos);
            if (streamPos < 0) break;
            int dataStart = streamPos + streamTok.Length;
            while (dataStart < pdf.Length && pdf[dataStart] <= 0x20) // skip whitespace after "stream"
                dataStart++;
            if (Matches(pdf, dataStart, Magic)) { pdf = RemoveBytes(pdf, dataStart, Magic.Length); fixedCount++; } // check for magic header
            pos = dataStart;
        }
        try { File.WriteAllBytes(output, pdf); }
        catch (Exception ex) { Console.WriteLine("Error writing output: " + ex.Message); return 1; }
        Console.WriteLine("Done. Fixed streams: " + fixedCount); Console.WriteLine("Output: " + output);
        return 0;
    }
    static int IndexOf(byte[] data, byte[] pattern, int start)
    {
        for (int i = start; i <= data.Length - pattern.Length; i++)
        {
            int j = 0;
            while (j < pattern.Length && data[i + j] == pattern[j]) j++;
            if (j == pattern.Length) return i;
        }
        return -1;
    }

    static bool Matches(byte[] data, int pos, byte[] pattern)
    {
        if (pos + pattern.Length > data.Length) return false;
        for (int i = 0; i < pattern.Length; i++)
            if (data[pos + i] != pattern[i]) return false;
        return true;
    }

    static byte[] RemoveBytes(byte[] data, int pos, int count)
    {
        byte[] result = new byte[data.Length - count]; Buffer.BlockCopy(data, 0, result, 0, pos);
        Buffer.BlockCopy(data, pos + count, result, pos, data.Length - pos - count); return result;
    }
}
