# Simple test to run just the debug Malwarebytes module
Write-Host "Testing Malwarebytes Debug Module..." -ForegroundColor Cyan
Write-Host "Current location: $(Get-Location)" -ForegroundColor Gray

$debugScript = ".\Modules\Run-Malwarebytes-Debug.ps1"
if (Test-Path $debugScript) {
    Write-Host "Found debug script, running..." -ForegroundColor Green
    & $debugScript
} else {
    Write-Host "Debug script not found at: $debugScript" -ForegroundColor Red
    Write-Host "Available files:" -ForegroundColor Yellow
    Get-ChildItem -Recurse | ForEach-Object { Write-Host "  $($_.FullName)" -ForegroundColor Gray }
}

Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")