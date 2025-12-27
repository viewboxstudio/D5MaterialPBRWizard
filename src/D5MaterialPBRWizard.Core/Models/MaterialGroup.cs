namespace D5MaterialPBRWizard.Core.Models;

public class MaterialGroup
{
    public string BaseName { get; set; }
    public Dictionary<TextureType, TextureMap> Maps { get; set; }
    public bool IsComplete { get; set; }
    public List<string> MissingMaps { get; set; }

    public MaterialGroup(string baseName)
    {
        BaseName = baseName;
        Maps = new Dictionary<TextureType, TextureMap>();
        MissingMaps = new List<string>();
        UpdateCompleteness();
    }

    public void AddMap(TextureMap map)
    {
        if (map.Type != TextureType.Unknown && !Maps.ContainsKey(map.Type))
        {
            Maps[map.Type] = map;
            UpdateCompleteness();
        }
    }

    private void UpdateCompleteness()
    {
        MissingMaps.Clear();
        
        bool hasAlbedo = Maps.ContainsKey(TextureType.Albedo) || 
                        Maps.ContainsKey(TextureType.BaseColor) || 
                        Maps.ContainsKey(TextureType.Color);
        
        if (!hasAlbedo) MissingMaps.Add("Albedo");
        if (!Maps.ContainsKey(TextureType.Normal)) MissingMaps.Add("Normal");

        IsComplete = MissingMaps.Count == 0;
    }

    public int MapCount => Maps.Count;
    public string StatusIcon => IsComplete ? "✔️" : "⚠️";
    public string StatusText => IsComplete ? "Completo" : $"Incompleto - Falta: {string.Join(", ", MissingMaps)}";
}
