using System.Text.RegularExpressions;
using D5MaterialPBRWizard.Core.Models;

namespace D5MaterialPBRWizard.Core.Utilities;

public class TextureNameParser
{
    public static (string baseName, TextureType type) ParseFileName(string fileName)
    {
        var name = Path.GetFileNameWithoutExtension(fileName).ToLower();
        var type = TextureType.Unknown;
        
        if (name.Contains("albedo") || name.Contains("basecolor") || name.Contains("diffuse"))
            type = TextureType.Albedo;
        else if (name.Contains("normal"))
            type = TextureType.Normal;
        else if (name.Contains("roughness") || name.Contains("rough"))
            type = TextureType.Roughness;
        else if (name.Contains("metallic") || name.Contains("metal"))
            type = TextureType.Metallic;
        else if (name.Contains("_ao") || name.Contains("ambient"))
            type = TextureType.AO;
        else if (name.Contains("height") || name.Contains("displacement"))
            type = TextureType.Height;
        
        var pattern = @"_(albedo|basecolor|diffuse|normal|roughness|metallic|ao|height|displacement|rough|metal)";
        var baseName = Regex.Replace(name, pattern, "", RegexOptions.IgnoreCase).Trim('_', '-', ' ');
        
        if (!string.IsNullOrEmpty(baseName))
            baseName = char.ToUpper(baseName[0]) + baseName.Substring(1);
        
        return (baseName, type);
    }
}
