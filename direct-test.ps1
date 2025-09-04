# Direct test for Malwarebytes Debug Module
# This bypasses the launcher completely

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "=== DIRECT MALWAREBYTES DEBUG TEST ===" -ForegroundColor Cyan

# Create temp directory
$testPath = Join-Path $env:TEMP "MBAM_Debug_Test_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $testPath -Force | Out-Null
Write-Host "Test directory: $testPath" -ForegroundColor Gray

# Download the debug module directly
$url = "https://raw.githubusercontent.com/NerdyNeighbor/nntool/main/Modules/Run-Malwarebytes-Debug.ps1"
$destination = Join-Path $testPath "Run-Malwarebytes-Debug.ps1"

Write-Host "Downloading debug module..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri $url -OutFile $destination -UseBasicParsing
    
    if (Test-Path $destination) {
        Write-Host "Download successful!" -ForegroundColor Green
        Write-Host "File size: $((Get-Item $destination).Length) bytes" -ForegroundColor Gray
        
        # Change to test directory and run
        Push-Location $testPath
        
        Write-Host "`nRunning debug module..." -ForegroundColor Yellow
        & $destination
        
        Pop-Location
    } else {
        Write-Host "Download failed - file not created" -ForegroundColor Red
    }
} catch {
    Write-Host "Download error: $_" -ForegroundColor Red
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")