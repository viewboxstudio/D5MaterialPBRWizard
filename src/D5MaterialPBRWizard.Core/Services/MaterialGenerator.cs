using D5MaterialPBRWizard.Core.Models;
using D5MaterialPBRWizard.Core.Utilities;
using System.Text.Json;

namespace D5MaterialPBRWizard.Core.Services;

public class MaterialGenerator
{
    public string OutputDirectory { get; set; }

    public async Task<List<PBRMaterial>> GenerateMaterialsAsync(List<MaterialGroup> materialGroups)
    {
        var results = new List<PBRMaterial>();

        foreach (var group in materialGroups)
        {
            var material = new PBRMaterial(group);
            
            try
            {
                var outputDir = OutputDirectory ?? "Output";
                Directory.CreateDirectory(outputDir);
                
                var outputPath = Path.Combine(outputDir, $"{group.BaseName}.json");
                
                var materialData = new
                {
                    Name = group.BaseName,
                    IsComplete = group.IsComplete,
                    Maps = group.Maps.ToDictionary(kvp => kvp.Key.ToString(), kvp => kvp.Value.FilePath),
                    MissingMaps = group.MissingMaps,
                    CreatedAt = DateTime.Now
                };

                var json = JsonSerializer.Serialize(materialData, new JsonSerializerOptions { WriteIndented = true });
                File.WriteAllText(outputPath, json);

                material.IsGenerated = true;
                material.GeneratedPath = outputPath;
                
                Logger.Info($"Generado: {group.BaseName}");
            }
            catch (Exception ex)
            {
                material.ErrorMessage = ex.Message;
                Logger.Error($"Error: {ex.Message}");
            }

            results.Add(material);
        }

        return results;
    }
}
