# Quick fix - Downloads and runs the tool directly without any caching issues

Write-Host "NERDY NEIGHBOR TOOL - Direct Download" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

# Create temp directory
$tempPath = Join-Path $env:TEMP "NNTool_Direct_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $tempPath -Force | Out-Null
Set-Location $tempPath

Write-Host "Working directory: $tempPath" -ForegroundColor Gray

# Create Modules subdirectory
New-Item -ItemType Directory -Path (Join-Path $tempPath "Modules") -Force | Out-Null

# Download files directly with simple approach
$files = @(
    @{Name = "NNTool-Main.ps1"; Path = "NNTool-Main.ps1"},
    @{Name = "Remove-Antivirus.ps1"; Path = "Modules/Remove-Antivirus.ps1"},
    @{Name = "Run-Malwarebytes.ps1"; Path = "Modules/Run-Malwarebytes.ps1"},
    @{Name = "Remove-RemoteTools.ps1"; Path = "Modules/Remove-RemoteTools.ps1"},
    @{Name = "Run-SystemRepair.ps1"; Path = "Modules/Run-SystemRepair.ps1"},
    @{Name = "Run-WindowsUpdate.ps1"; Path = "Modules/Run-WindowsUpdate.ps1"}
)

$baseUrl = "https://raw.githubusercontent.com/NerdyNeighbor/nntool/main"

Write-Host "`nDownloading components..." -ForegroundColor Yellow

foreach ($file in $files) {
    Write-Host "  $($file.Name)..." -NoNewline
    
    $url = "$baseUrl/$($file.Path)"
    $dest = Join-Path $tempPath $file.Path
    
    try {
        # Simple direct download
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($url, $dest)
        
        if (Test-Path $dest) {
            $size = (Get-Item $dest).Length
            Write-Host " OK ($size bytes)" -ForegroundColor Green
        } else {
            Write-Host " Failed" -ForegroundColor Red
        }
    } catch {
        Write-Host " Error: $_" -ForegroundColor Red
    }
}

Write-Host "`nStarting Nerdy Neighbor Tool..." -ForegroundColor Cyan

# Check if main file exists and run it
$mainFile = Join-Path $tempPath "NNTool-Main.ps1"
if (Test-Path $mainFile) {
    & $mainFile
} else {
    Write-Host "Main file not found. Check downloads above." -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}