# Debug Script - Only Antivirus Removal + Malwarebytes
# Tests just the first two modules to verify the fix

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  FOCUSED DEBUG: AV REMOVAL + MALWAREBYTES" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Create debug directory
$debugPath = Join-Path $env:TEMP "NNTool_AVMbam_Debug_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$logFile = Join-Path $debugPath "av_mbam_debug.log"

New-Item -ItemType Directory -Path $debugPath -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $debugPath "Modules") -Force | Out-Null

Start-Transcript -Path $logFile -Force

Write-Host "Debug directory: $debugPath" -ForegroundColor Yellow
Write-Host ""

# Download only the two modules we need
Write-Host "=== DOWNLOADING MODULES ===" -ForegroundColor Cyan

$files = @(
    @{Name = "Remove-Antivirus.ps1"; Path = "Modules/Remove-Antivirus.ps1"},
    @{Name = "Run-Malwarebytes.ps1"; Path = "Modules/Run-Malwarebytes.ps1"}
)

$baseUrl = "https://raw.githubusercontent.com/NerdyNeighbor/nntool/main"

foreach ($file in $files) {
    Write-Host "Downloading $($file.Name)..." -NoNewline
    
    $url = "$baseUrl/$($file.Path)"
    $dest = Join-Path $debugPath $file.Path
    
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("Cache-Control", "no-cache")
        $webClient.DownloadFile($url, $dest)
        
        if (Test-Path $dest) {
            $size = (Get-Item $dest).Length
            Write-Host " OK ($size bytes)" -ForegroundColor Green
            
            # Check if antivirus module excludes Malwarebytes
            if ($file.Name -eq "Remove-Antivirus.ps1") {
                $content = Get-Content $dest -Raw
                if ($content -like "*Malwarebytes*") {
                    Write-Host "  WARNING: Still contains Malwarebytes in removal list!" -ForegroundColor Red
                } else {
                    Write-Host "  GOOD: Malwarebytes excluded from removal" -ForegroundColor Green
                }
            }
        }
    } catch {
        Write-Host " FAILED: $_" -ForegroundColor Red
    }
}

Set-Location $debugPath
Write-Host ""

# Check current Malwarebytes status BEFORE running anything
Write-Host "=== PRE-TEST MALWAREBYTES STATUS ===" -ForegroundColor Cyan

$mbamReg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | 
    Where-Object { $_.DisplayName -like "*Malwarebytes*" }

if ($mbamReg) {
    Write-Host "Registry: $($mbamReg.DisplayName) v$($mbamReg.DisplayVersion)" -ForegroundColor Green
} else {
    Write-Host "Registry: Not found" -ForegroundColor Red
}

$mbamExe = "${env:ProgramFiles}\Malwarebytes\Anti-Malware\mbam.exe"
if (Test-Path $mbamExe) {
    Write-Host "Executable: Found at $mbamExe" -ForegroundColor Green
} else {
    Write-Host "Executable: NOT FOUND at $mbamExe" -ForegroundColor Red
}

$mbamService = Get-Service "MBAMService" -ErrorAction SilentlyContinue
if ($mbamService) {
    Write-Host "Service: MBAMService is $($mbamService.Status)" -ForegroundColor Green
} else {
    Write-Host "Service: MBAMService not found" -ForegroundColor Red
}

Write-Host ""

# Test 1: Antivirus Removal
Write-Host "=== STEP 1: ANTIVIRUS REMOVAL ===" -ForegroundColor Yellow
Write-Host "Expected: Should NOT remove Malwarebytes" -ForegroundColor Gray
Write-Host ""

try {
    $avModule = Join-Path $debugPath "Modules\Remove-Antivirus.ps1"
    & $avModule
    Write-Host ""
    Write-Host "Antivirus removal completed with exit code: $LASTEXITCODE" -ForegroundColor Gray
} catch {
    Write-Host "ERROR in antivirus removal: $_" -ForegroundColor Red
}

Write-Host ""

# Check Malwarebytes status AFTER antivirus removal
Write-Host "=== POST-ANTIVIRUS MALWAREBYTES STATUS ===" -ForegroundColor Cyan

$mbamReg2 = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | 
    Where-Object { $_.DisplayName -like "*Malwarebytes*" }

if ($mbamReg2) {
    Write-Host "Registry: Still present - GOOD!" -ForegroundColor Green
} else {
    Write-Host "Registry: REMOVED - BAD!" -ForegroundColor Red
}

if (Test-Path $mbamExe) {
    Write-Host "Executable: Still present - GOOD!" -ForegroundColor Green
} else {
    Write-Host "Executable: MISSING - BAD!" -ForegroundColor Red
}

$mbamService2 = Get-Service "MBAMService" -ErrorAction SilentlyContinue
if ($mbamService2) {
    Write-Host "Service: $($mbamService2.Status) - Should be Running" -ForegroundColor Green
} else {
    Write-Host "Service: MISSING - BAD!" -ForegroundColor Red
}

Write-Host ""

# Only proceed with Malwarebytes test if it's still available
if ((Test-Path $mbamExe) -and $mbamReg2) {
    # Test 2: Malwarebytes Scan
    Write-Host "=== STEP 2: MALWAREBYTES SCAN ===" -ForegroundColor Yellow
    Write-Host "Expected: Should find executable and launch scan" -ForegroundColor Gray
    Write-Host ""
    
    try {
        $mbamModule = Join-Path $debugPath "Modules\Run-Malwarebytes.ps1"
        & $mbamModule
        Write-Host ""
        Write-Host "Malwarebytes module completed with exit code: $LASTEXITCODE" -ForegroundColor Gray
    } catch {
        Write-Host "ERROR in Malwarebytes module: $_" -ForegroundColor Red
    }
} else {
    Write-Host "=== STEP 2: MALWAREBYTES SCAN ===" -ForegroundColor Yellow
    Write-Host "SKIPPED: Malwarebytes was removed by antivirus module!" -ForegroundColor Red
    Write-Host "This confirms the bug - antivirus removal is still removing Malwarebytes" -ForegroundColor Red
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  DEBUG COMPLETE" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

Stop-Transcript

Write-Host ""
Write-Host "Log saved to: $logFile" -ForegroundColor Green
notepad.exe $logFile

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")