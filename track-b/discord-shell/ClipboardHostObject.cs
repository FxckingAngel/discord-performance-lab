#nullable enable

using System.Collections.Specialized;
using System.Drawing;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading;
using System;
using System.Windows.Forms;

namespace KoroneDiscordShell;

public interface IClipboardBackend
{
    void SetText(string text);

    void SetImage(byte[] imageBytes, string? imageSource);

    void SetFile(string filePath);

    void CopyCommand();

    void CutCommand();

    void PasteCommand();

    string ReadText();

    bool HasImage { get; }
}

public sealed class ClipboardHostObject
{
    private readonly IClipboardBackend backend;

    public ClipboardHostObject(IClipboardBackend backend)
    {
        this.backend = backend ?? throw new ArgumentNullException(nameof(backend));
    }

    public void Copy(string? text)
    {
        if (string.IsNullOrEmpty(text))
        {
            backend.CopyCommand();
            return;
        }

        backend.SetText(text);
    }

    public void CopyImage(byte[] imageArrayBuffer, string? imageSource)
    {
        ArgumentNullException.ThrowIfNull(imageArrayBuffer);
        backend.SetImage((byte[])imageArrayBuffer.Clone(), imageSource);
    }

    public void CopyFile(string filePath)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(filePath);
        backend.SetFile(filePath);
    }

    public void Cut() => backend.CutCommand();

    public void Paste() => backend.PasteCommand();

    public string Read() => backend.ReadText();

    public bool HasMixedContent()
    {
        return !string.IsNullOrWhiteSpace(backend.ReadText()) && backend.HasImage;
    }
}

internal sealed class ValidatedClipboardBackend : IClipboardBackend
{
    private const int MaxImageBytes = 16 * 1024 * 1024;
    private const int MaxImageDimension = 8192;
    private const long MaxImagePixels = 67_108_864;

    public bool HasImage => Execute("detect image data", Clipboard.ContainsImage);

    public bool HasFileDrop => Execute("detect file-drop data", Clipboard.ContainsFileDropList);

    public void SetText(string value)
    {
        ArgumentException.ThrowIfNullOrEmpty(value);
        Execute("set text", () => Clipboard.SetText(value, TextDataFormat.UnicodeText));
    }

    public void SetImage(byte[] imageBytes, string? imageSource)
    {
        ArgumentNullException.ThrowIfNull(imageBytes);
        if (imageBytes.Length == 0) throw new ArgumentException("Image data cannot be empty.", nameof(imageBytes));
        if (imageBytes.Length > MaxImageBytes)
        {
            throw new ArgumentException($"Image data cannot exceed {MaxImageBytes} bytes.", nameof(imageBytes));
        }

        using var stream = new MemoryStream(imageBytes, writable: false);
        using var source = DecodeImage(stream);
        ValidateImageBounds(source);
        using var bitmap = new Bitmap(source);
        Execute("set image", () => Clipboard.SetImage(bitmap));
    }

    public void SetFile(string filePath)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(filePath);
        var fullPath = ValidateFilePath(filePath);
        var filePaths = new StringCollection { fullPath };
        Execute("set file drop", () => Clipboard.SetFileDropList(filePaths));
    }

    public void CopyCommand() => throw new NotSupportedException(
        "The diagnostic clipboard backend does not synthesize UI copy commands.");

    public void CutCommand() => throw new NotSupportedException(
        "The diagnostic clipboard backend does not synthesize UI cut commands.");

    public void PasteCommand() => throw new NotSupportedException(
        "The diagnostic clipboard backend does not synthesize UI paste commands.");

    public string ReadText()
    {
        return Execute("read text", () => Clipboard.ContainsText() ? Clipboard.GetText() : string.Empty);
    }

    public bool HasMixedContent()
    {
        return Execute("detect mixed content", () =>
        {
            var data = Clipboard.GetDataObject();
            if (data is null) return false;

            var hasText = data.GetDataPresent(DataFormats.UnicodeText, autoConvert: true)
                || data.GetDataPresent(DataFormats.Text, autoConvert: true);
            var hasImage = data.GetDataPresent(DataFormats.Bitmap, autoConvert: true)
                || data.GetDataPresent(DataFormats.Dib, autoConvert: true);
            return hasText && hasImage;
        });
    }

    private static Image DecodeImage(Stream stream)
    {
        try
        {
            return Image.FromStream(stream, useEmbeddedColorManagement: false, validateImageData: true);
        }
        catch (ArgumentException exception)
        {
            throw new ArgumentException("Image data is not a supported image format.", nameof(stream), exception);
        }
        catch (OutOfMemoryException exception)
        {
            throw new ArgumentException("Image data is not a supported image format.", nameof(stream), exception);
        }
    }

    private static void ValidateImageBounds(Image image)
    {
        if (image.Width <= 0 || image.Height <= 0
            || image.Width > MaxImageDimension
            || image.Height > MaxImageDimension
            || (long)image.Width * image.Height > MaxImagePixels)
        {
            throw new ArgumentException("Image dimensions exceed the diagnostic clipboard limit.", nameof(image));
        }
    }

    private static string ValidateFilePath(string filePath)
    {
        string fullPath;
        try
        {
            fullPath = Path.GetFullPath(filePath);
        }
        catch (ArgumentException exception)
        {
            throw new ArgumentException("File path is invalid.", nameof(filePath), exception);
        }
        catch (NotSupportedException exception)
        {
            throw new ArgumentException("File path is invalid.", nameof(filePath), exception);
        }

        if (!File.Exists(fullPath))
        {
            throw new FileNotFoundException("The clipboard file-drop path must identify an existing file.", fullPath);
        }

        return fullPath;
    }

    private static TResult Execute<TResult>(string operation, Func<TResult> action)
    {
        EnsureSta();
        try
        {
            return action();
        }
        catch (ExternalException exception)
        {
            throw new InvalidOperationException($"Windows clipboard operation '{operation}' failed.", exception);
        }
        catch (ThreadStateException exception)
        {
            throw new InvalidOperationException($"Windows clipboard operation '{operation}' failed.", exception);
        }
    }

    private static void Execute(string operation, Action action)
    {
        Execute(operation, () =>
        {
            action();
            return true;
        });
    }

    private static void EnsureSta()
    {
        if (Thread.CurrentThread.GetApartmentState() != ApartmentState.STA)
        {
            throw new InvalidOperationException("Windows clipboard operations require an STA thread.");
        }
    }
}

public sealed class SyntheticClipboardBackend : IClipboardBackend
{
    private string text = string.Empty;

    public byte[]? ImageBytes { get; private set; }

    public string? ImageSource { get; private set; }

    public string? FilePath { get; private set; }

    public int CopyCommandCount { get; private set; }

    public int CutCommandCount { get; private set; }

    public int PasteCommandCount { get; private set; }

    public bool HasImage => ImageBytes is not null;

    public void SetText(string value)
    {
        text = value;
        ImageBytes = null;
        ImageSource = null;
        FilePath = null;
    }

    public void SetImage(byte[] imageBytes, string? imageSource)
    {
        text = string.Empty;
        ImageBytes = (byte[])imageBytes.Clone();
        ImageSource = imageSource;
        FilePath = null;
    }

    public void SetFile(string filePath)
    {
        text = string.Empty;
        ImageBytes = null;
        ImageSource = null;
        FilePath = filePath;
    }

    public void SeedMixedContent(string value, byte[] imageBytes, string? imageSource)
    {
        text = value;
        ImageBytes = (byte[])imageBytes.Clone();
        ImageSource = imageSource;
        FilePath = null;
    }

    public void CopyCommand() => CopyCommandCount++;

    public void CutCommand() => CutCommandCount++;

    public void PasteCommand() => PasteCommandCount++;

    public string ReadText() => text;
}
