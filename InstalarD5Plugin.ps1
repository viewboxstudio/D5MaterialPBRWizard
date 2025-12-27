# =====================================================
# D5 MATERIAL PBR WIZARD - INSTALADOR AUTOMÁTICO
# Para: viewboxstudio
# Versión: 1.0
# =====================================================

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

# ============================================
# CONFIGURACIÓN - TU URL DE GITHUB
# ============================================
$REPO_URL = "https://github.com/viewboxstudio/D5MaterialPBRWizard/archive/refs/heads/main.zip"
$VERSION = "1.0.0"
$PLUGIN_NAME = "D5 Material PBR Wizard"

# ============================================
# FUNCIONES
# ============================================

function Write-Header {
    Clear-Host
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                              ║" -ForegroundColor Cyan
    Write-Host "║       $PLUGIN_NAME - INSTALADOR AUTOMÁTICO       ║" -ForegroundColor Cyan
    Write-Host "║                    Versión $VERSION                          ║" -ForegroundColor Cyan
    Write-Host "║                                                              ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Text, [int]$Current, [int]$Total)
    Write-Host ""
    Write-Host "[$Current/$Total] $Text" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Text)
    Write-Host "  ✓ $Text" -ForegroundColor Green
}

function Write-Error {
    param([string]$Text)
    Write-Host "  ✗ $Text" -ForegroundColor Red
}

function Write-Info {
    param([string]$Text)
    Write-Host "  ℹ $Text" -ForegroundColor Cyan
}

function Download-FileWithProgress {
    param([string]$Url, [string]$OutputPath)
    
    try {
        Write-Info "Descargando desde GitHub..."
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($Url, $OutputPath)
        Write-Success "Descargado correctamente"
        return $true
    }
    catch {
        Write-Error "Error descargando: $($_.Exception.Message)"
        return $false
    }
}

function Test-DotNetInstalled {
    try {
        $output = & dotnet --list-sdks 2>&1 | Out-String
        if ($output -match "6\.0\.\d+") {
            $version = ($output | Select-String "6\.0\.\d+").Matches[0].Value
            Write-Success ".NET 6.0 SDK ya instalado (versión $version)"
            return $true
        }
    }
    catch { }
    
    Write-Info ".NET 6.0 SDK no encontrado"
    return $false
}

function Install-DotNet {
    Write-Info "Descargando .NET 6.0 SDK..."
    
    $dotnetUrl = "https://download.visualstudio.microsoft.com/download/pr/b395fa18-c53b-4f7f-bf91-6b2d3c43fedb/d83a318111da9e15f5ecebfd2d190e89/dotnet-sdk-6.0.427-win-x64.exe"
    $installerPath = "$env:TEMP\dotnet-sdk-installer.exe"
    
    if (Download-FileWithProgress -Url $dotnetUrl -OutputPath $installerPath) {
        Write-Info "Instalando .NET 6.0 SDK (puede tardar unos minutos)..."
        
        $process = Start-Process -FilePath $installerPath -ArgumentList "/install /quiet /norestart" -Wait -PassThru
        
        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            Write-Success ".NET 6.0 SDK instalado correctamente"
            return $true
        }
        
        Write-Error "Error instalando .NET 6.0"
    }
    
    return $false
}

function Find-D5Installation {
    Write-Info "Buscando D5 Render..."
    
    $paths = @(
        "C:\Program Files\D5 Render",
        "C:\Program Files (x86)\D5 Render",
        "C:\Program Files\D5Render",
        "C:\Program Files (x86)\D5Render"
    )
    
    foreach ($path in $paths) {
        if (Test-Path "$path\D5Render.exe") {
            Write-Success "D5 Render encontrado: $path"
            return $path
        }
    }
    
    # Buscar en Steam
    try {
        $steamPath = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Wow6432Node\Valve\Steam" -Name "InstallPath" -ErrorAction SilentlyContinue
        if ($steamPath) {
            $d5Steam = Join-Path $steamPath "steamapps\common\D5 Render"
            if (Test-Path "$d5Steam\D5Render.exe") {
                Write-Success "D5 Render encontrado (Steam): $d5Steam"
                return $d5Steam
            }
        }
    }
    catch { }
    
    return $null
}

function Build-Project {
    param([string]$SourcePath)
    
    Write-Info "Compilando proyecto..."
    
    $slnFile = Get-ChildItem -Path $SourcePath -Filter "*.sln" -Recurse | Select-Object -First 1
    
    if (!$slnFile) {
        Write-Error "No se encontró archivo .sln"
        return $null
    }
    
    $outputPath = Join-Path $SourcePath "publish"
    
    try {
        Write-Info "Restaurando dependencias..."
        & dotnet restore $slnFile.FullName 2>&1 | Out-Null
        
        $uiProject = Get-ChildItem -Path $SourcePath -Filter "*UI.csproj" -Recurse | Select-Object -First 1
        
        if (!$uiProject) {
            Write-Error "No se encontró proyecto UI"
            return $null
        }
        
        Write-Info "Compilando (puede tardar 2-3 minutos)..."
        & dotnet publish $uiProject.FullName `
            --configuration Release `
            --runtime win-x64 `
            --self-contained true `
            --output $outputPath `
            /p:PublishSingleFile=false 2>&1 | Out-Null
        
        if (Test-Path "$outputPath\MaterialPBRWizard.exe") {
            Write-Success "Proyecto compilado exitosamente"
            return $outputPath
        }
        
        Write-Error "No se encontró el ejecutable"
        return $null
    }
    catch {
        Write-Error "Error compilando: $($_.Exception.Message)"
        return $null
    }
}

function Install-Plugin {
    param([string]$CompiledPath, [string]$D5Path)
    
    $pluginsFolder = Join-Path $D5Path "Plugins"
    $pluginFolder = Join-Path $pluginsFolder "MaterialPBRWizard"
    
    if (!(Test-Path $pluginsFolder)) {
        New-Item -ItemType Directory -Path $pluginsFolder -Force | Out-Null
        Write-Success "Carpeta Plugins creada"
    }
    
    if (Test-Path $pluginFolder) {
        $backupPath = "$pluginFolder.backup_" + (Get-Date -Format "yyyyMMdd_HHmmss")
        Write-Info "Respaldando instalación previa..."
        Move-Item -Path $pluginFolder -Destination $backupPath -Force
        Write-Success "Backup creado"
    }
    
    New-Item -ItemType Directory -Path $pluginFolder -Force | Out-Null
    
    Write-Info "Copiando archivos..."
    Copy-Item -Path "$CompiledPath\*" -Destination $pluginFolder -Recurse -Force
    
    @("Config", "Logs", "Output") | ForEach-Object {
        $folder = Join-Path $pluginFolder $_
        if (!(Test-Path $folder)) {
            New-Item -ItemType Directory -Path $folder -Force | Out-Null
        }
    }
    
    Write-Success "Plugin instalado en: $pluginFolder"
    return $pluginFolder
}

function New-DesktopShortcut {
    param([string]$TargetPath)
    
    try {
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $shortcutPath = Join-Path $desktopPath "$PLUGIN_NAME.lnk"
        
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($shortcutPath)
        $Shortcut.TargetPath = $TargetPath
        $Shortcut.WorkingDirectory = Split-Path $TargetPath
        $Shortcut.Description = $PLUGIN_NAME
        $Shortcut.Save()
        
        Write-Success "Acceso directo creado"
        return $true
    }
    catch {
        Write-Info "No se pudo crear acceso directo"
        return $false
    }
}

# ============================================
# PROGRAMA PRINCIPAL
# ============================================

try {
    Write-Header
    
    Write-Info "Este instalador va a:"
    Write-Info "  1. Verificar/Instalar .NET 6.0 SDK"
    Write-Info "  2. Descargar el código de GitHub"
    Write-Info "  3. Compilar el proyecto"
    Write-Info "  4. Buscar D5 Render"
    Write-Info "  5. Instalar el plugin"
    Write-Info "  6. Crear acceso directo"
    Write-Host ""
    
    $continue = Read-Host "¿Deseas continuar? (S/N)"
    if ($continue -ne "S" -and $continue -ne "s") {
        Write-Info "Instalación cancelada"
        exit 0
    }
    
    # PASO 1: .NET
    Write-Step "Verificando .NET 6.0 SDK" 1 6
    
    if (!(Test-DotNetInstalled)) {
        if (!(Install-DotNet)) {
            throw "No se pudo instalar .NET 6.0"
        }
    }
    
    # PASO 2: Descargar
    Write-Step "Descargando código desde GitHub" 2 6
    
    $tempPath = Join-Path $env:TEMP "D5PBRWizard_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -ItemType Directory -Path $tempPath -Force | Out-Null
    
    $zipPath = Join-Path $tempPath "source.zip"
    
    if (!(Download-FileWithProgress -Url $REPO_URL -OutputPath $zipPath)) {
        throw "No se pudo descargar el código"
    }
    
    Write-Info "Extrayendo archivos..."
    $extractPath = Join-Path $tempPath "source"
    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
    
    $sourcePath = (Get-ChildItem -Path $extractPath -Directory | Select-Object -First 1).FullName
    Write-Success "Código extraído"
    
    # PASO 3: Compilar
    Write-Step "Compilando proyecto" 3 6
    
    $compiledPath = Build-Project -SourcePath $sourcePath
    if (!$compiledPath) {
        throw "Error compilando"
    }
    
    # PASO 4: Buscar D5
    Write-Step "Buscando D5 Render" 4 6
    
    $d5Path = Find-D5Installation
    
    if (!$d5Path) {
        Write-Info "Selecciona manualmente la carpeta de D5 Render"
        Add-Type -AssemblyName System.Windows.Forms
        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderBrowser.Description = "Selecciona la carpeta de D5 Render"
        
        if ($folderBrowser.ShowDialog() -eq "OK") {
            $d5Path = $folderBrowser.SelectedPath
            if (!(Test-Path "$d5Path\D5Render.exe")) {
                throw "La carpeta no contiene D5Render.exe"
            }
        }
        else {
            throw "Debes seleccionar la carpeta de D5 Render"
        }
    }
    
    # PASO 5: Instalar
    Write-Step "Instalando plugin" 5 6
    
    $pluginPath = Install-Plugin -CompiledPath $compiledPath -D5Path $d5Path
    
    # PASO 6: Acceso directo
    Write-Step "Creando acceso directo" 6 6
    
    $exePath = Join-Path $pluginPath "MaterialPBRWizard.exe"
    New-DesktopShortcut -TargetPath $exePath
    
    # Limpiar
    Remove-Item $tempPath -Recurse -Force -ErrorAction SilentlyContinue
    
    # ÉXITO
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                                                              ║" -ForegroundColor Green
    Write-Host "║            ✓ INSTALACIÓN COMPLETADA EXITOSAMENTE             ║" -ForegroundColor Green
    Write-Host "║                                                              ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Success "Plugin instalado en:"
    Write-Host "  $pluginPath" -ForegroundColor Cyan
    Write-Host ""
    Write-Success "Ejecutable:"
    Write-Host "  $exePath" -ForegroundColor Cyan
    Write-Host ""
    
    $execute = Read-Host "¿Deseas abrir el plugin ahora? (S/N)"
    if ($execute -eq "S" -or $execute -eq "s") {
        Start-Process $exePath
    }
    
} catch {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║                                                              ║" -ForegroundColor Red
    Write-Host "║                  ✗ ERROR EN LA INSTALACIÓN                  ║" -ForegroundColor Red
    Write-Host "║                                                              ║" -ForegroundColor Red
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""
    Write-Error $_.Exception.Message
    Write-Host ""
}

Write-Host ""
Write-Host "Presiona cualquier tecla para salir..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
