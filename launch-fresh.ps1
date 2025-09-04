# Fresh Launcher - Forces no caching at all levels
# This ensures you always get the latest version

# Force TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Clear PowerShell's web request cache completely
[System.Net.WebRequest]::DefaultCachePolicy = New-Object System.Net.Cache.RequestCachePolicy([System.Net.Cache.RequestCacheLevel]::NoCacheNoStore)

# Add cache-busting headers and random parameter
$headers = @{
    'Cache-Control' = 'no-cache, no-store, must-revalidate'
    'Pragma' = 'no-cache'
    'Expires' = '0'
}

$cacheBuster = [System.Guid]::NewGuid().ToString()
$freshUrl = "https://raw.githubusercontent.com/NerdyNeighbor/nntool/main/NNTool-Launcher.ps1?nocache=$cacheBuster&t=$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"

Write-Host "Forcing fresh download with no caching..." -ForegroundColor Yellow
Write-Host "URL: $freshUrl" -ForegroundColor Gray

try {
    $response = Invoke-WebRequest -Uri $freshUrl -Headers $headers -UseBasicParsing
    
    # Verify we got the updated version by checking for our verification code
    if ($response.Content -like "*cache buster*" -and $response.Content -like "*file sizes*") {
        Write-Host "✓ Got fresh launcher with verification features" -ForegroundColor Green
    } else {
        Write-Host "⚠ Still getting cached version" -ForegroundColor Yellow
    }
    
    # Execute the fresh launcher
    Invoke-Expression $response.Content
    
} catch {
    Write-Host "Error downloading fresh launcher: $_" -ForegroundColor Red
    Write-Host "Falling back to direct GitHub URL..." -ForegroundColor Yellow
    
    # Fallback with different cache busting approach
    $fallbackUrl = "https://raw.githubusercontent.com/NerdyNeighbor/nntool/main/NNTool-Launcher.ps1"
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("Cache-Control", "no-cache")
    $webClient.Headers.Add("Pragma", "no-cache")
    $webClient.CachePolicy = New-Object System.Net.Cache.RequestCachePolicy([System.Net.Cache.RequestCacheLevel]::NoCacheNoStore)
    
    $content = $webClient.DownloadString($fallbackUrl)
    Invoke-Expression $content
}