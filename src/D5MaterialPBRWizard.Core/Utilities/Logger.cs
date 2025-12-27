namespace D5MaterialPBRWizard.Core.Utilities;

public class Logger
{
    private static string _logPath;
    private static readonly object _lock = new object();

    public static void Initialize(string directory)
    {
        if (!Directory.Exists(directory))
            Directory.CreateDirectory(directory);
        
        _logPath = Path.Combine(directory, $"log_{DateTime.Now:yyyyMMdd_HHmmss}.txt");
    }

    public static void Info(string message) => Log(message, "INFO");
    public static void Warning(string message) => Log(message, "WARN");
    public static void Error(string message) => Log(message, "ERROR");

    private static void Log(string message, string level)
    {
        lock (_lock)
        {
            var entry = $"[{DateTime.Now:HH:mm:ss}] [{level}] {message}";
            Console.WriteLine(entry);
            
            if (_logPath != null)
            {
                try { File.AppendAllText(_logPath, entry + Environment.NewLine); }
                catch { }
            }
        }
    }
}
