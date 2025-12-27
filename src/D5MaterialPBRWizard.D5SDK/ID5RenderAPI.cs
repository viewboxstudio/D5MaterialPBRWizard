namespace D5MaterialPBRWizard.D5SDK;

public interface ID5RenderAPI
{
    bool IsConnected();
    Task<bool> TestConnectionAsync();
}

public class MockD5RenderSDK : ID5RenderAPI
{
    public bool IsConnected() => false;
    public async Task<bool> TestConnectionAsync() { await Task.Delay(100); return false; }
}
