# Test ONLY the Malwarebytes download function with latest code

Write-Host "=== MALWAREBYTES DOWNLOAD TEST ===" -ForegroundColor Cyan
Write-Host ""

# Force download latest version with cache buster
$url = "https://raw.githubusercontent.com/NerdyNeighbor/nntool/main/Modules/Run-Malwarebytes.ps1?t=$((Get-Date).Ticks)"
$tempPath = Join-Path $env:TEMP "MbamDownloadTest_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $tempPath -Force | Out-Null

$modulePath = Join-Path $tempPath "Run-Malwarebytes.ps1"

Write-Host "Downloading latest module..." -ForegroundColor Yellow
try {
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("Cache-Control", "no-cache")
    $webClient.DownloadFile($url, $modulePath)
    
    $size = (Get-Item $modulePath).Length
    Write-Host "Downloaded: $size bytes" -ForegroundColor Green
    
    # Check if it contains multiple download sources
    $content = Get-Content $modulePath -Raw
    if ($content -like "*Official API*" -and $content -like "*Direct Link*") {
        Write-Host "✓ Contains updated download sources" -ForegroundColor Green
    } else {
        Write-Host "✗ Still old version without multiple sources" -ForegroundColor Red
    }
    
    Write-Host ""
} catch {
    Write-Host "Failed to download: $_" -ForegroundColor Red
    exit 1
}

# Now test just the download function by extracting it
Write-Host "Testing Malwarebytes download..." -ForegroundColor Cyan
Write-Host ""

# Set up logging function
function Write-NNLog {
    param([string]$Message, [string]$Level = "INFO")
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host "[$Level] $Message" -ForegroundColor $color
}

# Extract and run just the Install-Malwarebytes function
Set-Location $tempPath

Write-Host "Running download test..." -ForegroundColor Yellow
Write-Host "This will attempt to download from multiple sources:" -ForegroundColor Gray
Write-Host "1. Official API" -ForegroundColor Gray
Write-Host "2. Direct Link" -ForegroundColor Gray  
Write-Host "3. Alternative CDN" -ForegroundColor Gray
Write-Host ""

# Load the module and call the install function directly
. $modulePath

# Call the install function
$result = Install-Malwarebytes

if ($result) {
    Write-Host ""
    Write-Host "SUCCESS: Malwarebytes download/install completed!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "FAILED: All download attempts failed" -ForegroundColor Red
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")