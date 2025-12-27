using D5MaterialPBRWizard.Core.Models;
using D5MaterialPBRWizard.Core.Utilities;

namespace D5MaterialPBRWizard.Core.Services;

public class TextureScanner
{
    public async Task<List<MaterialGroup>> ScanFolderAsync(string folderPath)
    {
        Logger.Info($"Escaneando: {folderPath}");
        
        var textureMaps = new List<TextureMap>();
        var files = Directory.GetFiles(folderPath, "*.*", SearchOption.TopDirectoryOnly)
                             .Where(f => ImageValidator.IsValidImageFile(f));

        foreach (var file in files)
        {
            var map = new TextureMap(file);
            var (baseName, type) = TextureNameParser.ParseFileName(map.FileName);
            map.Type = type;
            
            var (width, height) = ImageValidator.GetImageDimensions(file);
            map.Width = width;
            map.Height = height;
            
            textureMaps.Add(map);
        }

        var groups = new Dictionary<string, MaterialGroup>();
        
        foreach (var map in textureMaps)
        {
            var (baseName, _) = TextureNameParser.ParseFileName(map.FileName);
            
            if (!groups.ContainsKey(baseName))
                groups[baseName] = new MaterialGroup(baseName);
            
            groups[baseName].AddMap(map);
        }

        Logger.Info($"Encontrados {groups.Count} materiales");
        return groups.Values.ToList();
    }
}
