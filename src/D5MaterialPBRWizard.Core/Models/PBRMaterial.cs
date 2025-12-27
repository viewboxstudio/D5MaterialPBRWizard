namespace D5MaterialPBRWizard.Core.Models;

public class PBRMaterial
{
    public string Name { get; set; }
    public MaterialGroup Group { get; set; }
    public bool IsGenerated { get; set; }
    public string GeneratedPath { get; set; }
    public DateTime CreatedAt { get; set; }
    public string ErrorMessage { get; set; }

    public PBRMaterial(MaterialGroup group)
    {
        Group = group;
        Name = group.BaseName;
        IsGenerated = false;
        CreatedAt = DateTime.Now;
    }

    public bool HasError => !string.IsNullOrEmpty(ErrorMessage);
}
