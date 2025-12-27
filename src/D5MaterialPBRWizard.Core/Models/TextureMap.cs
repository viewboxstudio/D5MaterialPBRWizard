namespace D5MaterialPBRWizard.Core.Models;

public class TextureMap
{
    public string FilePath { get; set; }
    public string FileName { get; set; }
    public TextureType Type { get; set; }
    public int Width { get; set; }
    public int Height { get; set; }
    public long FileSize { get; set; }
    public bool IsValid { get; set; }

    public TextureMap(string filePath)
    {
        FilePath = filePath;
        FileName = Path.GetFileName(filePath);
        Type = TextureType.Unknown;
        IsValid = File.Exists(filePath);
    }
}
