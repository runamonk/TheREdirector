using Avalonia.Controls;
using Avalonia.Interactivity;

namespace TheREdirector;

public partial class SettingsWindow : Window
{
    // For the designer only.
    public SettingsWindow() => InitializeComponent();

    internal SettingsWindow(Settings settings) : this()
    {
        CloseEdge.IsChecked = settings.CloseEdge;
        AskAfterCloses.Value = settings.AskAfterCloses;
        AskWithinMinutes.Value = settings.AskWithinMinutes;
        Closed += (_, _) =>
        {
            settings.CloseEdge = CloseEdge.IsChecked == true;
            settings.AskAfterCloses = (int)(AskAfterCloses.Value ?? settings.AskAfterCloses);
            settings.AskWithinMinutes = (int)(AskWithinMinutes.Value ?? settings.AskWithinMinutes);
            settings.Save();
        };
    }

    private void CloseClicked(object? sender, RoutedEventArgs e) => Close();
}
