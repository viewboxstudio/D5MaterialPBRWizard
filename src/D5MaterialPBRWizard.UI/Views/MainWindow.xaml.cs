using System.Windows;
using D5MaterialPBRWizard.Core.Services;
using D5MaterialPBRWizard.Core.Models;
using D5MaterialPBRWizard.Core.Utilities;

namespace D5MaterialPBRWizard.UI.Views;

public partial class MainWindow : Window
{
    private TextureScanner _scanner;
    private MaterialGenerator _generator;
    private List<MaterialGroup> _materialGroups;
    private string _selectedFolder;

    public MainWindow()
    {
        InitializeComponent();
        Logger.Initialize(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Logs"));
        _scanner = new TextureScanner();
        _generator = new MaterialGenerator();
        _materialGroups = new List<MaterialGroup>();
    }

    private void SelectFolder_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new System.Windows.Forms.FolderBrowserDialog();
        if (dialog.ShowDialog() == System.Windows.Forms.DialogResult.OK)
        {
            _selectedFolder = dialog.SelectedPath;
            FolderPathText.Text = _selectedFolder;
        }
    }

    private async void ScanFolder_Click(object sender, RoutedEventArgs e)
    {
        if (string.IsNullOrEmpty(_selectedFolder))
        {
            MessageBox.Show("Selecciona una carpeta primero");
            return;
        }

        MaterialsListView.Items.Clear();
        _materialGroups = await _scanner.ScanFolderAsync(_selectedFolder);
        MaterialCountText.Text = $" ({_materialGroups.Count})";

        foreach (var group in _materialGroups)
            MaterialsListView.Items.Add(group);

        MessageBox.Show($"Encontrados {_materialGroups.Count} materiales");
    }

    private async void GenerateMaterials_Click(object sender, RoutedEventArgs e)
    {
        if (_materialGroups == null || _materialGroups.Count == 0)
        {
            MessageBox.Show("Escanea una carpeta primero");
            return;
        }

        _generator.OutputDirectory = Path.Combine(_selectedFolder, "D5_Materials_Output");
        var materials = await _generator.GenerateMaterialsAsync(_materialGroups);
        
        MessageBox.Show($"Generados {materials.Count(m => m.IsGenerated)} materiales\n\nEn: {_generator.OutputDirectory}");
        System.Diagnostics.Process.Start("explorer.exe", _generator.OutputDirectory);
    }
}
