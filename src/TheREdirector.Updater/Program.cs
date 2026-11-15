using System.Diagnostics;
using System.Runtime.InteropServices;
using TheREdirector.Core;

// Installs a downloaded update once The Redirector has closed, then starts it again.
// The Redirector runs this from a temp copy, so nothing in the app folder is in use.
const uint OkCancel = 1, Warning = 0x30, Information = 0x40;
const int ClickedOk = 1;

var options = new Dictionary<string, string>();
for (var i = 0; i + 1 < args.Length; i += 2) options[args[i]] = args[i + 1];
if (!options.TryGetValue("--pid", out var pid) || !options.TryGetValue("--zip", out var zip) ||
    !options.TryGetValue("--app", out var app) || !options.TryGetValue("--from", out var from))
{
    MessageBoxW(0, "Use Check for updates in The Redirector's tray menu to update it.", "The Redirector", Information);
    return 1;
}
var exe = Path.GetFullPath(Path.Combine(app, "TheREdirector.exe"));

try
{
    try
    {
        using var closing = Process.GetProcessById(int.Parse(pid));
        closing.WaitForExit(TimeSpan.FromMinutes(1));
    }
    catch (ArgumentException) { } // Already closed.
    while (IsRunning(exe))
        if (MessageBoxW(0, "Quit The Redirector to finish updating, then click OK.", "The Redirector update", OkCancel | Information) != ClickedOk)
            return 0;
    UpdateInstaller.Install(zip, app, from);
}
catch (Exception e)
{
    MessageBoxW(0, "The Redirector could not be updated.\n\n" + e.Message, "The Redirector update", Warning);
}

try { Process.Start(new ProcessStartInfo(exe) { UseShellExecute = true, WorkingDirectory = app }); }
catch (Exception e) { MessageBoxW(0, "The Redirector could not be started.\n\n" + e.Message, "The Redirector update", Warning); }
return 0;

static bool IsRunning(string exe)
{
    foreach (var process in Process.GetProcessesByName("TheREdirector"))
        using (process)
        {
            try
            {
                if (string.Equals(process.MainModule?.FileName, exe, StringComparison.OrdinalIgnoreCase)) return true;
            }
            catch (Exception e) when (e is InvalidOperationException or System.ComponentModel.Win32Exception) { } // Exited or not ours.
        }
    return false;
}

[DllImport("user32.dll", CharSet = CharSet.Unicode)]
static extern int MessageBoxW(nint owner, string text, string caption, uint type);
