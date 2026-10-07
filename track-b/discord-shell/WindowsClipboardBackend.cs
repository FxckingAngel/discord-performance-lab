#nullable enable

using System;
using System.Collections.Specialized;
using System.ComponentModel;
using System.Drawing;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Forms;

namespace KoroneDiscordShell;

public sealed class WindowsClipboardBackend : IClipboardBackend
{
    private const uint WmCopy = 0x0301;
    private const uint WmCut = 0x0300;
    private const uint WmPaste = 0x0302;

    public void SetText(string text)
    {
        ArgumentNullException.ThrowIfNull(text);
        Clipboard.SetText(text, TextDataFormat.UnicodeText);
    }

    public void SetImage(byte[] imageBytes, string? imageSource)
    {
        ArgumentNullException.ThrowIfNull(imageBytes);
        using var stream = new MemoryStream(imageBytes, writable: false);
        using var sourceImage = Image.FromStream(stream, useEmbeddedColorManagement: false, validateImageData: true);
        using var bitmap = new Bitmap(sourceImage);
        var data = new DataObject();
        data.SetData(DataFormats.Bitmap, false, bitmap);
        if (!string.IsNullOrWhiteSpace(imageSource))
        {
            data.SetData(DataFormats.Html, false, $"<img src=\"{EscapeHtmlAttribute(imageSource)}\">");
        }

        Clipboard.SetDataObject(data, copy: true);
    }

    public void SetFile(string filePath)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(filePath);
        var fullPath = Path.GetFullPath(filePath);
        if (!File.Exists(fullPath)) throw new FileNotFoundException("Clipboard file was not found.", fullPath);

        var files = new StringCollection { fullPath };
        var data = new DataObject();
        data.SetData(DataFormats.FileDrop, false, files);
        data.SetData("FileNameW", false, BuildFileNameWPayload(fullPath));
        Clipboard.SetDataObject(data, copy: true);
    }

    public void CopyCommand() => SendEditMessage(WmCopy);

    public void CutCommand() => SendEditMessage(WmCut);

    public void PasteCommand() => SendEditMessage(WmPaste);

    public string ReadText()
    {
        return Clipboard.ContainsText(TextDataFormat.UnicodeText)
            ? Clipboard.GetText(TextDataFormat.UnicodeText)
            : string.Empty;
    }

    public bool HasImage => Clipboard.ContainsImage()
        || Clipboard.ContainsData(DataFormats.Bitmap)
        || Clipboard.ContainsData(DataFormats.Dib)
        || Clipboard.ContainsData(DataFormats.EnhancedMetafile);

    internal static byte[] BuildFileNameWPayload(string filePath)
    {
        return Encoding.Unicode.GetBytes(filePath + "\0");
    }

    private static void SendEditMessage(uint message)
    {
        var target = GetForegroundWindow();
        if (target == IntPtr.Zero) return;
        _ = SendMessage(target, message, IntPtr.Zero, IntPtr.Zero);
    }

    private static string EscapeHtmlAttribute(string value)
    {
        return value.Replace("&", "&amp;", StringComparison.Ordinal)
            .Replace("\"", "&quot;", StringComparison.Ordinal)
            .Replace("<", "&lt;", StringComparison.Ordinal)
            .Replace(">", "&gt;", StringComparison.Ordinal);
    }

    [DllImport("user32.dll")]
    private static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern IntPtr SendMessage(IntPtr windowHandle, uint message, IntPtr wParam, IntPtr lParam);
}
