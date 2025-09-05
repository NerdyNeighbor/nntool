# Direct test of Malwarebytes module to see what's actually happening

Write-Host "=== DIRECT MALWAREBYTES MODULE TEST ===" -ForegroundColor Cyan
Write-Host ""

# Check current directory
$currentDir = Get-Location
Write-Host "Current directory: $currentDir" -ForegroundColor Gray

# Look for the module
$modulePath = Join-Path $currentDir "Modules\Run-Malwarebytes.ps1"

if (Test-Path $modulePath) {
    Write-Host "Found module at: $modulePath" -ForegroundColor Green
    Write-Host "File size: $((Get-Item $modulePath).Length) bytes" -ForegroundColor Gray
    Write-Host ""
    
    # Check if it contains the fix
    $content = Get-Content $modulePath -Raw
    
    Write-Host "Checking module content..." -ForegroundColor Yellow
    
    if ($content -like "*exit 1*") {
        Write-Host "✗ Module contains 'exit 1' - this is the OLD broken version!" -ForegroundColor Red
        Write-Host "  The module will exit early without running the scan." -ForegroundColor Red
    } elseif ($content -like "*return*" -and $content -like "*Malwarebytes is already installed*") {
        Write-Host "✓ Module contains the fix (uses 'return' instead of 'exit 1')" -ForegroundColor Green
    } else {
        Write-Host "? Unable to determine module version" -ForegroundColor Yellow
    }
    
    # Show the critical lines
    Write-Host ""
    Write-Host "Critical section of the module:" -ForegroundColor Yellow
    $lines = $content -split "`n"
    $foundSection = $false
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -like "*Malwarebytes not found, installing*") {
            $foundSection = $true
            Write-Host "Line $($i+1): $($lines[$i])" -ForegroundColor Gray
            
            # Show next 10 lines
            for ($j = 1; $j -le 10; $j++) {
                if ($i + $j -lt $lines.Count) {
                    Write-Host "Line $($i+$j+1): $($lines[$i+$j])" -ForegroundColor Gray
                    
                    # Highlight the problematic line
                    if ($lines[$i+$j] -like "*exit*") {
                        Write-Host "  ^ THIS IS THE PROBLEM - 'exit' kills the entire script!" -ForegroundColor Red
                    }
                }
            }
            break
        }
    }
    
    Write-Host ""
    Write-Host "Now running the module to see what happens..." -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Gray
    
    # Run it and capture output
    & $modulePath
    
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host "Module execution completed" -ForegroundColor Cyan
    
} else {
    Write-Host "Module not found at: $modulePath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Available files:" -ForegroundColor Yellow
    Get-ChildItem -Recurse | ForEach-Object { 
        Write-Host "  $($_.FullName)" -ForegroundColor Gray 
    }
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")