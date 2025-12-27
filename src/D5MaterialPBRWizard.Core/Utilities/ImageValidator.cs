namespace D5MaterialPBRWizard.Core.Utilities;

public class ImageValidator
{
    private static readonly string[] SupportedExtensions = { ".jpg", ".jpeg", ".png", ".tga", ".bmp", ".tif", ".tiff" };

    public static bool IsValidImageFile(string filePath)
    {
        if (!File.Exists(filePath)) return false;
        var ext = Path.GetExtension(filePath).ToLower();
        return SupportedExtensions.Contains(ext);
    }

    public static (int width, int height) GetImageDimensions(string filePath)
    {
        try
        {
            using var image = System.Drawing.Image.FromFile(filePath);
            return (image.Width, image.Height);
        }
        catch { return (0, 0); }
    }
}
