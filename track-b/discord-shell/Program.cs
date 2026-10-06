using System;
using System.Windows.Forms;

namespace KoroneDiscordShell;

internal static class Program
{
    [STAThread]
    private static void Main(string[] args)
    {
        ApplicationConfiguration.Initialize();
        var diagnosticBlank = args.Length == 1 && string.Equals(args[0], "--diagnostic-blank", StringComparison.Ordinal);
        Application.Run(new MainForm(diagnosticBlank));
    }
}
