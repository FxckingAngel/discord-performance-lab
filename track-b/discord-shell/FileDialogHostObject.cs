using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text.Json;
using System.Windows.Forms;

namespace KoroneDiscordShell;

[ComVisible(true)]
[ClassInterface(ClassInterfaceType.AutoDual)]
public sealed class FileDialogHostObject
{
    public void ShowItemInFolder(string path)
    {
        if (string.IsNullOrWhiteSpace(path)) throw new ArgumentException("A file path is required.", nameof(path));
        var fullPath = Path.GetFullPath(path);
        if (!File.Exists(fullPath) && !Directory.Exists(fullPath)) throw new FileNotFoundException("The requested item does not exist.", fullPath);

        var startInfo = new ProcessStartInfo
        {
            FileName = "explorer.exe",
            UseShellExecute = true,
        };
        startInfo.ArgumentList.Add($"/select,{fullPath}");
        Process.Start(startInfo);
    }

    public string ShowOpenDialog(string optionsJson)
    {
        ArgumentNullException.ThrowIfNull(optionsJson);
        using var document = JsonDocument.Parse(optionsJson);
        var root = document.RootElement;
        var properties = ReadProperties(root);
        var filters = ReadFilters(root);

        using var dialog = new OpenFileDialog
        {
            Multiselect = properties.Contains("multiSelections", StringComparer.Ordinal),
            Filter = filters,
            CheckFileExists = true,
            CheckPathExists = true,
        };

        var result = dialog.ShowDialog();
        return JsonSerializer.Serialize(new
        {
            canceled = result != DialogResult.OK,
            filePaths = result == DialogResult.OK ? dialog.FileNames : Array.Empty<string>(),
        });
    }

    public string SaveWithDialog2(byte[] fileContents, string fileName, string? defaultDirectory, bool throwOnCancel = false)
    {
        ArgumentNullException.ThrowIfNull(fileContents);
        ValidateFileName(fileName);

        var directory = string.IsNullOrWhiteSpace(defaultDirectory)
            ? Environment.GetFolderPath(Environment.SpecialFolder.UserProfile) is { Length: > 0 } profile
                ? Path.Combine(profile, "Downloads")
                : throw new InvalidOperationException("The user's Downloads directory could not be resolved.")
            : Path.GetFullPath(defaultDirectory);
        if (!Directory.Exists(directory)) throw new DirectoryNotFoundException("The default save directory does not exist.");

        using var dialog = new SaveFileDialog
        {
            InitialDirectory = directory,
            FileName = fileName,
            AddExtension = false,
            OverwritePrompt = true,
            CheckPathExists = true,
            Filter = BuildSaveFilter(fileName),
        };

        var result = dialog.ShowDialog();
        if (result != DialogResult.OK || string.IsNullOrWhiteSpace(dialog.FileName))
        {
            if (throwOnCancel) throw new OperationCanceledException("Save dialog was canceled by user.");
            return JsonSerializer.Serialize(new { canceledByUser = true, filePath = string.Empty, directory = string.Empty });
        }

        var selectedPath = Path.GetFullPath(dialog.FileName);
        File.WriteAllBytes(selectedPath, fileContents);
        return JsonSerializer.Serialize(new
        {
            canceledByUser = false,
            filePath = selectedPath,
            directory = Path.GetDirectoryName(selectedPath) ?? string.Empty,
        });
    }

    private static void ValidateFileName(string fileName)
    {
        if (string.IsNullOrWhiteSpace(fileName) || fileName != Path.GetFileName(fileName) || fileName is "." or "..")
        {
            throw new ArgumentException("fileName must be a file name, not a path.", nameof(fileName));
        }

        if (fileName.Any(character => Path.GetInvalidFileNameChars().Contains(character)))
        {
            throw new ArgumentException("fileName has invalid characters.", nameof(fileName));
        }
    }

    private static string BuildSaveFilter(string fileName)
    {
        var extension = Path.GetExtension(fileName).TrimStart('.');
        return string.IsNullOrWhiteSpace(extension) || extension == "."
            ? "All (*.*)|*.*"
            : $"{extension}|*.{extension}|All|*.*";
    }

    private static HashSet<string> ReadProperties(JsonElement root)
    {
        var result = new HashSet<string>(StringComparer.Ordinal);
        if (!root.TryGetProperty("properties", out var value)) return result;
        if (value.ValueKind != JsonValueKind.Array) throw new ArgumentException("properties must be an array.");

        foreach (var property in value.EnumerateArray())
        {
            if (property.ValueKind != JsonValueKind.String) throw new ArgumentException("properties must contain strings.");
            var name = property.GetString() ?? string.Empty;
            if (name is not "openFile" and not "multiSelections")
            {
                throw new NotSupportedException($"The isolated file-dialog harness does not implement '{name}'.");
            }

            result.Add(name);
        }

        return result;
    }

    private static string ReadFilters(JsonElement root)
    {
        if (!root.TryGetProperty("filters", out var value)) return "All files (*.*)|*.*";
        if (value.ValueKind != JsonValueKind.Array) throw new ArgumentException("filters must be an array.");

        var entries = new List<string>();
        foreach (var filter in value.EnumerateArray())
        {
            if (filter.ValueKind != JsonValueKind.Object
                || !filter.TryGetProperty("name", out var nameElement)
                || !filter.TryGetProperty("extensions", out var extensionsElement)
                || nameElement.ValueKind != JsonValueKind.String
                || extensionsElement.ValueKind != JsonValueKind.Array)
            {
                throw new ArgumentException("Each filter must contain a string name and an extensions array.");
            }

            var name = nameElement.GetString() ?? string.Empty;
            var extensions = extensionsElement.EnumerateArray()
                .Select(extension => extension.ValueKind == JsonValueKind.String ? extension.GetString() : null)
                .Where(extension => !string.IsNullOrWhiteSpace(extension))
                .Select(extension => extension!.Trim().TrimStart('.'))
                .Where(extension => extension == "*" || (extension.Length > 0 && extension.All(character => !"|;".Contains(character))))
                .ToArray();
            if (name.Length == 0 || extensions.Length == 0) throw new ArgumentException("Each filter needs a name and at least one valid extension.");
            entries.Add($"{name}|{string.Join(';', extensions.Select(extension => extension == "*" ? "*.*" : $"*.{extension}"))}");
        }

        return entries.Count == 0 ? "All files (*.*)|*.*" : string.Join('|', entries);
    }
}
